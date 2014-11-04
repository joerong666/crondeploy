#!/bin/env bash

VERSION="1.5.3"
webtarball=fooyun-web-1.5.3.tar.gz
webapitarball=fooyun-web-1.5.3.tar.gz
mgrtarball_32=fooyun-mngrserver-1.5.2_i386.tar.gz
mgrtarball_64=fooyun-mngrserver-1.5.2_x86_64.tar.gz
functarball_32=func_all_in-uc-bin_x32.tar.bz
functarball_64=func_all_in-uc-bin_x64.tar.bz

weburl="http://doc.ucweb.local/download/attachments/34179839/fooyun-web-1.5.3.tar.gz?version=2&modificationDate=1414129665000&api=v2"
webapiurl="http://doc.ucweb.local/download/attachments/34179839/fooyun-web-1.5.3.tar.gz?version=2&modificationDate=1414129665000&api=v2"
mgrurl_32="http://doc.ucweb.local/download/attachments/33462233/fooyun-mngrserver-1.5.2_i386.tar.gz?version=1&modificationDate=1413863546000&api=v2"
mgrurl_64="http://doc.ucweb.local/download/attachments/33462233/fooyun-mngrserver-1.5.2_x86_64.tar.gz?version=1&modificationDate=1413863559000&api=v2"
funcurl_32="http://soft.ucweb.local/platform/share/func_all_in-uc-bin_x32.tar.bz"
funcurl_64="http://soft.ucweb.local/platform/share/func_all_in-uc-bin_x64.tar.bz"

log_url=http://doc.ucweb.local/download/attachments/32771694/log.sh?api=v2
cronservice_url=http://doc.ucweb.local/download/attachments/32771694/cronservice.sh?api=v2
service_url=http://doc.ucweb.local/download/attachments/32771694/service.sh?api=v2
crondeploy_url=http://doc.ucweb.local/download/attachments/32771694/crondeploy.sh?api=v2

CURPWD=`pwd`
dpf=.crondeploy.sh && echo "download $dpf" && wget -O $dpf $crondeploy_url && source $dpf
cd $CURPWD && echo "clean $dpf" && rm $dpf
