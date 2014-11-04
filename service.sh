#####################################################################
# service functions, loaded by cronservice.sh args: method, basedir
#####################################################################
update_conf() {
    local oldcnf="$1"
    local newcnf="$2"
    local grepkey="$3"

    log_debug "update $oldcnf to $newcnf via grep expression: '$grepkey'"
    local keycnt=`fgrep -n "$grepkey" $oldcnf  |fgrep -v '#' |grep -v '\--' |wc -l`
    [ "$keycnt" != "1" ] && log_err "amount[$keycnt] of '$grepkey' in $newcnf is not 1" && return 1

    local keycnt=`fgrep -n "$grepkey" $newcnf  |fgrep -v '#' |grep -v '\--' |wc -l`
    [ "$keycnt" != "1" ] && log_err "amount[$keycnt] of '$grepkey' in $newcnf is not 1" && return 1

    local content=`fgrep "$grepkey" $oldcnf  |fgrep -v '#' |grep -v '\--'`
    local line=`fgrep -n "$grepkey" $newcnf  |fgrep -v '#' |grep -v '\--' |awk -F: '{print $1}'`

    log_debug "update $newcnf:$line with '$content'"
    sed -i "${line}d" $newcnf && sed -i "$line i$content" $newcnf
    [ $? -ne 0 ] && log_err "update $newcnf failed" && return 1

    return 0
}

op_web() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local f=${FUNCNAME[0]}
    local service=${f#*_}
    local method="$1"
    local basedir="$2"
    local real_basedir=`readlink -e $basedir`

    case "$method" in
        "install") 
            return 0
            ;;
        "upgrade") 
            local newdir=$3

            local cnf="conf/application.conf"
            local items=("http.port" "db.url" "db.user" "db.pass" "process.name")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done

            return 0
            ;;
        "status") 
            log_debug "check process exist"
            pid=`ps x |egrep "$real_basedir\b" |fgrep 'play' |fgrep 'java' |fgrep -v 'grep' |awk '{print $1}'`
            if [ -n "$pid" ]; then
                log_prompt "process[$pid] exist, write pid to $real_basedir/server.pid" && echo $pid >$real_basedir/server.pid && return 1
            else
                log_prompt "process not exist, remove server.pid if exist" && rm -f $real_basedir/server.pid
                return 0
            fi
            ;;
        "start") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 0 ] && log_warn "process exist, add to crontab if need" && add_to_crontab $service $basedir && return 0

            cd $basedir && log_debug "process not exist, start it and then add it to crontab" && play start && add_to_crontab $service $basedir
            return $?
            ;;
        "stop") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 1 ] && log_warn "process not exist, evict it from crontab if need" && evict_from_crontab $service $basedir && return 0

            cd $basedir && log_debug "process exist, evict it from crontab and then stop it" && evict_from_crontab $service $basedir && play stop
            local ret=$?
            [ $ret -eq 0 ] && ps x |fgrep "$real_basedir" |fgrep -v 'fgrep' |awk '{print $1}' |xargs kill -9 >/dev/null 2>&1
            return $ret
            ;;
        "restart") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 1 ] && log_err "process not exist, cannot restart" && return 1

            cd $basedir && log_debug "process exist, going to restart it" && play restart
            return $?
            ;;
    esac
}

op_mgr() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local f=${FUNCNAME[0]}
    local service=${f#*_}
    local method="$1"
    local basedir="$2"
    local real_basedir=`readlink -e $basedir`

    case "$method" in
        "install") 
            return 0
            ;;
        "upgrade") 
            local newdir=$3

            local cnf="bin/fooyun_mngr.ini"
            local items=("listen")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done

            local cnf="script/foo_conf.lua"
            local items=("host")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done

            local cnf="script/mngr/mngr_config.lua"
            local items=("mngr_server_ip" "mngr_server_port")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done

            return 0
            ;;
        "status") 
            log_debug "check whether process exist, via grep expression: $real_basedir/bin/uchas"
            proc="`ps x |fgrep "$basedir/bin/uchas" |fgrep -v "$G_CMD_NAME" |fgrep -v 'fgrep'`"

            [ -z "$proc" ] && log_prompt "process not exist" && return 0 
            log_prompt "process[$proc] exist" && return 1
            ;;
        "start") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 0 ] && log_warn "process exist, add to crontab if need" && add_to_crontab $service $basedir && return 0

            cd $basedir/bin && log_debug "process not exist, start it and then add it to crontab" && \
            $basedir/bin/uchas -f fooyun_mngr.ini -d && add_to_crontab $service $basedir
            return $?
            ;;
        "stop") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 1 ] && log_warn "process not exist, evict it from crontab if need" && evict_from_crontab $service $basedir && return 0

            log_debug "process exist, evict it from crontab and then stop it" && evict_from_crontab $service $basedir && \
            ps x |fgrep "$basedir/bin/uchas"|fgrep -v 'fgrep' |awk '{print $1}' |xargs kill -9
            ;;
        "restart") 
            ${FUNCNAME[0]} status $basedir
            [ $? -ne 1 ] && log_err "process not exist, cannot restart" && return 1

            cd $basedir/bin && log_debug "process exist, going to restart it" \
            && ps x |fgrep "$basedir/bin/uchas"|fgrep -v 'fgrep' |awk '{print $1}' |xargs kill -9 \
            && $basedir/bin/uchas -f fooyun_mngr.ini -d
            return $?
            ;;
    esac
}

op_func() {
    log_debug "${FUNCNAME[0]}($#): $*"

    local f=${FUNCNAME[1]}
    local service=${f#*_}
    local method="$1"
    local basedir="$2"

    case "$method" in
        "install") 
            return 0
            ;;
        "upgrade") 
            local newdir=$3

            local cnf="etc/certmaster/certmaster.conf"
            local items=("listen_port")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done
            
            local cnf="etc/certmaster/minion.conf"
            local items=("certmaster " "certmaster_port")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done
            
            local cnf="etc/func/overlord.conf"
            local items=("listen_port")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done

            local cnf="etc/func/minion.conf"
            local items=("listen_port" "minion_name")
            for((i=0;i<${#items[@]};i++))
            do
                update_conf $basedir/$cnf $newdir/$cnf "${items[$i]}"
                [ $? -ne 0 ] && return 1
            done
            
            return 0
            ;;
        "status") 
            local func_role="$3"
            log_debug "check whether process exist, via grep expression: $basedir/bin/python $func_role"
            proc="`ps x |fgrep "$basedir/bin/python $func_role" |fgrep -v "$G_CMD_NAME" |fgrep -v 'fgrep'`"
            
            [ -z "$proc" ] && log_prompt "process not exist" && return 0 
            log_prompt "process[$proc] exist" && return 1
            ;;
        "start") 
            local func_role="$3"
            ${FUNCNAME[0]} status $basedir $func_role
            [ $? -ne 0 ] && log_warn "process exist, add to crontab if need" && add_to_crontab $service $basedir && return 0

            cd $basedir/bin && log_debug "process not exist, start it and then add it to crontab" && \
            $basedir/bin/python $func_role --daemon && add_to_crontab $service $basedir
            return $?
            ;;
        "stop") 
            local func_role="$3"
            ${FUNCNAME[0]} status $basedir $func_role
            [ $? -ne 1 ] && log_warn "process not exist, evict it from crontab if need" && evict_from_crontab $service $basedir && return 0

            log_debug "process exist, evict it from crontab and then stop it" && evict_from_crontab $service $basedir && \
            ps x |fgrep "$basedir/bin/python $func_role"|fgrep -v 'fgrep' |awk '{print $1}' |xargs kill -9
            ;;
        "restart") 
            local func_role="$3"
            ${FUNCNAME[0]} status $basedir $func_role
            [ $? -ne 1 ] && log_err "process not exist, cannot restart" && return 1

            cd $basedir/bin && log_debug "process exist, going to restart it" && \
            ps x|grep "$basedir/bin/python $func_role" |grep -v 'grep' |awk '{print $1}' |xargs kill -9 && \
            $basedir/bin/python $func_role --daemon
            ;;
    esac
}

op_func_master() {
    log_debug "${FUNCNAME[0]}($#): $*"

    op_func "$@" certmaster
    return $?
}

op_func_slave() {
    log_debug "${FUNCNAME[0]}($#): $*"

    op_func "$@" funcd
    return $?
}

###########################################
# simple scripts
###########################################
G_SERVICES="web|mgr|func_master|func_slave"

