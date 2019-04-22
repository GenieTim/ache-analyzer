#!/bin/bash

cd "${0%/*}" || exit;
# check that inputs exist
touch headacheData.xlsx;
touch config.json;
# check that cache tables exist
touch fitnessData.xlsx;
touch weatherData.xlsx;
