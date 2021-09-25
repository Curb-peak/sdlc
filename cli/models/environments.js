const { Option, Argument } = require('commander');

const environments = module.exports.environments = require('./environments.json');
const names = module.exports.names = Object.keys(environments);
const description = module.exports.description = 'list of environments';

const defaultOption = module.exports.defaultOption = names[0];

module.exports.option = new Option('-e, --environments [environments...]', description)
  .choices(names.concat(['all']))
  .default(defaultOption)

module.exports.argument = new Argument('[environment...]', description)
    .choices(names.concat(['all']))
    .default(defaultOption)
