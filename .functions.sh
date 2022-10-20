#!/bin/bash

function exec_bash {
    echo "The \"$(grep -E 'PROJECT=.+$' .env|cut -d= -f2)\" project of the php container."
    docker-compose  -p ${PROJECT} \
        exec -w /var/www/html/$2 \
        -u dlaravel \
        $1  bash
    exit
}

if [[ "$1" = 'info' && "$2" = 'all' ]];then
    . ./all
    exit
fi

if [[ "$1" = 'info' && "$2" = 'ports' ]];then
    ./ports
    exit
fi

if [[ "$1" = 'all' ]];then
    . ./all
    exit
fi

if [ "$1" = 'info' ];then
    . ./info
    exit
fi

if [ "$1" = 'stop' ];then
    shift 1
    . ./stop $2
    exit
fi

if [ "$1" = 'start' ];then
    shift 1
    . ./start
    exit
fi

if [ "$1" = 'link' ];then
    shift 1
    . ./link
    exit
fi
#reload nginx
if [ "$1" = 'reload' ];then
    . ./reload
    exit
fi

#執行容器內的命令
if [ "$1" = 'artisan' ];then
    docker-compose -p ${PROJECT} exec php php $@
    exit 0
fi

#Default Workspace
if [ "$1" = '' ];then
    exec_bash php
fi

#進入ssh容器
if [ "$1" = 'ssh' ];then
    exec_bash $1
fi

#進入Drive容器
if [ "$1" = 'drive' ];then
    exec_bash $1 public
fi
