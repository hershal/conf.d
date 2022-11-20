#!/usr/bin/env bash

script=$(basename $0)
scriptname=${script}-$$
interval=5
counter=0
exit_after=-1


while [[ $# -gt 0 ]]; do
    key=$1
    case ${key} in
	      -i|--interval)
	          interval=$2; shift;;
        -e|--exit-after)
            exit_after=$2; shift;;
        -h|--help|*)
            echo "${script} -- run MMA levels for Blackwell"
            echo "Usage: ${script} [-h|--help] [--interval|-i <interval>]"
            echo "-i|--interval <seconds>"
            echo "        Specify an interval to print the script is still running."
            echo "        Currently set to ${interval} seconds"
            echo "-e|--exit-after <seconds>"
            echo "        Exit after <seconds> seconds"
            echo "        Currently set to ${exit_after} seconds."
            echo "-h, --help:"
            echo "        Print this message and quit."
            exit 0;;
    esac
    shift
done


killall() {
    echo $scriptname... done.
}
trap 'killall' EXIT

echo $scriptname...
while sleep 1; do
    counter=$(($counter+1))

    if [[ $(expr $counter % $interval) == 0 ]]; then
        echo $scriptname still running...
    fi

    if [[ $exit_after -ge 0 ]] && [[ $counter > $exit_after ]]; then
        exit
    fi
done

