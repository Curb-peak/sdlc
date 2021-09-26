const { spawn } = require('child_process');

const console = require('../console');
const inputs = require("../inputs");
const { names: serviceNames } = require("../models/services")
const { names: environmentNames } = require("../models/environments")

function getAMI(environment, service, version) {

  const command = 'aws';
  const argumentsString = `ec2 describe-images --filters "Name=tag:VERSION,Values=${version}" "Name=tag:SERVICE,Values=${service}" "Name=tag:ENVIRONMENT,Values=${environment}" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text --profile`
  const arguments = String.split(argumentsString, ' ');

  const build = spawn(command, arguments.concat(['sdlc']));

  build.stdout.on('data', (data) => {
    console.logHeading(`AMI found ${service} deploy started. Upon successful completion it will be auto-deployed to the ${environment} environment.`)
    console.log(data);
  });

  build.stderr.on('data', (data) => {
    console.errorHeading(`The ${service} build failed. It was scheduled to be deployed to the ${environment} environment.`)
    console.error(data);
  });
}
function func(environment, service, version) {

  const command = 'aws';
  const arguments = ['codebuild', 'start-build', '--project-name', `${service}-cb`, '--environment-variables-override', 'name=ENVIRONMENT,value=' + environment, '--profile'];

  const build = spawn(command, arguments.concat(['sdlc']));

  build.stdout.on('data', (data) => {
    console.logHeading(`The ${service} deploy started. Upon successful completion it will be auto-deployed to the ${environment} environment.`)
    console.log(data);
  });

  build.stderr.on('data', (data) => {
    console.errorHeading(`The ${service} build failed. It was scheduled to be deployed to the ${environment} environment.`)
    console.error(data);
  });
}

function buildEnvironments(environments, service) {
  if (Array.isArray(environments)) {

    environments.forEach((environment) => {
      func(environment, service)
    })

  } else {
    func(environments, service);
  }
}

module.exports = function (program) {

  program
    .command('deploy')
    .description('initiate service builds on specific environments')
    .addArgument(inputs.arguments.services)
    .addOption(inputs.options.environments)
    .addOption(inputs.options.version)
    .action((services, options) => {

      if (services.indexOf('all') > -1){
        services = serviceNames;
      }

      if (options.environments.indexOf('all') > -1){
        options.environments = environmentNames;
      }

      if (Array.isArray(services)) {
        services.forEach((service) => buildEnvironments(options.environments, service));
      } else {
        buildEnvironments(options.environments, services);
      }

    })
    .addHelpText('after', `
      Examples:
        $ sdlc deploy -e dev -v 0.0.1 -- conwell
        $ sdlc deploy -e dev staging -v 1.4.53 -- curie
        $ sdlc deploy -e all -v 3.2.131 -- meitner`
    );

}
