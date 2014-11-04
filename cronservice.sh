#!/bin/env bash

#######################################
# common functions
#######################################
install() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local service=$1
    local basedir="$2"
    local tarball=$3
    local force=$4

    local basedir_sym=`basename $basedir`
    local parentdir=`dirname $basedir`

    local tarball_dir=`dirname $tarball`
    local tarball_basename=`basename $tarball`
    local tarball_file=${tarball_basename%.tar.*}

    [ ! -e $tarball -o ! -f $tarball ] && log_err "$tarball not exist or not a tarball file" && return 1
    if [ $force -eq 0 ]; then
        [ -e $basedir ] && log_err "$basedir exist" && return 1
        [ -e $parentdir/$tarball_file ] && log_err "$parentdir/$tarball_file exist" && return 1
    fi

    log_debug "counting root dirs of tarball"
    local dircnt=`tar tf $tarball |sed 's#\./##' |awk -F/ '{print $1}' |uniq |wc -l`

    mkdir -p $parentdir && cd $parentdir
    [ $? -ne 0 ] && log_err "mkdir -p $parentdir && cd $parentdir" && return 1

    if [ $dircnt -eq 1 ]; then
        log_debug "tarball has only one root dir, extract simply"
        tar xf $tarball
        [ $? -ne 0 ] && log_err "tar xf $tarball" && return 1
    else
        log_debug "tarball has multi root dirs, extract to $tarball_file"
        mkdir -p $tarball_file && tar xf $tarball -C $tarball_file
        [ $? -ne 0 ] && log_err "mkdir $tarball_file && tar xf $tarball -C $tarball_file" && return 1
    fi

    log_debug "call ${service}'s ${FUNCNAME[0]} method"
    op_${service} ${FUNCNAME[0]} $basedir
    [ $? -ne 0 ] && log_err "${FUNCNAME[0]} $service failed" && return 1

    log_debug "create symbol link $basedir_sym -> $tarball_file"
    ln -snf $tarball_file $basedir_sym
    [ ! -L $basedir_sym ] && log_err "$basedir_sym should be a symbol link" && return 1

    log_prompt "$tarball has installed to $basedir"
    return 0
}

upgrade() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local service=$1
    local basedir="$2"
    local tarball=$3
    local force=$4
    local clean=$5

    local basedir_sym=`basename $basedir`
    local parentdir=`dirname $basedir`

    local tarball_dir=`dirname $tarball`
    local tarball_basename=`basename $tarball`
    local tarball_file=${tarball_basename%.tar.*}

    [ ! -e $tarball -o ! -f $tarball ] && log_err "$tarball not exist nor a tarball file" && return 1
    if [ $force -eq 0 ]; then
        [ ! -e $basedir -o ! -L $basedir ] && log_err "$basedir not exist nor a symbol link" && return 1
        [ -e $parentdir/$tarball_file ] && log_err "dir $parentdir/$tarball_file exist, cannot upgrade to the same version" && return 1
    fi

    log_debug "counting root dirs of tarball"
    local dircnt=`tar tf $tarball |sed 's#\./##' |awk -F/ '{print $1}'|uniq -d |wc -l`

    mkdir -p $parentdir && cd $parentdir
    [ $? -ne 0 ] && log_err "mkdir -p $parentdir && cd $parentdir" && return 1

    if [ $dircnt -eq 1 ]; then
        log_debug "tarball has only one root dir, extract simply"
        tar xf $tarball
        [ $? -ne 0 ] && log_err "tar xf $tarball" && return 1
    else
        log_debug "tarball has multi root dirs, extract to $tarball_file"
        mkdir -p $tarball_file && tar xf $tarball -C $tarball_file
        [ $? -ne 0 ] && log_err "mkdir $tarball_file && tar xf $tarball -C $tarball_file" && return 1
    fi

    if [ -e $basedir ]; then
        log_debug "call ${service}'s ${FUNCNAME[0]} method"
        op_${service} ${FUNCNAME[0]} $basedir $tarball_file
        [ $? -ne 0 ] && log_err "${FUNCNAME[0]} $service failed" && return 1
    fi

    [ ! -e $basedir -a $force -ne 0 ] && ln -snf $tarball_file $basedir_sym
    local old_version=`readlink -e $basedir`

    log_debug "stop process base on old dir"
    op_${service} stop $basedir
    [ $? -ne 0 ] && log_err "${FUNCNAME[0]} $service failed" && return 1

    cd $parentdir && log_debug "create symbol link $basedir_sym -> $tarball_file"
    ln -snf $tarball_file $basedir_sym
    [ ! -L $basedir_sym ] && log_err "$basedir_sym should be a symbol link" && return 1

    log_debug "start process base on new dir"
    op_${service} start $basedir
    [ $? -ne 0 ] && log_err "${FUNCNAME[0]} $service failed" && return 1

    local new_version=`readlink -e $basedir`
    [ $clean -eq 1 -a -n "$old_version" -a -n "$new_version" -a "$old_version" != "$new_version" ] && \
    log_debug "clean old version files $old_version" && rm -rf $old_version

    log_prompt "$service has upgraded from $old_version to $new_version"
    return 0
}

add_to_crontab() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local service=$1
    local basedir=$2

    log_debug "check crontab via: crontab -l |grep -v \"^#\" |fgrep \"$G_CMD_NAME -m start -s $service -d $basedir\""
    local res=`crontab -l |grep -v "^#" |fgrep "$G_CMD_NAME -m start -s $service -d $basedir"`
    if [ -z "$res" ]; then
        log_debug "cronjob regarding to $service not exist, going to add it"

        local tmpdir=$basedir/.${service}_tmp
        mkdir -p $tmpdir
        [ $? -ne 0 ] && log_err "create $tmpdir failed" && return 1

        local tmpcron=$tmpdir/.cron
        crontab -l > $tmpcron 2> /dev/null
        local job_cmd="* * * * *  $G_CMD_PATH -m start -s $service -d $basedir > $basedir/${service}_cron.log 2>&1"
        echo "$job_cmd" >> $tmpcron

        log_debug "add cronjob: $job_cmd"
        crontab $tmpcron
        if [ $? -eq 0 ]; then
            log_info "job added, check your crontab via 'crontab -l'"
        else
            log_err "'crontab $crontab' failure, please check the file"
            return 1
        fi
    else
        log_warn "cronjob regarding to $service exist"
    fi
}

evict_from_crontab() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local service=$1
    local basedir=$2

    log_debug "check crontab via: crontab -l |fgrep -n "$G_CMD_PATH -m start -s $service -d $basedir" |grep -v "^#" |awk -F: '{print $1}'"
    local res=`crontab -l |fgrep -n "$G_CMD_PATH -m start -s $service -d $basedir" |grep -v "^#" |awk -F: '{print $1}'`
    if [ ! -z "$res" ]; then
        log_debug "cronjob regarding to $service exist, going to evict it"

        local tmpdir=$basedir/.${service}_tmp
        mkdir -p $tmpdir
        [ $? -ne 0 ] && log_err "create $tmpdir failed" && return 1

        local tmpcron=$tmpdir/.cron
        crontab -l > $tmpcron 2> /dev/null
        job_cmd=`sed -n "${res}p" $tmpcron`
        sed -i "${res}d" "$tmpcron"
        log_debug "evict cronjob: $job_cmd"
        crontab "$tmpcron"
        if [ $? -eq 0 ]; then
            log_info "job evicted, check your crontab via 'crontab -l'"
        else
            log_err "'crontab $tmpcron' failure, please check the file"
            return 1
        fi
    else
        log_warn "cronjob regarding to $service not exist"
    fi
}

#################################################
# main
#################################################
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo -e "OPTIONS:"
    echo -e "-m method:\t $G_METHODS"
    echo -e "-s service:\t $G_SERVICES"
    echo -e "-d basedir:\t installation home, it is a symbol link"
    echo -e "-t tarball:\t use this tarball to install/upgrade"
    echo -e "-f :\t\t force to install/upgrade"
    echo -e "-c :\t\t clean old version files after upgrade"

    exit 1
}
    
main() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local method=""
    local service=""
    local basedir=""
    local tarball=""
    local force=0
    local clean=0

    while getopts :m:s:d:t:fc ac
    do
        case $ac in
            m)  method="$OPTARG"
                ;;
            s)  service="$OPTARG"
                ;;
            d)  basedir="$OPTARG"
                ;;
            t)  tarball="$OPTARG"
                ;;
            f)  force=1
                ;;
            c)  clean=1
                ;;
        esac
    done
    
    [ -z "$method" -o -z "$service" -o -z "$basedir" ] && usage
    [ -z "`echo $method |egrep "$G_METHODS"`" ] && usage
    [ -z "`echo $service |egrep "$G_SERVICES"`" ] && usage
    [ ! -z "`echo $method |egrep "install|upgrade"`" -a -z "$tarball" ] && log_err "-t required by install or upgrade" && usage

    log_prompt "---------- going to $method $service ---------------"
    if [ "$method" = "install" ]; then
        $method ${service} $basedir $tarball $force
    elif [ "$method" = "upgrade" ]; then
        $method ${service} $basedir $tarball $force $clean
    else
        op_${service} $method $basedir
    fi
    
    local ecode=$?
    if [ $ecode -eq 0 -o $method = "status" ]; then
        log_prompt "$method $service success"
    else
        log_err "$method $service failed"
    fi
    
    log_prompt "----------- $method $service finished ---------------"

    return $ecode
}

#################################################
# simple scripts
#################################################
CURRENT_PWD=`pwd`
cd `dirname $0`
G_PWD=`pwd`
G_CMD_NAME=`basename $0`
G_CMD_PATH=$G_PWD/$G_CMD_NAME
G_METHODS="install|upgrade|status|start|stop|restart"

source ~/.bash_profile
source ~/.bashrc

#global variable G_SERVICES is defined in service.sh
source log.sh
source service.sh

cd $CURRENT_PWD
    
main "$@"
