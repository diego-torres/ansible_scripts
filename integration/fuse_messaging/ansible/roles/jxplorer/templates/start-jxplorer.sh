#!/bin/bash

pushd {{jxplorer_home}} 
nohup {{jxplorer_home}}/jxplorer.sh 0<&- &>/dev/null &
popd