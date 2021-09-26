const { spawn } = require('child_process');

const console = require('../console');
const inputs = require("../inputs");

function func(environment, service) {

  const command = 'aws';
  const arguments = ['codebuild', 'start-build', '--project-name', `${service}-cb`, '--environment-variables-override', 'name=ENVIRONMENT,value=' + environment, '--profile'];

  const build = spawn(command, arguments.concat(['sdlc']));

  build.stdout.on('data', (data) => {
    console.logHeading(`The ${service} build started. If it completes successfully it will be auto-deployed to the ${environment} environment.`)
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
    .command('build')
    .description('initiate service builds on specific environments')
    .addArgument(inputs.arguments.services)
    .addOption(inputs.options.environments)
    .action((services, options) => {

      if (Array.isArray(services)) {
        services.forEach((service) => buildEnvironments(options.environments, service));
      } else {
        buildEnvironments(options.environments, services);
      }

    })
    .addHelpText('after', `
      Examples:
        $ sdlc build -e dev -- conwell
        $ sdlc build -e dev staging -- curie
        $ sdlc build -e all -- meitner`
    );
}
