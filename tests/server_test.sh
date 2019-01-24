#!/bin/sh

#################################################
### Functions
#################################################
Puts_help () {
    MY_BASENAME=$(basename $0)
	echo "This script is test script for goohub server．"
    echo "\nCaution!"
    echo "In order to use ${MY_BASENAME}, you should run redis-server. "
    echo "And, You should use this script in '~/Project/goohub'"
    echo "\nUsage:"
    echo "bash ${MY_BASENAME} <options>"
    echo "<options>"
    echo "help(or -h): Puts this help"
    echo "init(or -i) type: Init relation DB"
    echo "exec(or -e) type: Exec test"

}

Exec () {
    # If comment out while ~ done, this script become server
    # while true; do
    y=`date +%Y`
    m=`date +%m | sed 's/0//g'`
    e_ids=`(bundle exec ruby exe/goohub server kjtbw1219@gmail.com ${y}-${m} ${y}-${m})`
    for e_id in ${e_ids[@]}
    do
        bundle exec ruby exe/goohub share kjtbw1219@gmail.com ${e_id} --filter=location_delete --action=stdout # TODO: improve filter!(set parameter or set filter_id)
    done
    #     sleep 60;
    # done

}

#################################################
### Main part
#################################################
if [ -z "$1" ]
then
	type="no"
else
	type="$1"
fi

case "${type}" in
	"init" | "-i") y=`date +%Y`
                   m=`date +%m | sed 's/0//g'`
                   redis-cli del kjtbw1219@gmail.com-${y}-${m} #for init
			       ;;
	"help" | "-h") Puts_help
			       ;;
    "exec" | "-e") Exec
			       ;;
	*) echo "If you want to show help, please type 'server_raw_test.sh -h'"
	   ;;
esac
