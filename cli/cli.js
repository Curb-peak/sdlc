#!/usr/bin/env node

/*
features
  - check logs builds

  - deploy to dev, staging, and prod
  - terraform management
  - create a new service from template

  - view environment version matrix
  - view environment deltas

  - deploy --services [services...]
    - reuse artifacts from another environment and deploy them


d98d52d74e9cb5ea9cf75dfedefc3db2d4e41555 (HEAD -> devopsV2, origin/devopsV2) [DEV] bump
fdac92af9c548cefd9fa25d630468ae94c68b6b8 Merge branch 'devopsV2' of https://github.com/Curb-sdlc/devops into devopsV2
8d0cab9658b0ccbae79d82751ba299ed76e5a60a switched dev env to use the correct acm
13687ace8e8de451fb6b4ccd0273b12aaf0a604b funcitonal first pass on configuration management.. do not need to maintain separate versions of baked amis for each service | version pair
e0097ed124c18636ba660d7a6a1afe786cf9fb3b removed extraneous files
7825a4f0f7ddc6f8643902f7b55753fee4ad862e funcitonal first pass on configuration management.. do not need to maintain separate versions of baked amis for each service | version pair
b28b9ef117d4edabda4ffd0c6980710d3aebc952 (tag: devopsV2-v0.0.1) [DEV] - test deploy
a42e31c3e74b63c449921b23387a1766461776ad [DEV]
c8f5c211aea71ea8a525afec2a5a08f9e8a0d34f getting rid of dev branch
63564baec64fdd294800a64edd266993142e538a (devopsRefactor) more build script love
d9d006fc47c4da83275e50599cc8b1e7c2ac3904 [DEV] launch dev
80ba37b1a16438f3753be3ed9d23780f804335dd [DEV] testing 123
3cdb481fff70fc87c03cc97ff19024835e353528 remove extraneous files
a44cbfa622a8309da9ebb24e469867650d943091 remove extraneous files
b4ab08f4f56a1e6214ed39f4ec09c2dd250a4f3a first pass at configuration management
97d7d59f3708c6882fa12c6525b7169c385ef019 fixed launch template tags.. fixed make scripts for starting builds and refreshing service instances
6868481a4f63cef7043d5e6dc023cd841f2057f9 fix/add some make scripts.. additional debugging for deplo

   - build history
   - version history

   - env service create --service --environment
   - env service destroy --service --environment

   - env create --name
   - env destroy --name

   - service create --name --port --instances
   - service destroy --name




  commands
   - env: all environment commands automatically switch terraform workspace
     - deploy
     - versions
     - logs
*/
const { Command } = require('commander');
const deploy = require('./cmds/deploy');
const build = require('./cmds/build');

const program = new Command();

program
  .version('0.0.1')
  //.option('-c, --config <path>', 'set config path', './deploy.conf');

build(program);
deploy(program);

program.parse(process.argv);
