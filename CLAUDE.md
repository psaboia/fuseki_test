# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based Apache Jena Fuseki triple store setup using **named graphs** following semantic web best practices. The architecture uses a single endpoint with logical separation of ontology schema and instance data via named graphs.

## Key Architecture Components

### Named Graph System (Semantic Web Best Practice)
- **Single endpoint**: `/knowledge-base/sparql` - unified access to all data
- **Ontology Graph**: `<http://example.org/ontology>` - TBox (schema/classes/properties)
- **Data Graph**: `<http://example.org/data>` - ABox (instances/individuals)
- Single TDB2 database at `/fuseki/databases/knowledge-base` containing both graphs

### Configuration Structure
- `fuseki/config/config.ttl` defines single service called "knowledge-base"
- Docker-compose mounts this config directly to `/fuseki/config.ttl` in container
- Simplified configuration avoids complexity of dual endpoints

### Data Loading Pattern
- `load-ontology.sh` uses SPARQL UPDATE to insert schema into `<http://example.org/ontology>` graph
- `load-data.sh` uses SPARQL UPDATE to insert instances into `<http://example.org/data>` graph
- Both scripts target same endpoint but different named graphs
- `demo-cross-graph-queries.sh` demonstrates cross-graph querying capabilities

## Common Commands

### Server Management
```bash
# Start Fuseki server
docker-compose up -d

# Stop server
docker-compose down

# View logs
docker logs fuseki-server

# Check server status
curl -s -o /dev/null -w "%{http_code}" http://localhost:3030/
```

### Data Operations
```bash
# Load ontology schema into named graph
./load-ontology.sh

# Load instance data into named graph
./load-data.sh

# Demonstrate cross-graph queries
./demo-cross-graph-queries.sh

# Query specific named graph (data only)
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'SELECT ?s ?p ?o WHERE { GRAPH <http://example.org/data> { ?s ?p ?o } } LIMIT 5'

# Query specific named graph (ontology only)
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'SELECT ?s ?p ?o WHERE { GRAPH <http://example.org/ontology> { ?s ?p ?o } } LIMIT 5'

# Cross-graph query (data + schema together)
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?person ?name ?classLabel WHERE {
  GRAPH <http://example.org/data> { ?person a :Person ; :hasName ?name }
  GRAPH <http://example.org/ontology> { :Person rdfs:label ?classLabel }
}'
```

### Development & Testing
```bash
# Run comprehensive system tests
./test-system.sh

# Count triples in each named graph
curl -s "http://localhost:3030/knowledge-base/sparql?query=SELECT%20(COUNT(*)%20as%20%3Fcount)%20WHERE%20%7B%20GRAPH%20%3Chttp://example.org/data%3E%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20%7D" -H "Accept: application/json"
curl -s "http://localhost:3030/knowledge-base/sparql?query=SELECT%20(COUNT(*)%20as%20%3Fcount)%20WHERE%20%7B%20GRAPH%20%3Chttp://example.org/ontology%3E%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20%7D" -H "Accept: application/json"

# List all named graphs
curl -s "http://localhost:3030/knowledge-base/sparql?query=SELECT%20DISTINCT%20%3Fgraph%20WHERE%20%7B%20GRAPH%20%3Fgraph%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20%7D" -H "Accept: application/json"

# Reset data (cleans and reloads from TTL files)
./reset-database.sh
```

## Important Notes

- Web UI available at http://localhost:3030 with admin/admin credentials
- Data persists in `./fuseki/data` directory across container restarts
- Docker image platform warning (linux/amd64 vs arm64) is harmless
- Direct SPARQL endpoint access in browser shows service description only
- Single endpoint with named graphs follows semantic web best practices
- Cross-graph queries enable powerful data integration patterns
- Compatible with OWL reasoners that expect TBox + ABox together
- Simpler configuration and operational overhead than dual endpoints