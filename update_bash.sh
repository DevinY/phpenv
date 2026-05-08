#!/bin/bash
BASHFILES="start stop stats restart reload info link all ports artisan console .functions.sh update_bash.sh workspace artisan link activate db"

function update() {
    for f in $BASHFILES; do
        echo "Updating $f..."
        curl -H 'Cache-Control: no-cache, no-store' "https://raw.githubusercontent.com/DevinY/phpenv/main/$f" -so "$f"
        chmod +x "$f"
    done
    echo "Update complete."
}

echo "The following files will be updated: $BASHFILES"
echo "This will download the latest versions from the phpenv repository."
echo "Do you wish to proceed?"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) update; break;;
        No ) exit;;
    esac
done
