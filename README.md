crondeploy
==========

auto deploy your program and attach it to cronjob

usage
==========
Usage: /home/joerong/work/fooyun/fooyun/source/dev/script/deploy/my_deploy.sh [OPTIONS] <br/>
OPTIONS: <br/>
-m method:       install|upgrade|status|start|stop|restart <br/>
-s service:      web|mgr|func_master|func_slave <br/>
-d basedir:      installation home, it is a symbol link <br/>
-t tarball:      use local tarball rather than using remote one, should absolute path <br/>
-p platform:     32|64 <br/>
-f :             force to install/upgrade <br/>
-c :             clean downloaded file before/after install/upgrade <br/>

install
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m install -s web -d ~/tmp/fooyun/fooyun-web -c

upgrade
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m upgrade -s web -d ~/tmp/fooyun/fooyun-web -c

start
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m start -s web -d ~/tmp/fooyun/fooyun-web

stop
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m stop -s web -d ~/tmp/fooyun/fooyun-web

restart
==========
bash <(curl https://github.com/joerong666/crondeploy/blob/master/my_deploy.sh) -m restart -s web -d ~/tmp/fooyun/fooyun-web
