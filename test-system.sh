#!/bin/bash

# Comprehensive system testing script for Fuseki named graphs setup
echo "🧪 Testing Fuseki Named Graphs System"
echo "====================================="

FAILED_TESTS=0
TOTAL_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    echo -n "Testing: $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    result=$(eval "$test_command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected pattern: $expected_pattern"
        echo "   Got: $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Test JSON response
test_json_response() {
    local test_name="$1"
    local query="$2"
    local expected_count="$3"
    
    echo -n "Testing: $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    result=$(curl -s -X POST 'http://localhost:3030/knowledge-base/sparql' \
        -H 'Content-Type: application/sparql-query' \
        -H 'Accept: application/json' \
        -d "$query")
    
    if command -v jq >/dev/null 2>&1; then
        count=$(echo "$result" | jq '.results.bindings | length' 2>/dev/null)
        if [ "$count" = "$expected_count" ]; then
            echo -e "${GREEN}✅ PASS${NC} ($count results)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (expected $expected_count, got $count)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        # Fallback without jq
        if [[ "$result" =~ "bindings" ]] && [[ "$result" =~ "uri" ]]; then
            echo -e "${GREEN}✅ PASS${NC} (JSON response valid)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (Invalid JSON response)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    fi
}

echo
echo "🔧 Infrastructure Tests"
echo "----------------------"

# Test 1: Docker container running
run_test "Docker container running" \
    "docker ps | grep fuseki-server" \
    "fuseki-server"

# Test 2: Fuseki web interface accessible
run_test "Fuseki web interface accessible" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:3030/" \
    "200"

# Test 3: SPARQL endpoint accessible
run_test "SPARQL endpoint accessible" \
    "curl -s http://localhost:3030/knowledge-base/sparql" \
    "Service Description"

echo
echo "📁 File System Tests"
echo "--------------------"

# Test 4: Source TTL files exist
run_test "Ontology TTL file exists" \
    "test -f fuseki/ontologies/ontology.ttl && echo 'exists'" \
    "exists"

run_test "Data TTL file exists" \
    "test -f fuseki/ontologies/data.ttl && echo 'exists'" \
    "exists"

# Test 5: Database directory exists
run_test "Database directory exists" \
    "test -d fuseki/data/knowledge-base && echo 'exists'" \
    "exists"

# Test 6: Scripts are executable
run_test "Load scripts executable" \
    "test -x load-ontology.sh && test -x load-data.sh && echo 'executable'" \
    "executable"

echo
echo "🗄️ Database Content Tests"
echo "-------------------------"

# Test 7: Named graphs exist
test_json_response "Named graphs exist" \
    "SELECT DISTINCT ?graph WHERE { GRAPH ?graph { ?s ?p ?o } }" \
    "2"

# Test 8: Ontology graph has content
test_json_response "Ontology graph has classes" \
    "SELECT ?class WHERE { GRAPH <http://example.org/ontology> { ?class a <http://www.w3.org/2002/07/owl#Class> } }" \
    "3"

# Test 9: Data graph has content
test_json_response "Data graph has persons" \
    "PREFIX : <http://example.org/ontology#> SELECT ?person WHERE { GRAPH <http://example.org/data> { ?person a :Person } }" \
    "2"

echo
echo "🔗 Cross-Graph Query Tests"
echo "--------------------------"

# Test 10: Cross-graph query works
test_json_response "Cross-graph person-class query" \
    "PREFIX : <http://example.org/ontology#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?person ?classLabel WHERE { GRAPH <http://example.org/data> { ?person a :Person } GRAPH <http://example.org/ontology> { :Person rdfs:label ?classLabel } }" \
    "2"

# Test 11: Property domain/range validation
test_json_response "Property domain/range query" \
    "PREFIX : <http://example.org/ontology#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?prop ?domain ?range WHERE { GRAPH <http://example.org/ontology> { ?prop rdfs:domain ?domain ; rdfs:range ?range } } LIMIT 3" \
    "3"

echo
echo "🔄 Data Management Tests"
echo "------------------------"

# Test 12: Export functionality
echo -n "Testing: Export functionality... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
./export-data.sh > /dev/null 2>&1
if [ $? -eq 0 ]; then
    latest_backup=$(ls -t fuseki/backups/ | head -1)
    if [ -f "fuseki/backups/$latest_backup/ontology.ttl" ] && [ -f "fuseki/backups/$latest_backup/data.ttl" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC} (Backup files not created)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo -e "${RED}❌ FAIL${NC} (Export script failed)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 13: TTL syntax validation (if available)
if command -v rapper >/dev/null 2>&1; then
    run_test "Ontology TTL syntax valid" \
        "rapper -q -c fuseki/ontologies/ontology.ttl && echo 'valid'" \
        "valid"
    
    run_test "Data TTL syntax valid" \
        "rapper -q -c fuseki/ontologies/data.ttl && echo 'valid'" \
        "valid"
else
    echo "⚠️  Skipping TTL syntax validation (rapper not installed)"
    echo "   Install with: sudo apt-get install raptor2-utils"
fi

echo
echo "📊 Performance Tests"
echo "-------------------"

# Test 14: Query response time
echo -n "Testing: Query response time... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
start_time=$(date +%s%N)
curl -s -X POST 'http://localhost:3030/knowledge-base/sparql' \
    -H 'Content-Type: application/sparql-query' \
    -H 'Accept: application/json' \
    -d 'SELECT ?s ?p ?o WHERE { ?s ?p ?o } LIMIT 10' > /dev/null
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

if [ $duration -lt 1000 ]; then
    echo -e "${GREEN}✅ PASS${NC} (${duration}ms)"
else
    echo -e "${YELLOW}⚠️ SLOW${NC} (${duration}ms - expected <1000ms)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 15: Database size check
echo -n "Testing: Database size reasonable... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
db_size=$(du -sm fuseki/data/knowledge-base/ | cut -f1)
if [ $db_size -lt 500 ]; then
    echo -e "${GREEN}✅ PASS${NC} (${db_size}MB)"
else
    echo -e "${YELLOW}⚠️ LARGE${NC} (${db_size}MB - investigate if unexpected)"
fi

echo
echo "🎯 Test Summary"
echo "==============="
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! System is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}💥 $FAILED_TESTS test(s) failed. Check the output above.${NC}"
    echo
    echo "Common fixes:"
    echo "- Ensure Docker is running: docker-compose up -d"
    echo "- Load data: ./reset-database.sh"
    echo "- Check logs: docker logs fuseki-server"
    exit 1
fi