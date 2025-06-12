#!/bin/bash

# Load data using SPARQL Update
curl -X POST 'http://localhost:3030/knowledge-graph/update' \
  -H 'Content-Type: application/sparql-update' \
  --data-binary @- << 'EOF'
PREFIX : <http://example.org/ontology#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

INSERT DATA {
  # Example Individuals
  :john_doe rdf:type :Person ;
    :hasName "John Doe" ;
    :hasEmail "john.doe@example.com" ;
    :worksFor :acme_corp ;
    :manages :project_alpha .

  :jane_smith rdf:type :Person ;
    :hasName "Jane Smith" ;
    :hasEmail "jane.smith@example.com" ;
    :worksFor :tech_innovations ;
    :manages :project_beta .

  :acme_corp rdf:type :Organization ;
    rdfs:label "ACME Corporation" .

  :tech_innovations rdf:type :Organization ;
    rdfs:label "Tech Innovations Inc." .

  :project_alpha rdf:type :Project ;
    rdfs:label "Project Alpha" ;
    :hasStartDate "2024-01-15"^^xsd:date ;
    :hasBudget "250000.00"^^xsd:decimal ;
    :fundedBy :acme_corp .

  :project_beta rdf:type :Project ;
    rdfs:label "Project Beta" ;
    :hasStartDate "2024-03-01"^^xsd:date ;
    :hasBudget "500000.00"^^xsd:decimal ;
    :fundedBy :tech_innovations .
}
EOF