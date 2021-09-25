const { Option, Argument } = require('commander');

const services = module.exports.services = require('./services.json');
const names = module.exports.names = Object.keys(services);
const description = module.exports.description = 'list of services';

module.exports.option = new Option('-s, --services <services...>', description)
    .choices(names);

module.exports.argument = new Argument('<services...>', description)
    .choices(names);
