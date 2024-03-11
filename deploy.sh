#!/usr/bin/bash
# deploys a web static to given servers

set -e # exit if any command returns a none 0 status. i.e command failed

if [ $# != 3 ]; then
    echo "Usage: ./deploy.sh server_name1 server_name2 deployment_file"
    exit 1
fi

servers=("$1" "$2")
inputFile=$3
dtime="$(date +'%Y%m%d%H%M%S')"
file="$inputFile$dtime"

echo ""
echo "After this operation, the deployed version will be stored in the folder 'versions/'"
echo "Deployment will commence in 10 seconds. Check if you entered correct information."
echo "Press ctrl c, to cancel if you made a mistake."
echo ""

for ((j=9;j>-1;j--)); do
    sleep 1
    echo -ne "Starting deployment in $j\r"
done
clear

echo "Your new archive will be named:        $file"
echo ""

echo "Deploying to the following servers: "
echo ""
for i in "${servers[@]}"; do
    printf "        %s\n" "$i" 
done

if [ ! -d versions ]; then
    mkdir "versions/"
fi

tar -czf "versions/$file.tgz" "$inputFile"

for i in "${servers[@]}"; do
    echo ""
    scp -i ~/.ssh/id_rsa "versions/$file.tgz" "ubuntu@$i:/tmp/"
    echo ""
    echo "Copied archive file to server:        $i in directory:        /tmp/"
    echo ""
    echo "Extracting archive to:        /data/web_static/releases/ ..."
    echo ""
    ssh ubuntu@"$i" "mkdir /data/web_static/releases/new && tar -xzf /tmp/$file.tgz -C /data/web_static/releases/new" 
    ssh ubuntu@"$i" "mv /data/web_static/releases/new/web_static /data/web_static/releases/$file"
    echo "Here are the new contents of the releases directory: "
    echo ""
    ssh ubuntu@"$i" "sudo rm -r /data/web_static/releases/new/ && ls /data/web_static/releases/ | sed 's/^/\t\t\t/'"
    echo ""
    ssh ubuntu@"$i" "sudo rm -rf /data/web_static/current && ln -s /data/web_static/releases/$file /data/web_static/current"
    echo "Finished making a symbolic link for the new web static on server:        $i"
    echo ""
    ssh ubuntu@"$i" "sudo rm -rf /tmp/$file.tgz && sudo service nginx restart"
    echo ""
    echo "Deleted the archive from /tmp/, and restarted the Nginx server."
    echo ""
done

echo "Your newest release ( $file ) of web_static is now live on /hbnb_static/! You can visit: "
echo ""       
echo "                                     ${servers[0]}/hbnb_static/100-index.html or"
echo ""
echo "                                     ${servers[1]}/hbnb_static/100-index.html to view your web static"
