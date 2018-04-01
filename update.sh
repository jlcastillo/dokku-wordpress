#!/bin/sh

# update wordpress core
git clone --depth 1 https://github.com/WordPress/WordPress.git
rm -rf WordPress/.git
mv -f WordPress/* .
rm -rf WordPress

# update Gitium from a non-official herokuish-friendly fork
git clone --depth 1 git@github.com:jlcastillo/gitium.git
mv -f gitium/gitium wp-content/plugins
rm -rf gitium
