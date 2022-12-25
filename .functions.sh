#!/bin/bash
docker --help|grep -qi "docker compose"
if [ $? -eq 0 ];then
        function docker-compose(){
           docker compose $@
        }
fi

if [ -f .env ];then
    CURRENT_PROJECT=$(grep "PROJECT" .env|cut -d= -f2)
    CURRENT_PROJECT_FILE=$(grep PROJECT=${CURRENT_PROJECT} envs/*|cut -d: -f1)
else
    echo "No .env file are linked."
    echo "Issue ./link command  to create one."
    exit
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
        args=" -f $(default).yml "
        for SERVICE in $(grep -i "SERVICES" .env|cut -d= -f2|sed 's/"//g')
        do
            if [ -f "services/${SERVICE}.yml" ];then
                args+=" -f services/${SERVICE}.yml "
            fi
        done
        if [[ "${@}" == "ps" ]]; then
            TERM_STDOUT=$(docker-compose -p ${PROJECT} ${args} $@)
            echo -e "$TERM_STDOUT"
            #echo URL
            if [ $DEFAULT ] && [ $DEFAULT = "random" ];then
            echo -e "$TERM_STDOUT"|grep "${PROJECT}-web-1"|sed -r 's/.+0.0.0.0:([[:digit:]]+)->80.+/http:\/\/127.0.0.1:\1/g'

            PORT=$(echo -e "$TERM_STDOUT"|grep "${PROJECT}-web-1"|sed -r 's/.+0.0.0.0:([[:digit:]]+)->80.+/\1/g')

            sed -r 's/APP_URL=.+(random)/$PORT/g' .env
            
            else
                echo $APP_URL
            fi
        else
            docker-compose -p ${PROJECT} ${args} $@
        fi
    else
        echo ".env not found"
    fi
}

