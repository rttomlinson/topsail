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

Install any missing modules when that fails