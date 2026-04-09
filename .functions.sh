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

function services_list_from_env(){
        grep -Ei "^[[:space:]]*SERVICES=" .env 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/"//g'
}

function get_args(){
        args=" -f $(default_yml_file).yml "
        #add additional yml files
        for SERVICE in $(services_list_from_env)
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

# Sync php-fpm pool user/group in etc/php-fpm.d/www.conf with USER_ID/GROUP_ID from .env before build.
function sync_php_fpm_www_conf_from_env() {
    local www_conf="${PHPENV:-.}/etc/php-fpm.d/www.conf"
    if [ ! -f "$www_conf" ]; then
        return 0
    fi
    local uid gid
    uid=$(grep -E '^USER_ID=' .env 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r"'"'"'')
    gid=$(grep -E '^GROUP_ID=' .env 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r"'"'"'')
    if [ -z "$uid" ]; then
        uid=1000
    fi
    if [ -z "$gid" ]; then
        gid=1000
    fi
    local cur_user cur_group
    cur_user=$(awk '/^user[ \t]*=/ && $0 !~ /^[ \t]*;/ { gsub(/^[ \t]*user[ \t]*=[ \t]*/, ""); gsub(/[ \t]+$/, ""); print; exit }' "$www_conf")
    cur_group=$(awk '/^group[ \t]*=/ && $0 !~ /^[ \t]*;/ { gsub(/^[ \t]*group[ \t]*=[ \t]*/, ""); gsub(/[ \t]+$/, ""); print; exit }' "$www_conf")
    if [ "$cur_user" = "$uid" ] && [ "$cur_group" = "$gid" ]; then
        return 0
    fi
    echo "php-fpm www.conf: user/group ${cur_user:-?}/${cur_group:-?} -> ${uid}/${gid} (from .env USER_ID/GROUP_ID)"
    local tmp
    tmp=$(mktemp) || return 1
    sed -E -e "s/^user[[:space:]]*=.*/user = ${uid}/" -e "s/^group[[:space:]]*=.*/group = ${gid}/" "$www_conf" > "$tmp" && mv "$tmp" "$www_conf"
}

# Read or rotate Redis requirepass in services/redis.yml (default password -> random hex via openssl).
function print_or_rotate_redis_yml_secret() {
    local redis_yml="${PHPENV:-.}/services/redis.yml"
    local default='You_Should_Change_This_Password'
    if [ ! -f "$redis_yml" ]; then
        echo "services/redis.yml not found." >&2
        return 1
    fi
    local line current
    line=$(grep -E 'redis-server.*--requirepass' "$redis_yml" | grep -Ev '^[[:space:]]*#' | head -1)
    if [ -z "$line" ]; then
        echo "No redis-server --requirepass line found in services/redis.yml" >&2
        return 1
    fi
    current=$(printf '%s\n' "$line" | sed -E 's/.*--requirepass[[:space:]]+//;s/[[:space:]]+$//')
    if [ -z "$current" ]; then
        echo "Could not parse Redis password from services/redis.yml" >&2
        return 1
    fi
    if [ "$current" = "$default" ]; then
        local new_secret tmp
        new_secret=$(openssl rand -hex 32)
        tmp=$(mktemp) || return 1
        sed "s|${default}|${new_secret}|g" "$redis_yml" > "$tmp" && mv "$tmp" "$redis_yml"
        printf '%s\n' "$new_secret"
    else
        printf '%s\n' "$current"
    fi
}

function start {
    mkdir -p etc/cache
    touch authorized_keys
    echo ${APP_URL}
    PROJECT=$1
    args=" -f $(default_yml_file).yml "
    for SERVICE in $(services_list_from_env)
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    docker-compose -p ${PROJECT} ${args} up -d --remove-orphans
}

function stop {
    touch authorized_keys
    echo ${APP_URL}
    PROJECT=$1
    args=" -f $(default_yml_file).yml "
    for SERVICE in $(services_list_from_env)
    do
        if [ -f "services/${SERVICE}.yml" ];then
            args+=" -f services/${SERVICE}.yml "
        fi
    done
    docker-compose -p ${PROJECT} ${args} down --remove-orphans
}

function exec_bash {
    #SHELL=sh
    args=" -f $(default_yml_file).yml "
    for SERVICE in $(services_list_from_env)
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
        $1 ${SHELL}
        if [ $? -eq 1 ];then
            echo "docker run --rm -v $(readlink -f ${FOLDER}/):/var/www/html -ti $(grep -E 'PROJECT=.+$' .env|cut -d= -f2)_$1 ${SHELL}"
            docker run --rm -v $(readlink -f ${FOLDER}/):/var/www/html -ti $(grep -E 'PROJECT=.+$' .env|cut -d= -f2)_$1 ${SHELL}
        fi
    else
        docker-compose  -p ${PROJECT} ${args} exec $1 ${SHELL}
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
            # Bare `restart` with no service names: some Compose versions do not restart
            # services from merged `-f services/*.yml`; expand full service list explicitly.
            if [[ "$1" == "restart" && "$#" -eq 1 ]]; then
                _all_svc=$(docker-compose -p ${PROJECT} ${args} config --services 2>/dev/null)
                if [ -n "${_all_svc}" ]; then
                    # shellcheck disable=SC2086
                    docker-compose -p ${PROJECT} ${args} restart ${_all_svc}
                else
                    docker-compose -p ${PROJECT} ${args} restart
                fi
            else
                # `up` (e.g. ./console start → compose up -d): drop orphan containers from
                # older compose merges so redis/extra services do not warn as orphans.
                if [[ "$1" == "up" ]]; then
                    _has_ro=false
                    for _a in "$@"; do
                        [[ "$_a" == "--remove-orphans" ]] && _has_ro=true && break
                    done
                    if ! $_has_ro; then
                        docker-compose -p ${PROJECT} ${args} "$@" --remove-orphans
                    else
                        docker-compose -p ${PROJECT} ${args} "$@"
                    fi
                else
                    docker-compose -p ${PROJECT} ${args} "$@"
                fi
            fi
        fi
    else
        echo ".env not found"
    fi
}

