Run example

```
git clone https://github.com/rttomlinson/topsail.git
cd topsail/example
YAML_MANIFEST_SPEC_INPUT_FILENAME=service_manifest.yaml make step_service_manifest 
cd ..  
perl workflows.pl  
```

# Expose Docker control socket inside the Harness Delegate container
# to enable using containerized tools in Harness shell scripts
volumes = %W(
  /etc/docker:/etc/docker
  /var/run/docker.sock:/var/run/docker.sock
  /tmp:/tmp
)

docker run --init -v /tmp:/tmp -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:798750129590:activity:basic-activity

For deployer:
If running directly on machine
HOST_TEMPDIR set this. It must be reachable by the user running the script
i.e. must not traverse "up" the file system if you want to support docker running in the scripts (hint: you do want to support it)

If running as docker, be sure to mount docker paths and HOST_TEMPDIR along with passing as env var

For executor:
You have an env var called TMPDIR that is available
In order for your script to pass back data to the global execution context you must write out to a file of your selection AND create a file called <filename>.type (note the .type extention) this tell the executor to create your file and output the data as env vars that can be consumed in other scripts. You can pass any string values into your scripts via env vars. What you do with those strings is up to you. i.e. json encoded or whatever

How to make aws creds on the machine available to docker scripts
Does it automatically get the env vars? Probably not


# v1
# make sure running as root?
# do i need to make sure HOST_TEMPDIR exists?'# which also implies that whatever user the script runs as if it uses docker must also have access
# i.e. we should make? tell? the user to just use root user?
# what usecase for not using root user?
# HOST_TEMPDIR is the contract to the process_activity function for where the script has access to the host dir for file storage. no guarentees on scope
# run on local machine
if not root
sudo su root
export HOST_TEMPDIR="${HOME}/tmp"
echo $HOST_TEMPDIR
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker --env HOST_TEMPDIR="${HOST_TEMPDIR}" -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:044618531875:activity:basic-activity

# Probably need to mount .aws creds if running from local development environment
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker -v "${HOME}/.aws:/root/.aws" --env HOST_TEMPDIR="${HOST_TEMPDIR}" -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:044618531875:activity:basic-activity



If running on ec2 directly, (via docker) docker containers should have network access to the ec2 metadata server and can use the credentials on the machine


# create and mount to log4perl config from the machine
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker --mount type=bind,source="$(pwd)/log4perl.cfg",target=/log4perl.cfg --env HOST_TEMPDIR="${HOST_TEMPDIR}" --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=TopsailLogGroup -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:044618531875:activity:basic-activity

# Sending logs to aws cloudwatch from ec2
export HOST_TEMPDIR="${HOME}/tmp"
echo $HOST_TEMPDIR
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker --env HOST_TEMPDIR="${HOST_TEMPDIR}" --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=TopsailLogGroup -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:044618531875:activity:basic-activity

# preserve logs? # flush all logs? # preserve failed containers? # clean-up old containers when space is limited?
run in detached mode and get the container id. poll for container run completion and report back to server


# v2
# make sure running as root?
# do i need to make sure HOST_TEMPDIR exists?'# which also implies that whatever user the script runs as if it uses docker must also have access
# i.e. we should make? tell? the user to just use root user?
# what usecase for not using root user?
# HOST_TEMPDIR is the contract to the process_activity function for where the script has access to the host dir for file storage. no guarentees on scope
# How to pass aws credentials to the scripts?
if not root
sudo su root
export HOST_TEMPDIR="/tmp"
echo $HOST_TEMPDIR
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker --env HOST_TEMPDIR="${HOST_TEMPDIR}" -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:927027609069:activity:basic-activity

docker pull -q "$image" >/dev/null || true
exec docker run --init -v "$TMPDIR:$TMPDIR" -i "$image" "$@"

Install any missing modules when that fails


perl -d Workflow.pm --deployment-spec-json="$(jq '.deployment_spec' /tmp/big.json | jq -s '.[0]')" --context deploy

# tooling

* specification
* validation

# services

* executor, runs a series of steps
* * Define step states i.e. https://docs.aws.amazon.com/step-functions/latest/dg/concepts-states.html

* sync, waits for one or more other processors to meet
* approval, waits for 'approval' and continue