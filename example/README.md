CLOUD_SPEC_JSON=$(jq -Rsa . example/cloud_spec.json)
curl -XPOST "http://localhost:8888/2015-03-31/functions/function/invocations" -d "{\"contexts\": [\"prestaging\", \"standby\"], \"step_name\": \"validate_cloud_spec\", \"cloud_spec_json\": $CLOUD_SPEC_JSON}"


https://hello-john-boy.auth.us-east-1.amazoncognito.com/login?response_type=code&client_id=3m2r35loo2rmks954cmaedmp1u&redirect_uri=http://localhost/callback
