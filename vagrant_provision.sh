#! /bin/sh

sudo apt-get update
sudo apt-get install software-properties-common python-software-properties python g++ make -y

sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs -y

npm config set prefix ~/npm
export PATH=$HOME/npm/bin:$PATH

sudo apt-get install coffeescript -y

npm install -g coffee-script

cd ~/project/
npm install jsdom request --save