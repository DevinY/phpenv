#!/bin/bash
if [ -f .env ];then
    
    source .env
    docker-compose -p ${PROJECT} logs -f php

else

    echo ".env not found"

fi
