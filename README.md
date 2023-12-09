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

# make sure running as root?
# do i need to make sure HOST_TEMPDIR exists?
# HOST_TEMPDIR is the contract to the process_activity function for where the script has access to the host dir for file storage. no guarentees on scope
HOST_TEMPDIR="${HOME}/tmp"
echo $HOST_TEMPDIR
docker run --init -v "${HOST_TEMPDIR}:${HOST_TEMPDIR}" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker:/etc/docker --env HOST_TEMPDIR="${HOST_TEMPDIR}" -i rttomlinson/topsail process_activity --activity-arn arn:aws:states:us-east-1:798750129590:activity:basic-activity

docker pull -q "$image" >/dev/null || true
exec docker run --init -v "$TMPDIR:$TMPDIR" -i "$image" "$@"

Install any missing modules when that fails