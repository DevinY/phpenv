#!/bin/bash
docker --help|grep -qi "docker compose"
if [ $? -eq 0 ];then
        function docker-compose(){
           docker compose $@
        }
fi

function default(){
    DEFAULT=$(grep -Ei "^DEFAULT" .env|cut -d= -f2)
    if [ -z $DEFAULT ];then
        DEFAULT="docker-compose"
    fi
    echo $DEFAULT
}

function start {
    mkdir -p etc/cache
    touch authorized_keys
    echo ${APP_URL}
    PROJECT=$1
    args=" -f $(default).yml "
    for SERVICE in $(grep -Ei "^SERVICES" .env|cut -d= -f2|sed 's/"//g')
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    docker-compose -p ${PROJECT} ${args} up -d
}

function stop {
    touch authorized_keys
    echo ${APP_URL}
    PROJECT=$1
    args=" -f $(default).yml "
    for SERVICE in $(grep -Ei "^SERVICES" .env|cut -d= -f2|sed 's/"//g')
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    docker-compose -p ${PROJECT} ${args} down --remove-orphans
}
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
        args=" -f $(default).yml "
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

