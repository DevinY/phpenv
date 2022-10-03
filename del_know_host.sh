#!/bin/bash
if [ $1 ]; then
    sed -i '' "$1d" ~/.ssh/known_hosts
    else
    echo "$0 <line number>" 
fi
