# Fuseki Docker Setup with Named Graphs

Apache Jena Fuseki server running in Docker using **named graphs** for semantic web data management. Features single endpoint with logical separation between ontology schema and instance data.

## Key Features

- **Single endpoint**: `http://localhost:3030/knowledge-base/sparql`
- **Named graphs**: Separate schema (`<http://example.org/ontology>`) and data (`<http://example.org/data>`)
- **Cross-graph queries**: Query schema and data together in single SPARQL query
- **File-based source of truth**: TTL files sync with binary database
- **Export/import capabilities**: Backup and restore functionality

## Quick Start

1. Start Fuseki server:
```bash
docker-compose up -d
```

2. Load ontology schema into named graph:
```bash
./load-ontology.sh
```

3. Load instance data into named graph:
```bash
./load-data.sh
```

4. Access Fuseki UI:
   - URL: http://localhost:3030
   - Username: admin
   - Password: admin

5. Run cross-graph query demonstrations:
```bash
./demo-cross-graph-queries.sh
```

## Cross-Graph Query Demonstrations

The `demo-cross-graph-queries.sh` script showcases the **key advantage of named graphs**: the ability to query across both schema and data in a single SPARQL query. This demonstrates capabilities that would be impossible with separate dual endpoints.

### What the Demo Shows:

1. **Instances with Class Definitions**: Query people from the data graph and get their class labels from the ontology graph
2. **Instance Counts by Type**: Count how many instances exist for each class type using schema information
3. **Property Domain/Range Validation**: Show property usage with full domain/range information from the schema
4. **Named Graph Listing**: Display all available named graphs in the dataset

### Example Cross-Graph Query:
```sparql
PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?person ?name ?classLabel WHERE {
  GRAPH <http://example.org/data> {
    ?person a :Person ; :hasName ?name
  }
  GRAPH <http://example.org/ontology> {
    :Person rdfs:label ?classLabel
  }
}
```

This query retrieves person instances from the data graph while simultaneously fetching class labels from the ontology graph - impossible with dual endpoints but trivial with named graphs!

## Data Management

For detailed workflows on editing data, loading changes, backups, and best practices, see [DATA_MANAGEMENT.md](DATA_MANAGEMENT.md).

**Quick commands:**
- Edit: `vim fuseki/ontologies/ontology.ttl` or `vim fuseki/ontologies/data.ttl`  
- Reload: `./reset-database.sh`
- Test: `./test-system.sh`
- Backup: `./export-data.sh`

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

## Querying with Named Graphs

**Single SPARQL endpoint**: `http://localhost:3030/knowledge-base/sparql`

The power of named graphs is that you can query across both schema and data, or target specific graphs.

### Cross-Graph Queries (The Key Advantage!)

#### Query instances with their class definitions:
```bash
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?person ?name ?classLabel
WHERE {
  GRAPH <http://example.org/data> {
    ?person a :Person ;
            :hasName ?name .
  }
  GRAPH <http://example.org/ontology> {
    :Person rdfs:label ?classLabel .
  }
}'
```

### Graph-Specific Queries

#### Query only data instances:
```bash
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>

SELECT ?person ?name ?email
WHERE {
  GRAPH <http://example.org/data> {
    ?person a :Person ;
            :hasName ?name ;
            :hasEmail ?email .
  }
}'
```

#### Query only schema definitions:
```bash
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?class ?label
WHERE {
  GRAPH <http://example.org/ontology> {
    ?class a owl:Class ;
           rdfs:label ?label .
  }
}'
```

### Alternative Query Methods

#### Method 1: POST with SPARQL query in body (Recommended)
#### Method 2: GET with query parameter  
#### Method 3: URL-encoded POST

All methods work the same, just replace the endpoint with `/knowledge-base/sparql`

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

## Project Structure
```
fuseki_test/
├── docker-compose.yml          # Docker Compose configuration
├── fuseki/
│   ├── config/config.ttl       # Fuseki single-endpoint configuration
│   ├── data/knowledge-base/    # Binary TDB2 database (auto-generated)
│   ├── ontologies/             # Source TTL files (edit these)
│   │   ├── ontology.ttl        # Schema/classes/properties
│   │   └── data.ttl            # Instances/individuals
│   └── backups/                # Timestamped exports
├── *.sh                        # Data management scripts
└── DATA_MANAGEMENT.md          # Detailed workflow guide
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