#!/bin/bash

declare -r URI="$1"
declare -r CLUSTER="$2"
declare TASKS="$3"
TASKS=( $(echo $TASKS) )

function verifyURI {
    declare -r _URI="$1"

    HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}\n' "$_URI")
    if [[ $HTTP_CODE == "200" ]]; then
        return 0
    else
        return 1
    fi
}

function testAvailability {
    declare -r _URI="$1"
    declare -r _WAIT_TIMER="${2:-300}"
    declare -r _AVAILABILITY_TIMER="${3:-10}"

    declare _WAIT_COUNTER=0
    declare _AVAILABILITY_COUNTER=0

    while (( _WAIT_COUNTER < _WAIT_TIMER )); do
        if verifyURI "$_URI"; then
            if (( _AVAILABILITY_COUNTER < _AVAILABILITY_TIMER )); then
                (( _AVAILABILITY_COUNTER+=1 ))
            else
                echo "Availability restored succesfully"
                return 0
            fi
        fi
        sleep 1
        (( _WAIT_COUNTER+=1 ))
    done

    echo "Availability could not be restored after ${_WAIT_TIMER} seconds."
    exit 1
}

if ! verifyURI "$URI"; then
    echo "URI \"$URI\" cannot be reached."
fi

echo "Testing availability after stopping all tasks in one AZ..."
aws ecs stop-task --cluster $CLUSTER --task "${TASKS[0]}" --no-cli-pager 1> /dev/null
testAvailability $URI

echo "Testing durability after stopping all tasks..."
for TASK in ${TASKS[@]}; do
    aws ecs stop-task --cluster pha-cluster --task $TASK --no-cli-pager 1> /dev/null
done
testAvailability $URI
