#!/bin/bash

function exec_bash {
    echo "The \"$(grep -E 'PROJECT=.+$' .env|cut -d= -f2)\" project of the php container."
    docker-compose  -p ${PROJECT} \
        exec -w /var/www/html/$2 \
        -u dlaravel \
        $1  bash
    exit
}

function console() {
    if [ -f .env ];then
        source .env
        touch authorized_keys
        PROJECT=$(grep 'PROJECT' .env|cut -d= -f2)
        echo ${APP_URL}
        args=" -f docker-compose.yml "
        for SERVICE in $(grep -i "SERVICES" .env|cut -d= -f2|sed 's/"//g')
        do
            if [ -f "services/${SERVICE}.yml" ];then
                args+=" -f services/${SERVICE}.yml "
            fi
        done
        docker-compose -p ${PROJECT} ${args} $@
    else
        echo ".env not found"
    fi
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

#檢測是否為.env名稱，如果是就進入
if [ "$1" ];then
    MATCH=$(ls envs/$1* 2>/dev/null|wc -l)
    if [ ${MATCH} -eq 1 ];then
        ls envs/$1* >/dev/null
        if [ $? -eq 0 ];then
            ENVFILE=$(ls envs/$1*)
            #重新連結並進入容器
            ln -sf ${ENVFILE} .env
            grep "PROJECT" .env
            shift 1
            console exec php bash
        fi
        exit
    fi
fi
