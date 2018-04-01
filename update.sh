#!/bin/sh

# update wordpress core
rm -rf ./WordPress
git clone --depth 1 https://github.com/WordPress/WordPress.git
rm -rf ./WordPress/.git
cp -rf ./WordPress/* .
rm -rf ./WordPress

# update Gitium from a non-official herokuish-friendly fork
rm -rf ./gitium
git clone --depth 1 git@github.com:jlcastillo/gitium.git
cp -rf ./gitium/gitium wp-content/plugins
rm -rf ./gitium
