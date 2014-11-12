#!/bin/env bash

###############################################################################################
# Customize url
###############################################################################################
log_url=http://down0.game.uc.cn/ucgc/fooyun/log.sh
cronservice_url=http://down0.game.uc.cn/ucgc/fooyun/cronservice.sh
service_url=http://down0.game.uc.cn/ucgc/fooyun/service.sh
###############################################################################################

G_METHODS="install|upgrade|status|start|stop|restart"
G_SERVICES="web|webapi|mgr|func_master|func_slave"

usage() {
    echo "Usage: $0 [OPTIONS] "
    echo -e "OPTIONS:"
    echo -e "-m method:\t $G_METHODS"
    echo -e "-s service:\t $G_SERVICES"
    echo -e "-d basedir:\t installation home, it is a symbol link"
    echo -e "-l pkgurl:\t\t remote url of package used to install/upgrade, required if '-t' option not provided. eg: \"http://localhost:4218/myapp/mypkg-1.5.3.tar.gz\""
    echo -e "-n pkgname:\t\t remote package name used to install/upgrade, required if '-t' option not provided. eg: \"mypkg-1.5.3.tar.gz\""
    echo -e "-t tarball:\t use local tarball rather than using remote url, should be absolute path. eg: /home/me/pkg/mypkg-1.5.4.tar.gz"
    echo -e "-f :\t\t force to install/upgrade"
    echo -e "-c :\t\t clean downloaded file before/after install/upgrade"

    exit 1
}
 
while getopts :m:s:d:l:n:t:fc ac
do
    case $ac in
        m)  method="$OPTARG"
            ;;
        s)  service="$OPTARG"
            ;;
        d)  basedir="$OPTARG"
            ;;
        l)  pkgurl="$OPTARG"
            ;;
        n)  pkgname="$OPTARG"
            ;;
        t)  tarball="$OPTARG"
            ;;
        f)  force="-f"
            ;;
        c)  clean="-c"
            ;;
    esac
done

[ -z "$method" -o -z "$service" -o -z "$basedir" ] && usage
[ -z "`echo $method |egrep "$G_METHODS"`" ] && usage
[ -z "`echo $service |egrep "$G_SERVICES"`" ] && usage
[ -n "`echo $method |egrep 'install|upgrade'`" ] && [ -z "$tarball" ] && [ -z "$pkgurl" -o -z "$pkgname" ] && usage

#############################################################
PWD=`pwd`
downloaddir=$HOME/.crondeploy
utildir=$downloaddir/cronutil
srcdir=$downloaddir/src

scriptUrls=("$log_url" "$cronservice_url" "$service_url")
for((i=0;i<${#scriptUrls[@]};i++))
do
    curl "${scriptUrls[$i]}" >/dev/null 2>&1
    [ $? -ne 0 ] && utildir="$PWD" && use_local="1" && echo "cannot reach ${scriptUrls[$i]}, use local script instead" && break
done

mkdir -p $utildir $srcdir
[ $? -ne 0 ] && exit 1

EXEC=$utildir/cronservice.sh
cd $utildir

if [ -z "$use_local" ]; then
    tf=log.sh && echo "download $tf to $srcdir if need" &&           [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $log_url
    tf=cronservice.sh && echo "download $tf to $srcdir if need" &&   [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $cronservice_url
    tf=service.sh && echo "download $tf to $srcdir if need" &&       [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $service_url
fi

chmod +x *

cd $srcdir

if [ ! -z "$tarball" ]; then
    $EXEC -m $method -s $service -d $basedir -t $tarball $force $clean
else
    tf="$pkgname" && echo "download $tf to $srcdir if need" && [ ! -z "`echo $method |egrep 'install|upgrade'`" ] && \
    if [ ! -e $tf -o ! -z "$clean" ]; then
        wget -O $tf "$pkgurl"
        [ $? -ne 0 ] && echo "download from $pkgurl failed" && exit 1
    fi

    $EXEC -m $method -s $service -d $basedir -t $srcdir/$tf $force $clean
    [ ! -z "$clean" ] && echo "clean $srcdir/$tf" && rm $tf
fi
