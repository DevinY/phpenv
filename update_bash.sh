#!/bin/bash
BASHFILES="start stop stats restart reload info link all ports artisan console .functions.sh update_bash.sh workspace artisan link activate db"
function update {
    for f in $BASHFILES
    do
    echo "Updating $f"
    curl -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/DevinY/phpenv/main/$f -so $f
    chmod +x $f
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
