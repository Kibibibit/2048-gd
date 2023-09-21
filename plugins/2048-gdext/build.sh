#!/bin/bash

cd godot-cpp
scons platform=linux -j4 custom_api_file=../extension_api.json
cd ..
