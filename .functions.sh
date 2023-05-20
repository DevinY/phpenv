#!/bin/bash
docker --help|grep -qi "docker compose"
if [ $? -eq 0 ];then
        function docker-compose(){
           docker compose $@
        }
fi

if [ -f .env ];then
    CURRENT_PROJECT=$(grep "PROJECT" .env|cut -d= -f2)
    CURRENT_PROJECT_FILE="envs/$(ls -l .env|cut -d/ -f2)"
else
    echo "No .env file are linked."
    echo "Issue ./link command  to create one."
    exit
fi

function get_project(){
    PROJECT=$(grep -Ei "^PROJECT=" .env|cut -d= -f2)
    if [ -z $PROJECT ];then
        echo "PROJECT variable not found in env file"
        exit 1
    fi
    echo $PROJECT
}

function get_args(){
        args=" -f $(default_yml_file).yml "
        #add additional yml files
        for SERVICE in $(grep -Ei "^SERVICES" .env|cut -d= -f2|sed 's/"//g')
        do
            if [ -f "services/${SERVICE}.yml" ];then
                args+=" -f services/${SERVICE}.yml "
            fi
        done
        echo $args
}

function get_workspace(){
    WORKSPACE=$(grep -Ei "^WORKSPACE" .env|cut -d= -f2)
    if [ -z $WORKSPACE ];then
        WORKSPACE="php"
    fi
    echo $WORKSPACE
}

function default_yml_file(){
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
    args=" -f $(default_yml_file).yml "
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
    args=" -f $(default_yml_file).yml "
    for SERVICE in $(grep -Ei "^SERVICES" .env|cut -d= -f2|sed 's/"//g')
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    docker-compose -p ${PROJECT} ${args} down --remove-orphans
}

function exec_bash {
    args=" -f $(default_yml_file).yml "
    for SERVICE in $(grep -Ei "^SERVICES" .env|cut -d= -f2|sed 's/"//g')
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    echo "Entering the \"$(grep -E 'PROJECT=.+$' .env|cut -d= -f2)\" project in the $1 container."
    if [[ $1 = 'php' ]];then
        docker-compose  -p ${PROJECT} ${args}\
        exec -w /var/www/html/$2 \
        -u dlaravel \
        $1 bash
    else
        docker-compose  -p ${PROJECT} ${args} exec $1  bash
    fi
    exit
}

function console() {
    if [ -f .env ];then
        source .env
        touch authorized_keys
        PROJECT=$(get_project)
        args=$(get_args)
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

