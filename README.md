crondeploy
==========

auto deploy your program and attach it to cronjob

usage
==========
Usage: /home/joerong/work/fooyun/fooyun/source/dev/script/deploy/my_deploy.sh [OPTIONS] <br/>
OPTIONS: <br/>
-m method:       install|upgrade|status|start|stop|restart <br/>
-s service:      web|webapi|mgr|func_master|func_slave <br/>
-v version:      which version to install/upgrade

install
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m install -s web -v 1.5.3

upgrade
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m upgrade -s web -v 1.5.3

start
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m start -s web

stop
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m stop -s web

restart
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m restart -s web
