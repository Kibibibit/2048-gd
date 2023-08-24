#!/bin/bash

cd godot-cpp
scons platofrm=linux -j4 custom_api_file=../extension_api.json
cd ..
