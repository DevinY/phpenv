#!/bin/bash

# Detect if "docker compose" is available as a plugin, otherwise fallback to docker-compose
if docker help | grep -qi "docker compose"; then
    function docker-compose() {
        docker compose "$@"
    }
fi

# Helper: Get value from .env file
function get_env_val() {
    local key=$1
    local default=$2
    if [[ -f .env ]]; then
        local val=$(grep -Ei "^${key}=" .env | head -1 | cut -d= -f2- | tr -d '\r' | sed "s/^['\"]//;s/['\"]$//")
        echo "${val:-$default}"
    else
        echo "$default"
    fi
}

function get_project() {
    local project=$(get_env_val "PROJECT")
    if [[ -z "$project" ]]; then
        echo "PROJECT variable not found in .env" >&2
        exit 1
    fi
    echo "$project"
}

function get_workspace() {
    get_env_val "WORKSPACE" "php"
}

function default_yml_file() {
    get_env_val "DEFAULT" "docker-compose"
}

function services_list_from_env() {
    get_env_val "SERVICES" ""
}

function get_args() {
    local args="-f $(default_yml_file).yml"
    for SERVICE in $(services_list_from_env); do
        if [[ -f "services/${SERVICE}.yml" ]]; then
            args+=" -f services/${SERVICE}.yml"
        fi
    done
    echo "$args"
}

# Sync php-fpm pool user/group in etc/php-fpm.d/www.conf with USER_ID/GROUP_ID from .env
function sync_php_fpm_www_conf_from_env() {
    local www_conf="${PHPENV:-.}/etc/php-fpm.d/www.conf"
    [[ -f "$www_conf" ]] || return 0

    local uid=$(get_env_val "USER_ID" "1000")
    local gid=$(get_env_val "GROUP_ID" "1000")

    local cur_user=$(awk '/^user[ \t]*=/ && $0 !~ /^[ \t]*;/ { gsub(/^[ \t]*user[ \t]*=[ \t]*/, ""); gsub(/[ \t]+$/, ""); print; exit }' "$www_conf")
    local cur_group=$(awk '/^group[ \t]*=/ && $0 !~ /^[ \t]*;/ { gsub(/^[ \t]*group[ \t]*=[ \t]*/, ""); gsub(/[ \t]+$/, ""); print; exit }' "$www_conf")

    if [[ "$cur_user" == "$uid" && "$cur_group" == "$gid" ]]; then
        return 0
    fi

    echo "php-fpm www.conf: user/group ${cur_user:-?}/${cur_group:-?} -> ${uid}/${gid} (from .env)"
    local tmp=$(mktemp) || return 1
    sed -E -e "s/^user[[:space:]]*=.*/user = ${uid}/" -e "s/^group[[:space:]]*=.*/group = ${gid}/" "$www_conf" > "$tmp" && mv "$tmp" "$www_conf"
}

# Read or rotate Redis requirepass in services/redis.yml
function print_or_rotate_redis_yml_secret() {
    local redis_yml="${PHPENV:-.}/services/redis.yml"
    local default='You_Should_Change_This_Password'
    [[ -f "$redis_yml" ]] || { echo "services/redis.yml not found." >&2; return 1; }

    local line=$(grep -E 'redis-server.*--requirepass' "$redis_yml" | grep -Ev '^[[:space:]]*#' | head -1)
    [[ -z "$line" ]] && { echo "No redis-server --requirepass line found in services/redis.yml" >&2; return 1; }

    local current=$(printf '%s\n' "$line" | sed -E 's/.*--requirepass[[:space:]]+//;s/[[:space:]]+$//')
    [[ -z "$current" ]] && { echo "Could not parse Redis password from services/redis.yml" >&2; return 1; }

    if [[ "$current" == "$default" ]]; then
        local new_secret=$(openssl rand -hex 32)
        local tmp=$(mktemp) || return 1
        sed "s|${default}|${new_secret}|g" "$redis_yml" > "$tmp" && mv "$tmp" "$redis_yml"
        echo "$new_secret"
    else
        echo "$current"
    fi
}

function start() {
    mkdir -p etc/cache
    touch authorized_keys
    source .env
    echo "${APP_URL}"
    local project=$1
    local args=$(get_args)
    docker-compose -p "${project}" ${args} up -d --remove-orphans
}

function stop() {
    touch authorized_keys
    source .env
    echo "${APP_URL}"
    local project=$1
    local args=$(get_args)
    docker-compose -p "${project}" ${args} down --remove-orphans
}

function exec_bash() {
    local project=$(get_project)
    local args=$(get_args)
    local workspace=$1
    local subdir=$2

    echo "Entering the \"$project\" project in the $workspace container."
    
    if [[ "$workspace" == 'php' ]]; then
        docker-compose -p "${project}" ${args} exec -w "/var/www/html/${subdir}" -u dlaravel php ${SHELL}
        if [[ $? -eq 1 ]]; then
            # Fallback to docker run if exec fails
            echo "Fallback: docker run..."
            docker run --rm -v "$(readlink -f ./):/var/www/html" -ti "${project}_php" ${SHELL}
        fi
    else
        docker-compose -p "${project}" ${args} exec "${workspace}" ${SHELL}
    fi
    exit
}

function console() {
    if [[ ! -f .env ]]; then
        echo ".env not found"
        return 1
    fi

    source .env
    local project=$(get_project)
    local args=$(get_args)

    if [[ "$1" == "ps" ]]; then
        local output=$(docker-compose -p "${project}" ${args} ps)
        echo -e "$output"
        
        if [[ "$DEFAULT" == "random" ]]; then
            local port=$(echo "$output" | grep "${project}-web-1" | sed -r 's/.+0.0.0.0:([[:digit:]]+)->80.+/\1/g')
            [[ -n "$port" ]] && echo "http://127.0.0.1:$port"
        else
            echo "${APP_URL}"
        fi
    elif [[ "$1" == "restart" && "$#" -eq 1 ]]; then
        local all_svc=$(docker-compose -p "${project}" ${args} config --services 2>/dev/null)
        if [[ -n "${all_svc}" ]]; then
            docker-compose -p "${project}" ${args} restart ${all_svc}
        else
            docker-compose -p "${project}" ${args} restart
        fi
    elif [[ "$1" == "up" ]]; then
        # Ensure --remove-orphans is present unless already specified
        if [[ "$*" != *"--remove-orphans"* ]]; then
            docker-compose -p "${project}" ${args} "$@" --remove-orphans
        else
            docker-compose -p "${project}" ${args} "$@"
        fi
    else
        docker-compose -p "${project}" ${args} "$@"
    fi
}
