#!/bin/bash

# Load instance data from TTL file into named graph
echo "Loading instance data from fuseki/ontologies/data.ttl..."

# Check if data file exists
if [ ! -f "fuseki/ontologies/data.ttl" ]; then
    echo "Error: fuseki/ontologies/data.ttl not found!"
    exit 1
fi

# Load data from TTL file directly into named graph
echo "Uploading data.ttl to <http://example.org/data> graph..."
curl -X POST 'http://localhost:3030/knowledge-base/data?graph=http://example.org/data' \
  -u admin:admin \
  -H 'Content-Type: text/turtle' \
  --data-binary @fuseki/ontologies/data.ttl

if [ $? -eq 0 ]; then
    echo -e "\n✅ Instance data loaded successfully from TTL file!"
else
    echo -e "\n❌ Failed to load instance data!"
    exit 1
fi