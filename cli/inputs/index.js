const {
  option: environmentsOption,
  argument: environmentsArg
} = require('../models/environments');

const {
  option: servicesOption,
  argument: servicesArg
} = require('../models/services');

const {
  option: versionOption,
  argument: versionArg
} = require('../models/version');

module.exports = {
  options: {
    environments: environmentsOption,
    services: servicesOption,
    version: versionOption
  },
  arguments: {
    environments: environmentsArg,
    services: servicesArg,
    version: versionArg
  }
}