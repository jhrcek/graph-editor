#!/bin/bash
rm -f dist/app.js
elm make --yes --warn src/Main.elm --output=dist/app.js
