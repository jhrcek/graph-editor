#!/bin/bash
rm -f app.js
elm make --warn --debug src/Main.elm --output=app.js
