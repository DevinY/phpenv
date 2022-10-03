#!/bin/bash
PUBS=$(ls ~/.ssh/id_*.pub)
for o in $PUBS
do
    touch authorized_keys
    PUBLIC_KEY=$(cat $o)
    grep -q "$PUBLIC_KEY" authorized_keys
    if [ $? -gt 0 ]; then
        cat $o >> authorized_keys
    fi
done
