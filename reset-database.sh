#!/bin/bash

# Reset database and reload from TTL files
echo "=== Resetting Fuseki Database ==="

# Clear specific named graphs
echo "Clearing named graphs..."
curl -X POST 'http://localhost:3030/knowledge-base/update' \
  -u admin:admin \
  -H 'Content-Type: application/sparql-update' \
  -d 'CLEAR GRAPH <http://example.org/ontology>'

curl -X POST 'http://localhost:3030/knowledge-base/update' \
  -u admin:admin \
  -H 'Content-Type: application/sparql-update' \
  -d 'CLEAR GRAPH <http://example.org/data>'

echo "✅ Named graphs cleared"

# Reload from TTL files
echo
echo "Reloading from TTL files..."
./load-ontology.sh
./load-data.sh

echo
echo "=== Database Reset Complete ==="
echo "Data source: TTL files in fuseki/ontologies/"
echo "Database location: fuseki/data/knowledge-base/"