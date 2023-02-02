# phpenv
Docker php 容器化專案執行環境

透過.env指定專案路徑，搭配ssh服務，就能使用VSCode的ssh-remote簡易的連進容器中。

您可以將不需要的容器服務註解掉或開啟。


進階用途:
可透過放置不同的env檔到envs資料夾，執行多個不同的專案。

第一步: 執行link即可產生預設的.env設定檔。

<pre>
./link
</pre>

第二步: 依自己的環境調整專案名稱及開啟的連接埠

您可以加上正確的USER_ID及GROUP_ID，特別在Linux環境很有用。

預設容器會使用uid及gid 1000執行，nginx及php，依自己的環境可以調整正確的USER_ID及GROUP_ID。

<pre>
#SERVICES="mariadb"
APP_URL=http://127.0.0.1:1050
PROJECT=default
FOLDER=..
HTTP_PORT=1050
HTTPS_PORT=1150
DB_PORT=1250
SSH_PORT=2222
DRIVE_PORT=2223
USER_ID=1000
GROUP_ID=1000
</pre>

例如:
下方是我Synology NAS下的環境，在Linux的環境資料庫的目錄會建立失敗，
請自行調整data目錄中資料夾權限。
<pre>
DotEnv Settings
SERVICES="ssh_db mariadb_ssh redis "
PROJECT=ccc
APP_URL=http://127.0.0.1:1056
FOLDER=/volume1/docker/ccc
NETWORK_MOD=host
HTTP_PORT=1056
SSH_PORT=2256
DB_PORT=3356
USER_ID=1026
GROUP_ID=100
</pre>


第三步: 移除#SERVICE的註解以啟動資料庫服務。

您可以由services的資料夾中查看有那些服務能用，例如: redis，以空白格開不同的服務名稱。

SERVICES="mariadb redis drive"

drive服務不提供PHP，主要可用於資料上傳，或是Laravel的Storage Filesystem的SFTP功能。
<pre>
./console build drive
</pre>

第四步: 建立容器，僅需執行一次，除非您變動USER_ID或GROUP_ID時，才需重buidl。

重要: 如果您是執行中的舊專案，請確認php版號一制，必免因PHP升級造成程式執行異常

第一次啟動容器時，可透過./console build建立容器，預設的image名稱prefix為default，會依據您dot env中的PROJECT而變更。
<pre>
default_drive
default_ssh
default_nginx
default_php
</pre>


指令說明
<pre>
./link 選擇環境或產生初始化環境變數範本
./start 啟用
./restart 停用再啟用容器
./stop 停用
./stop [project_name] 停用啟動中，非.env設定中的專案服務。
./relaod 重整nginx設定
./info 顯示.env資訊
./syn_auth.sh 同步自己的公鑰到authorized_keys中，用於ssh驗證
./gen_ssl_for_test.sh [name] 建立自簽憑證並自動匯入MacOs鑰匙圈，name後方會自動追加.test
./del_know_host.sh [interger] 在MacOS環境用來快速刪除~/.ssh/known_hosts特定行號
./artisan 用來執行php容器服務的artisan指令
./console 串接docker原生的命令，自動依.env代入project名稱，另外提供本專案的一些子命令。

#多env檔(進階操作)
./all 查看所有envs中的PROJECT服務啟動狀態
./all start envs資料夾中的所有env檔，env檔的PROJECT名稱及啟動的PORT不可重覆，會自重連結到每個.env檔進行啟動。
./all stop  停用envs資料夾的所有服務，會自重連結到每個.env檔進行停止

</pre>

範例:

容器啟動時，預設進入php容器中

<pre>
./console
</pre>

進入資料庫容器，相當於執行docker-compose exec。
<pre>
./console exec db bash
</pre>

執行artisan的命令，例如查看框架版本，相當於執行php artisan。

<pre>
./console artisan -V
</pre>


Drive服務密碼變更，可用於Laravel Storage Filesystem的SFTP
drive容器為隨機密碼，要登入我們需要重新設定密碼，指令如下

<pre>
./console exec drive passwd dlaravel
</pre>

設更密碼後，我們需要重新commit我們自己的image，以便下次重啟時，密碼不會被還原。



如果您不熟悉如何取得drive服務的container id，可以透過如下指令取得啟動中的drive容器id。

<pre>

docker ps|grep $(./console ps drive|tail -n1|awk '{print $1}')

</pre>

類似下方這樣，commit drive的image
<pre>
docker commit fbaaaea6b8fd [專案名稱]_drive
</pre>

