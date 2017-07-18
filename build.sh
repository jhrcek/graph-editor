#!/bin/bash
rm -f app.js
elm make src/Main.elm --output=app.js
