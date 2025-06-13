#!/bin/bash

# Export data from named graphs back to TTL files (backup/version control)
echo "Exporting data from Fuseki named graphs to TTL files..."

# Create backup directory with timestamp
BACKUP_DIR="fuseki/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backup directory: $BACKUP_DIR"

# Export ontology graph using SPARQL CONSTRUCT
echo "Exporting <http://example.org/ontology> graph..."
curl -s -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: text/turtle' \
  -d 'CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <http://example.org/ontology> { ?s ?p ?o } }' > "$BACKUP_DIR/ontology.ttl"

if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/ontology.ttl" ]; then
    echo "✅ Ontology exported to $BACKUP_DIR/ontology.ttl"
else
    echo "❌ Failed to export ontology"
fi

# Export data graph using SPARQL CONSTRUCT
echo "Exporting <http://example.org/data> graph..."
curl -s -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: text/turtle' \
  -d 'CONSTRUCT { ?s ?p ?o } WHERE { GRAPH <http://example.org/data> { ?s ?p ?o } }' > "$BACKUP_DIR/data.ttl"

if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/data.ttl" ]; then
    echo "✅ Data exported to $BACKUP_DIR/data.ttl"
else
    echo "❌ Failed to export data"
fi

# Export all graphs (complete backup) using SPARQL CONSTRUCT
echo "Exporting complete dataset..."
curl -s -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/n-quads' \
  -d 'CONSTRUCT { ?s ?p ?o } WHERE { GRAPH ?g { ?s ?p ?o } }' > "$BACKUP_DIR/complete.nq"

if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/complete.nq" ]; then
    echo "✅ Complete dataset exported to $BACKUP_DIR/complete.nq"
else
    echo "❌ Failed to export complete dataset"
fi

# Show summary
echo
echo "=== Export Summary ==="
echo "Backup directory: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
echo
echo "To restore from backup:"
echo "  ./load-ontology.sh (loads from fuseki/ontologies/ontology.ttl)"
echo "  ./load-data.sh (loads from fuseki/ontologies/data.ttl)"
echo
echo "To update source files with exported data:"
echo "  cp $BACKUP_DIR/ontology.ttl fuseki/ontologies/"
echo "  cp $BACKUP_DIR/data.ttl fuseki/ontologies/"