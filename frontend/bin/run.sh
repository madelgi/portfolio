#!/usr/bin/env sh

if [ "$BUILD_ENV" == "development" ]; then
    echo "Running development server"
    gatsby develop -H 0.0.0.0
else
    echo "Running production server"
    gatsby serve -H 0.0.0.0
fi
