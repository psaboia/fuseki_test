#!/bin/bash

# Load ontology schema from TTL file into named graph
echo "Loading ontology schema from fuseki/ontologies/ontology.ttl..."

# Wait for Fuseki to be ready
echo "Waiting for Fuseki to be ready..."
sleep 5

# Check if ontology file exists
if [ ! -f "fuseki/ontologies/ontology.ttl" ]; then
    echo "Error: fuseki/ontologies/ontology.ttl not found!"
    exit 1
fi

# Load ontology from TTL file directly into named graph
echo "Uploading ontology.ttl to <http://example.org/ontology> graph..."
curl -X POST 'http://localhost:3030/knowledge-base/data?graph=http://example.org/ontology' \
  -u admin:admin \
  -H 'Content-Type: text/turtle' \
  --data-binary @fuseki/ontologies/ontology.ttl

if [ $? -eq 0 ]; then
    echo -e "\n✅ Ontology schema loaded successfully from TTL file!"
else
    echo -e "\n❌ Failed to load ontology schema!"
    exit 1
fi