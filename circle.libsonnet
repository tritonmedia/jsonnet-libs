{
  // Workflow creates a workflow
  Workflow():: {
    jobs: [
      { [job]: { context: 'Docker' } } 
      for job in self.jobs_
    ],
  },

  // Job creates a CircleCI Job
  Job(dockerImage = 'docker:19.03.5', withDocker=true):: {
    local steps = self.steps_,
    docker: [
      { image: dockerImage },
    ],
    steps: [
      "checkout",
      if withDocker == true then { setup_remote_docker: { version: '18.09.3' } },
    ] + steps,
  },

  // RunStep creates a { run: { name, command } } CircleCI step
  RunStep(name, command):: {
    run: {
      name: name,
      command: command,
    }
  },

  // ServiceConfig create a CircleCI default configuration file
  ServiceConfig(name):: {
    version: 2,
    jobs: {
      build: $.Job() {
        steps_:: [
          $.RunStep(
            'Build Docker Image', 
            'DOCKER_BUILDKIT=1 docker build -t jaredallard/%s -f Dockerfile .' % name,
          ),
          $.RunStep(
            'Publish Docker Image',
            'echo "$DOCKER_PASSWORD" | docker login --username "${DOCKER_USERNAME}" --password-stdin && docker push jaredallard/%s' % name,
          )
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
