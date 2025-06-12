# Fuseki Docker Setup for Ontology & Knowledge Graph Publishing

This setup provides Apache Jena Fuseki server running in Docker for publishing and querying ontologies and knowledge graphs.

## Quick Start

1. Start Fuseki server:
```bash
docker-compose up -d
```

2. Access Fuseki UI:
   - URL: http://localhost:3030
   - Username: admin
   - Password: admin

3. Your dataset endpoint: http://localhost:3030/knowledge-graph

## Loading Data

### Option 1: Using Fuseki UI
1. Go to http://localhost:3030
2. Select "knowledge-graph" dataset
3. Click "upload files" tab
4. Upload your ontology file (e.g., `fuseki/ontologies/example-ontology.ttl`)

### Option 2: Using SPARQL Update
```bash
curl -X POST http://localhost:3030/knowledge-graph/data \
  -H "Content-Type: text/turtle" \
  --data-binary @fuseki/ontologies/example-ontology.ttl
```

### Option 3: Using Docker exec
```bash
docker exec -it fuseki-server /bin/bash
cd /fuseki/ontologies
/jena-fuseki/bin/tdb2.tdbloader --loc=/fuseki/databases/knowledge-graph example-ontology.ttl
```

## Querying Your Knowledge Graph

You now have **two separate SPARQL endpoints**:
- **Knowledge Graph**: `http://localhost:3030/knowledge-graph/sparql` (for your data instances)
- **Ontology**: `http://localhost:3030/ontology/sparql` (for your schema/ontology)

### Programmatic SPARQL Queries

#### Method 1: POST with SPARQL query in body (Recommended)
```bash
curl -X POST 'http://localhost:3030/knowledge-graph/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'SELECT ?s ?p ?o WHERE { ?s ?p ?o } LIMIT 5'
```

#### Method 2: GET with query parameter
```bash
curl 'http://localhost:3030/knowledge-graph/sparql?query=SELECT%20*%20WHERE%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20LIMIT%205' \
  -H 'Accept: application/json'
```

#### Method 3: URL-encoded POST
```bash
curl -X POST 'http://localhost:3030/knowledge-graph/sparql' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json' \
  -d 'query=SELECT * WHERE { ?s ?p ?o } LIMIT 5'
```

### Example Queries

#### Query Knowledge Graph Data
```bash
# Get all persons from knowledge graph
curl -X POST 'http://localhost:3030/knowledge-graph/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
SELECT ?person ?name ?email
WHERE {
  ?person a :Person ;
          :hasName ?name ;
          :hasEmail ?email .
}'
```

#### Query Ontology Schema
```bash
# Get all classes from ontology
curl -X POST 'http://localhost:3030/ontology/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'SELECT ?class ?label
WHERE {
  ?class a <http://www.w3.org/2002/07/owl#Class> .
  OPTIONAL { ?class <http://www.w3.org/2000/01/rdf-schema#label> ?label }
}'
```

### Browser Access
- **Fuseki UI**: http://localhost:3030 (web interface for interactive queries)
- **Direct endpoint access**: Shows service description only

### Response Format
All queries return JSON by default:
```json
{
  "head": {
    "vars": ["s", "p", "o"]
  },
  "results": {
    "bindings": [
      {
        "s": {"type": "uri", "value": "http://example.org/ontology#Person"},
        "p": {"type": "uri", "value": "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"},
        "o": {"type": "uri", "value": "http://www.w3.org/2002/07/owl#Class"}
      }
    ]
  }
}
```

## Directory Structure
```
fuseki_test/
├── docker-compose.yml       # Docker Compose configuration
├── fuseki/
│   ├── config/
│   │   └── config.ttl      # Fuseki configuration
│   ├── data/               # Database storage (created automatically)
│   └── ontologies/         # Your ontology files
│       └── example-ontology.ttl
└── README.md
```

## Stopping Fuseki
```bash
docker-compose down
```

## Persisting Data
Data is persisted in `./fuseki/data` directory. To reset, stop the container and delete this directory.

## Configuration
- Memory allocation: Adjust `-Xmx2g` in docker-compose.yml
- Admin password: Change `ADMIN_PASSWORD` in docker-compose.yml
- Port: Change `3030:3030` mapping if needed