#!/bin/bash
BASHFILES="start stop restart reload info link all ports artisan console .functions.sh"
function update {
    for f in $BASHFILES
    do
    echo "Updating $f"
    curl https://raw.githubusercontent.com/DevinY/phpenv/main/$f -so $f
    done
}
echo Files: "$BASHFILES" will be update.
echo "Do you wish to update bash files from phpenv. (bug fix and new functions)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) update; break;;
        No ) exit;;
    esac
done
