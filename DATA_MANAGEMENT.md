# Data Management Guide

This guide explains how to manage your semantic data using the file-based source of truth approach implemented in this project.

## File Structure

```
fuseki_test/
├── fuseki/ontologies/           # SOURCE FILES (edit these)
│   ├── ontology.ttl            # Schema/classes/properties → <http://example.org/ontology>
│   └── data.ttl                # Instances/individuals → <http://example.org/data>
├── fuseki/data/knowledge-base/  # BINARY DATABASE (auto-generated, ~192MB)
├── fuseki/backups/             # EXPORT BACKUPS (timestamped folders)
└── *.sh                        # Management scripts
```

## Core Principles

1. **TTL files are the single source of truth** - Always edit these, never the database directly
2. **Database is disposable** - Can be recreated from TTL files anytime
3. **Changes require reload** - Edit TTL → run reset script → test
4. **Export for backup** - Regular backups before major changes

## Development Workflow

### 1. Edit Source Data

**Edit Schema (Classes, Properties, Domains, Ranges):**
```bash
vim fuseki/ontologies/ontology.ttl
```

**Edit Instances (People, Organizations, Projects):**
```bash
vim fuseki/ontologies/data.ttl
```

### 2. Load Changes into Database

**Option A: Reset Everything (Recommended)**
```bash
./reset-database.sh
```
- Clears both named graphs
- Reloads from TTL files
- Ensures clean state

**Option B: Load Individually**
```bash
./load-ontology.sh  # Load just schema
./load-data.sh      # Load just data
```

### 3. Test & Validate

**Run Cross-Graph Demo:**
```bash
./demo-cross-graph-queries.sh
```

**Query Specific Graph:**
```bash
# Query data only
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -d 'SELECT ?s ?p ?o WHERE { GRAPH <http://example.org/data> { ?s ?p ?o } }'

# Query schema only  
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -d 'SELECT ?s ?p ?o WHERE { GRAPH <http://example.org/ontology> { ?s ?p ?o } }'
```

### 4. Backup & Version Control

**Export Database:**
```bash
./export-data.sh
```
- Creates timestamped backup folder
- Exports both graphs as TTL
- Exports complete dataset as N-Quads

**Commit to Git:**
```bash
git add fuseki/ontologies/*.ttl
git commit -m "Update ontology schema"
git push
```

## Data Flow

```
TTL Files (Source) → Binary DB (Runtime) → SPARQL Queries (Fast Access)
                                        ↘
ontology.ttl       → TDB2 files        → Cross-graph queries
data.ttl           → (optimized)       → Web UI queries
                                        ↗
                   ← export-data.sh     ← Backup files
```

## Common Scenarios

### Adding New Person
1. Edit `fuseki/ontologies/data.ttl`:
   ```turtle
   :new_person rdf:type :Person ;
     :hasName "New Person" ;
     :hasEmail "new@example.com" .
   ```
2. Run `./reset-database.sh`
3. Test with demo queries

### Adding New Property
1. Edit `fuseki/ontologies/ontology.ttl`:
   ```turtle
   :hasPhoneNumber a owl:DatatypeProperty ;
     rdfs:label "has phone number"@en ;
     rdfs:domain :Person ;
     rdfs:range xsd:string .
   ```
2. Edit `fuseki/ontologies/data.ttl` to use new property
3. Run `./reset-database.sh`
4. Validate with queries

### Backup Before Major Changes
1. Run `./export-data.sh`
2. Note backup directory (e.g., `fuseki/backups/20250613_090630/`)
3. Make changes
4. If issues occur, restore from backup:
   ```bash
   cp fuseki/backups/20250613_090630/ontology.ttl fuseki/ontologies/
   cp fuseki/backups/20250613_090630/data.ttl fuseki/ontologies/
   ./reset-database.sh
   ```

### Starting Fresh
```bash
# Clear everything
docker-compose down
rm -rf fuseki/data/*

# Start clean
docker-compose up -d
./reset-database.sh
```

## Script Reference

| Script | Purpose | Input | Output |
|--------|---------|-------|--------|
| `load-ontology.sh` | Load schema | `ontology.ttl` | Updates `<http://example.org/ontology>` |
| `load-data.sh` | Load instances | `data.ttl` | Updates `<http://example.org/data>` |
| `reset-database.sh` | Full reload | Both TTL files | Clean database state |
| `export-data.sh` | Backup | Database | Timestamped backup folder |
| `demo-cross-graph-queries.sh` | Test | Database | Cross-graph query results |

## File Formats

- **TTL (Turtle)**: Human-readable, version control friendly
- **TDB2**: Binary, optimized for SPARQL queries
- **N-Quads**: Complete export format with named graph context

## Testing Workflow

### Comprehensive System Testing

Run the full test suite to validate all system components:

```bash
./test-system.sh
```

**What it tests:**
- ✅ Infrastructure (Docker, web interface, SPARQL endpoint)
- ✅ File system (TTL files, database, scripts)
- ✅ Database content (named graphs, classes, instances)
- ✅ Cross-graph queries (schema + data integration)
- ✅ Data management (export/import functionality)
- ✅ Performance (response time, database size)

### Testing Scenarios

**After making changes:**
```bash
./reset-database.sh  # Reload your changes
./test-system.sh     # Verify everything works
```

**Daily development:**
```bash
./test-system.sh     # Quick health check
```

**Before deployment:**
```bash
./export-data.sh     # Backup current state
./test-system.sh     # Full validation
```

**Troubleshooting:**
```bash
./test-system.sh     # Identify failing components
docker logs fuseki-server  # Check server logs if needed
```

### Test Results Interpretation

**All tests pass (15/15):**
- System is healthy and ready for use
- Performance is within expected ranges
- All functionality working correctly

**Some tests fail:**
- Check specific error messages in output
- Common fixes provided in test summary
- Verify Docker is running and data is loaded

**Performance warnings:**
- Query response time >1000ms: Check system resources
- Database size unexpectedly large: Review data volume

## Best Practices

1. **Always validate TTL syntax** before loading
2. **Use meaningful URIs** in your data
3. **Regular backups** before schema changes
4. **Version control TTL files** but not binary database
5. **Test cross-graph queries** after changes
6. **Document property domains/ranges** in ontology comments
7. **Run test suite** after making changes
8. **Monitor performance** with regular testing

## Troubleshooting

**Loading fails:**
- Check TTL syntax with online validator
- Verify file paths are correct
- Check Fuseki authentication (admin/admin)

**Data appears missing:**
- Verify correct named graph in queries
- Check if reset-database.sh completed successfully
- Use export-data.sh to inspect current database content

**Performance issues:**
- Binary database should handle queries efficiently
- For large datasets, consider TDB2 optimization settings
- Monitor fuseki/data/ directory size