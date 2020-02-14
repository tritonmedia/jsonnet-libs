{
  // Workflow creates a workflow
  Workflow():: {
    jobs: [
      // we support using strings, or supplying valid workflow objects w/ a name:: prop
      // to specify the name of it
      { [if std.type(job) == 'object' then job.name else job ]: { context: 'Docker' } + if std.type(job) == 'object' then job else {} } 
      for job in self.jobs_
    ],
  },

  // Job creates a CircleCI Job
  Job(dockerImage = 'docker:19.03.5', withDocker=true):: {
    local steps = self.steps_,
    docker: [
      { image: dockerImage },
    ],
    local staticSteps = ["checkout"],
    steps: staticSteps + (if withDocker == true then [{ setup_remote_docker: { version: '18.09.3' } }] else [])
    + steps,
  },

  // RunStep creates a { run: { name, command } } CircleCI step
  RunStep(name, command):: {
    run: {
      name: name,
      command: command,
    }
  },

  // SaveCacheStep creates a save_cache circle step
  SaveCacheStep(key, paths):: {
    save_cache: {
      key: key,
      paths: paths,
    },
  },

  // RestoreCacheStep creates a restore_cache step
  RestoreCacheStep(key):: {
    restore_cache: {
      key: key,
    },
  },

  // BuildDockerImageStep builds a docker image
  BuildDockerImageStep(name, Dockerfile='Dockerfile'):: $.RunStep(
    'Build "%s" Docker Image' % name,
    'DOCKER_BUILDKIT=1 docker build --progress=plain -t %s -f %s .' % [name, Dockerfile],
  ),

  // PublishDockerImageStep publishes a docker image
  PublishDockerImageStep(name):: $.RunStep(
    'Publish "%s" Docker Image' % name,
    'echo "$DOCKER_PASSWORD" | docker login --username "${DOCKER_USERNAME}" --password-stdin && docker push %s' % name,
  ),

  // ServiceConfig create a CircleCI default configuration file
  ServiceConfig(name):: {
    version: 2,
    jobs: {
      build: $.Job() {
        local imageName = 'tritonmedia/%s' % name,
        steps_:: [
          $.BuildDockerImageStep(imageName),
          $.PublishDockerImageStep(imageName)
        ],
      },
    },
    workflows: {
      version: 2,
      ['build-push']: $.Workflow() {
        jobs_:: ['build'],
      },
    },
  },
}
