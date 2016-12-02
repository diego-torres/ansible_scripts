#!/bin/bash

#   EXAMPLES: 
#     ./provision-map-projects.sh -a --user=jbride-redhat.com --course=MAP_FOUNDATIONAL --email=jbride2000@gmail.com     :   Creates MAP_FOUNDATIONAL course using userId = jbride-redhat.com
#     ./provision-map-projects.sh -r --user=jbride-redhat.com --course=MAP_FOUNDATIONAL                                  :   Deletes MAP_FOUNDATIONAL course using userId = jbride-redhat.com

#   ADMIN NOTES:
#   This script is installed at:  ?
#   It is invoked by CloudForms.  The CloudForms log file can be viewed as followed:
#       1)  ssh <userId>@labs.opentlc.com
#       2)  tail -n 50 /var/www/miq/vmdb/log/automation.log
#
#   Client that invokes this script is in CloudForms ruby code written by Patrick
#   A new CloudForms "class" can be created via the following:  Automate -> Datastore -> OPEN -> OSELAB3 -> Class
#   Policy:  Provisioning Scope /  Able to see all non ILT OPENTLC labs in catalog
#
#   RHMAP accounts managed by this script can be seen at the variable $MAP_DOMAIN (defined below)

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
LOG_FILE=/tmp/map_provision.log
MAP_DOMAIN=gpte.us.training.redhatmobile.com

declare -A COURSES
COURSES=( ["MAP_FOUNDATIONAL"]=1 )


DEBUG=false
ADD=false
REMOVE=false
COURSE_EXIST=false
OPTS=`getopt -o ar -l user:,course:,email: -n 'parse-options' -- "$@"`
if [ $? != 0 ];
then
    echo "Failed parsing options." >&2;
    exit 1;
fi

eval set -- "$OPTS"

while true; do
    case "$1" in
        -a) ADD=true; shift;;
        -r) REMOVE=true; shift;;
        --user) USERNAME="$2"; shift 2;;
        --course) COURSENAME="$2"; shift 2;;
        --email) USER_EMAIL="$2"; shift 2;;
        --) shift; break;;
        *) break;;
    esac
done

verify_course() {
    for course in "${!COURSES[@]}"; do
        if [ "$COURSENAME" == "$course" ] ; then
            echo -en "\nverify_course() coursename = $COURSENAME exists!\n" >> $LOG_FILE;
            COURSE_EXIST=true
        fi
    done

    if [ $COURSE_EXIST = false ] ; then
        echo "The course $COURSENAME is not valid. Possible options are: ${!COURSES[@]} >> $LOG_FILE"
        exit 1
    fi

}

determine_project_name() {

    # prune username of "*.com" suffix
    # username_short="${USERNAME%.*}"

    # replace all dots by dash
    username_short=$(echo $USERNAME | sed -e 's/\./-/g')
    
    echo -en "determine_project_name() username_short = $username_short \n" >> $LOG_FILE;
    PROJECTNAME=$(echo $username_short-$COURSENAME | cut -c -63 | sed s/_/-/g | awk '{print tolower($0)}')
}


createMAPProject() {
    map_guid="";

    # 1)  Ensure email variable exists
    if [[ x$USER_EMAIL == x ]]; then
        echo -en "$USERNAME : must pass the user email address" >> $LOG_FILE
        exit 1;
    fi

    # 2)  Determine whether user already exists in MAP Core environment
    echo "$USERNAME : Creating MAP user with email: $USER_EMAIL" >> $LOG_FILE
    eval queryResponse=`curl -X POST -H "X-FH-AUTH-USER: 152ea76d89b0b60fecc1303d810cb9e6bc3bd7b2" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{ "username":"'$USERNAME'" }' https://$MAP_DOMAIN/box/srv/1.1/admin/user/read`

    if [[ $DEBUG == true ]]; then echo -en "$USERNAME : DEBUG queryResponse = $queryResponse\n" >> $LOG_FILE;  fi

    if [[ $queryResponse == *"User not found"* ]]; then


        echo "$USERNAME : User does not exist in MAP Core.  Will now create with email = $USER_EMAIL" >> $LOG_FILE

        # 3)  User does not exist in MAP Core.  Create user given name and email
        eval postResponse=`curl -X POST -H "X-FH-AUTH-USER: 152ea76d89b0b60fecc1303d810cb9e6bc3bd7b2" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d'{ "username":"'$USERNAME'", "email":"'$USER_EMAIL'", "name":"'$USERNAME'", "invite":true}' \
            "https://$MAP_DOMAIN/box/srv/1.1/admin/user/create"`

    	if [[ $postResponse == *"status:error"* ]]
        then
    	    echo -en "$USERNAME : Error postResponse = $postResponse\n" >> $LOG_FILE
            exit 1;
	elif [[ $postResponse == *"user_invalid_email"* ]]; then
    	    echo -en "$USERNAME : Error postResponse = $postResponse\n" >> $LOG_FILE
            exit 1;
	elif [[ $postResponse == *"status:ok"* ]]; then
      	    echo -en "$USERNAME : successfully created user: postResponse = $postResponse\n" >> $LOG_FILE;

            # 4)  User should now exist.  Query MAP Core to determine GUID
    	    eval queryResponse=`curl -X POST -H "X-FH-AUTH-USER: 152ea76d89b0b60fecc1303d810cb9e6bc3bd7b2" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{ "username":"'$USERNAME'" }' https://$MAP_DOMAIN/box/srv/1.1/admin/user/read`
            if [[ $DEBUG == true ]]; then echo -en "$USERNAME : DEBUG queryResponse = $queryResponse\n" >> $LOG_FILE;  fi
            map_guid=${queryResponse##*guid:}
            map_guid=${map_guid%%,*}
      	    echo -en "$USERNAME : successfully created user: map_guid = $map_guid\n" >> $LOG_FILE;

            # 5)  Add user to Student team
            eval postResponse=`curl -X POST -H "X-FH-AUTH-USER: 152ea76d89b0b60fecc1303d810cb9e6bc3bd7b2" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{ "guid":"'$map_guid'" }' \
                https://$MAP_DOMAIN/api/v2/admin/teams/57f6aab1adc986a25304bd2b/user/${map_guid}`

            if [[ $DEBUG == true ]]; then echo -en "$USERNAME : DEBUG add student to team: postResponse = $postResponse\n" >> $LOG_FILE;  fi
        else
      	    echo -en "$USERNAME : ERROR: postResponse = $postResponse\n" >> $LOG_FILE;
            exit;
        fi


    elif [[ $queryResponse = *"status:ok"* ]]; then
        echo -en "$USERNAME : MAP user already found; Completing\n" >> $LOG_FILE
    else 
        echo -en "$USERNAME : ERROR querying for user = $queryResponse\n" >> $LOG_FILE;
        exit 1;
    fi

}

deleteMAPProject() {

    echo "$USERNAME : Deleting MAP user " >> $LOG_FILE
    eval deleteResponse=`curl -X POST -H "X-FH-AUTH-USER: 152ea76d89b0b60fecc1303d810cb9e6bc3bd7b2" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -d '{ "username": "'$USERNAME'" }' \
      "https://$MAP_DOMAIN/box/srv/1.1/admin/user/delete"`

    if [[ $deleteResponse != *"status:ok"* ]]; then
        echo -en "$USERNAME : ERROR deleting user. Response = $deleteResponse\n" >> $LOG_FILE;
        exit 1;
    fi
}


echo -en "\n`date`" >> $LOG_FILE
verify_course
determine_project_name
if [ "$ADD" = true ] ; then
    if [ "$COURSENAME" == "MAP_FOUNDATIONAL" ] ; then
        createMAPProject 
    else
        echo "Unable to create project from unknown Course: $COURSENAME ; $PROJECTNAME ;  USERNAME= $USERNAME" >> $LOG_FILE
        exit 1;
    fi
elif $REMOVE ; then
    if [ "$COURSENAME" == "MAP_FOUNDATIONAL" ] ; then
        deleteMAPProject 
    else
       echo "Unable to remove project from unknown Course: $COURSENAME ; $PROJECTNAME ;  USERNAME= $USERNAME" >> $LOG_FILE
       exit 1;
    fi
fi
