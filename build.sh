#!/bin/bash
elm make --yes --warn src/Main.elm --output=dist/js/app.js
# uglifyjs dist/js/app.js --compress --mangle --output dist/js/app.js
