CLOUD_SPEC_JSON=$(jq -Rsa . example/cloud_spec.json)
curl -XPOST "http://localhost:8888/2015-03-31/functions/function/invocations" -d "{\"contexts\": [\"prestaging\", \"standby\"], \"step_name\": \"validate_cloud_spec\", \"cloud_spec_json\": $CLOUD_SPEC_JSON}"
