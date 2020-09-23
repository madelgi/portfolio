if [ "$BUILD_ENV" == "development" ]; then
    gatsby develop -H 0.0.0.0
else
    gatsby serve -H 0.0.0.0
fi
