#!/bin/bash
rm -f dist/app.js
elm make --warn src/Main.elm --output=dist/app.js
