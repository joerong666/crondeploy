#!/bin/env bash

G_METHODS="install|upgrade|status|start|stop|restart"
G_SERVICES="web|webapi|mgr|func_master|func_slave"

usage() {
    echo "Usage: $0 [OPTIONS] "
    echo -e "OPTIONS:"
    echo -e "-m method:\t $G_METHODS"
    echo -e "-s service:\t $G_SERVICES"
    echo -e "-v version:\t which version to install/upgrade"

    exit 1
}
 
while getopts :m:s:v: ac
do
    case $ac in
        m)  method="$OPTARG"
            ;;
        s)  service="$OPTARG"
            ;;
        v)  version="$OPTARG"
            ;;
    esac
done

[ -z "$method" -o -z "$service" ] && usage
[ -z "`echo $method |egrep "$G_METHODS"`" ] && usage
[ -z "`echo $service |egrep "$G_SERVICES"`" ] && usage
[ -z "$version" ] && [ -z "`echo $service |egrep 'func_master|func_slave'`" -a -n "`echo $method |egrep 'install|upgrade'`" ] && usage

urlRoot="http://down0.game.uc.cn/ucgc/fooyun"

[ "$service" = "web" -o "$service" = "webapi" ] && pkgname="fooyun-web-${version}.tar.gz"
[ "$service" = "mgr" ] && pkgname="fooyun-mngrserver-${version}_`uname -m`.tar.gz"
if [ "$service" = "func_master" -o "$service" = "func_slave" ]; then
    [ "`uname -m`" = "i386" ] && pkgname="func_all_in-uc-bin_x32.tar.bz"
    [ "`uname -m`" = "x86_64" ] && pkgname="func_all_in-uc-bin_x64.tar.bz"
fi

installdir="$HOME/local/fooyun/fooyun-$service"
[ "$service" = "webapi" ] && service=web && installdir="$HOME/local/fooyun/api/fooyun-api"

if [ "$method" = "install" -o "$method" = "upgrade" ]; then
    bash <(curl $urlRoot/crondeploy.sh) -m $method -s $service -d $installdir -c -n $pkgname -l "$urlRoot/$pkgname"
else
    bash <(curl $urlRoot/crondeploy.sh) -m $method -s $service -d $installdir
fi
