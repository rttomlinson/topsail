Run example

```
git clone https://github.com/rttomlinson/topsail.git
cd topsail/example
YAML_MANIFEST_SPEC_INPUT_FILENAME=service_manifest.yaml make step_service_manifest 
cd ..  
perl workflows.pl  
```

Install any missing modules when that fails