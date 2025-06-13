#!/bin/bash

echo "=== Cross-Graph Query Demonstrations ==="
echo "This shows the power of named graphs: querying schema + data together"
echo

# Wait for server
sleep 2

echo "1. Query instances with their class definitions:"
echo "   (Shows data from both graphs in a single query)"
echo
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?person ?name ?class ?classLabel
WHERE {
  GRAPH <http://example.org/data> {
    ?person a ?class ;
            :hasName ?name .
  }
  GRAPH <http://example.org/ontology> {
    ?class rdfs:label ?classLabel .
  }
  FILTER(?class = :Person)
}' | jq '.'

echo
echo "2. Count instances per class type:"
echo
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?classLabel (COUNT(?instance) as ?count)
WHERE {
  GRAPH <http://example.org/data> {
    ?instance a ?class .
  }
  GRAPH <http://example.org/ontology> {
    ?class rdfs:label ?classLabel .
  }
}
GROUP BY ?classLabel' | jq '.'

echo
echo "3. Show property usage with domain/range info:"
echo
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'PREFIX : <http://example.org/ontology#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?propertyLabel ?subject ?object ?domainLabel ?rangeLabel
WHERE {
  GRAPH <http://example.org/data> {
    ?subject :worksFor ?object .
  }
  GRAPH <http://example.org/ontology> {
    :worksFor rdfs:label ?propertyLabel ;
              rdfs:domain ?domain ;
              rdfs:range ?range .
    ?domain rdfs:label ?domainLabel .
    ?range rdfs:label ?rangeLabel .
  }
}' | jq '.'

echo
echo "4. List all named graphs in the dataset:"
echo
curl -X POST 'http://localhost:3030/knowledge-base/sparql' \
  -H 'Content-Type: application/sparql-query' \
  -H 'Accept: application/json' \
  -d 'SELECT DISTINCT ?graph
WHERE {
  GRAPH ?graph { ?s ?p ?o }
}' | jq '.'

echo
echo "=== These queries demonstrate why named graphs are superior ==="
echo "- Single endpoint for unified queries across schema and data"
echo "- Logical separation without operational complexity"
echo "- Standard SPARQL graph operations"
echo "- Perfect for reasoning engines that expect TBox + ABox together"