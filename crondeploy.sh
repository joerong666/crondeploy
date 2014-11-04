#!/bin/env bash

VERSION="1.5.3"
webtarball=fooyun-web-1.5.3.tar.gz
mgrtarball_32=fooyun-mngrserver-1.5.2_i386.tar.gz
mgrtarball_64=fooyun-mngrserver-1.5.2_x86_64.tar.gz
functarball_32=func_all_in-uc-bin_x32.tar.bz
functarball_64=func_all_in-uc-bin_x64.tar.bz

weburl="http://doc.ucweb.local/download/attachments/34179839/fooyun-web-1.5.3.tar.gz?version=2&modificationDate=1414129665000&api=v2"
mgrurl_32="http://doc.ucweb.local/download/attachments/33462233/fooyun-mngrserver-1.5.2_i386.tar.gz?version=1&modificationDate=1413863546000&api=v2"
mgrurl_64="http://doc.ucweb.local/download/attachments/33462233/fooyun-mngrserver-1.5.2_x86_64.tar.gz?version=1&modificationDate=1413863559000&api=v2"
funcurl_32="http://soft.ucweb.local/platform/share/func_all_in-uc-bin_x32.tar.bz"
funcurl_64="http://soft.ucweb.local/platform/share/func_all_in-uc-bin_x64.tar.bz"

log_url=http://doc.ucweb.local/download/attachments/32771694/log.sh?api=v2
cronservice_url=http://doc.ucweb.local/download/attachments/32771694/cronservice.sh?api=v2
service_url=http://doc.ucweb.local/download/attachments/32771694/service.sh?api=v2

#################################################################################
G_METHODS="install|upgrade|status|start|stop|restart"
G_SERVICES="web|mgr|func_master|func_slave"

usage() {
    echo "Usage: $0 [OPTIONS] "
    echo -e "OPTIONS:"
    echo -e "-m method:\t $G_METHODS"
    echo -e "-s service:\t $G_SERVICES"
    echo -e "-d basedir:\t installation home, it is a symbol link"
    echo -e "-t tarball:\t use local tarball rather than using remote one, should absolute path"
    echo -e "-p platform:\t 32|64"
    echo -e "-f :\t\t force to install/upgrade"
    echo -e "-c :\t\t clean downloaded file before/after install/upgrade"

    exit 1
}
 
while getopts :m:s:d:t:p:fc ac
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
        p)  pf="$OPTARG"
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

#############################################################
downloaddir=$HOME/local/crondeploy
utildir=$downloaddir/cronutil
srcdir=$downloaddir/src
EXEC=$utildir/cronservice.sh

mkdir -p $utildir $srcdir
[ $? -ne 0 ] && exit 1

cd $utildir
tf=log.sh && echo "download $tf to $srcdir if need" &&           [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $log_url
tf=cronservice.sh && echo "download $tf to $srcdir if need" &&   [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $cronservice_url
tf=service.sh && echo "download $tf to $srcdir if need" &&       [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf $service_url
chmod +x *

cd $srcdir

sv=$service
tp="_32"
[ -n "`echo $sv |egrep 'func_master|func_slave'`" ] && sv="func"
[ "$pf" != "32" ] && tp="_64"
[ "$service" = "web" ] && tp=""

if [ ! -z "$tarball" ]; then
    $EXEC -m $method -s $service -d $basedir -t $tarball $force $clean
else
    tft="\$${sv}tarball${tp}"
    tfu="\$${sv}url${tp}"
    tf=`eval "echo $tft"` && echo "download $tf to $srcdir if need" && [ ! -z "`echo $method |egrep 'install|upgrade'`" ] && \
    [ ! -e $tf -o ! -z "$clean" ] && wget -O $tf `eval "echo $tfu"`

    $EXEC -m $method -s $service -d $basedir -t $srcdir/$tf $force $clean
    [ $? -eq 0 -a ! -z "$clean" ] && echo "clean $srcdir/$tf" && rm $tf
fi
