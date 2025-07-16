#!/usr/bin/env bash

system_profiler SPPowerDataType -json | jq '.SPPowerDataType[] | select(._name == "sppower_ac_charger_information") | .sppower_ac_charger_watts | tonumber'
