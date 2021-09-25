const { Option, Argument } = require('commander');

const description = module.exports.description = 'specify a specific version';
const semver = /^((([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)$/

module.exports.isValid = function (version) {
  return semver.test(version);
}

module.exports.option = new Option('-v, --version [version]', description)
module.exports.argument = new Argument('[version]', description)
