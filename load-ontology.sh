#!/bin/bash

# Load ontology schema using the file upload endpoint
echo "Loading ontology schema into Fuseki..."

# Wait for Fuseki to be ready
echo "Waiting for Fuseki to be ready..."
sleep 5

# Upload the ontology schema file
curl -X POST \
  http://localhost:3030/ontology/data \
  -H "Content-Type: text/turtle" \
  --data-binary @fuseki/ontologies/ontology-schema-only.ttl

echo -e "\nOntology schema loaded successfully!"