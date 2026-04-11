# Fuseki Setup - Reproducible Guide

This guide documents the process for setting up a Fuseki instance with RDF data and maintaining data quality through iterative extension.

## Prerequisites
- Docker installed and running
- Empty working directory

## Quick Start

```bash
docker pull secoresearch/fuseki
docker run -d -p 3030:3030 --name fuseki secoresearch/fuseki
sleep 2
export FUSEKI_PASSWORD=$(docker logs fuseki 2>&1 | grep "admin=" | cut -d= -f2)
```

Use `$FUSEKI_PASSWORD` in subsequent curl commands.

---

## Phase 1: Initial Setup

### Create Core Data File

Create `simpsons.ttl` with core family members. This establishes the base schema and relationships:

```turtle
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix family: <http://example.org/family#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://example.org/person/homer> a foaf:Person ;
    foaf:name "Homer Simpson" ;
    foaf:age 45 ;
    foaf:jobTitle "Safety Inspector" ;
    family:spouse <http://example.org/person/marge> ;
    family:parentOf <http://example.org/person/bart>, <http://example.org/person/lisa>, <http://example.org/person/maggie> .

<http://example.org/person/marge> a foaf:Person ;
    foaf:name "Marge Simpson" ;
    foaf:age 43 ;
    foaf:jobTitle "Homemaker" ;
    family:spouse <http://example.org/person/homer> ;
    family:parentOf <http://example.org/person/bart>, <http://example.org/person/lisa>, <http://example.org/person/maggie> .

<http://example.org/person/bart> a foaf:Person ;
    foaf:name "Bart Simpson" ;
    foaf:age 10 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/homer>, <http://example.org/person/marge> ;
    family:sibling <http://example.org/person/lisa>, <http://example.org/person/maggie> .

<http://example.org/person/lisa> a foaf:Person ;
    foaf:name "Lisa Simpson" ;
    foaf:age 8 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/homer>, <http://example.org/person/marge> ;
    family:sibling <http://example.org/person/bart>, <http://example.org/person/maggie> .

<http://example.org/person/maggie> a foaf:Person ;
    foaf:name "Maggie Simpson" ;
    foaf:age 1 ;
    foaf:jobTitle "Baby" ;
    family:parent <http://example.org/person/homer>, <http://example.org/person/marge> ;
    family:sibling <http://example.org/person/bart>, <http://example.org/person/lisa> .
```

### Create Dataset

```bash
curl -s -u admin:$FUSEKI_PASSWORD -X POST "http://localhost:3030/$/datasets?dbType=tdb2&dbName=ds-rw"
```

### Upload and Verify

```bash
curl -s -u admin:$FUSEKI_PASSWORD -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@simpsons.ttl"
```

Expected: `{"count": 40, "tripleCount": 40, "quadCount": 0}`

---

## Phase 2: Extension Pattern

### Goal

Extend the graph with additional data while maintaining data quality invariants.

### Invariants

After each extension, verify these relationship properties:

| Relationship | Property | Query |
|--------------|----------|-------|
| `parent` / `parentOf` | Reciprocal | If A `parentOf` B, then B `parent` A |
| `spouse` | Reciprocal | If A `spouse` B, then B `spouse` A |
| `sibling` | Reciprocal | If A `sibling` B, then B `sibling` A |
| `neighborOf` | Reciprocal | If A `neighborOf` B, then B `neighborOf` A |

### Audit Queries

```bash
# Parent/parentOf reciprocity
curl -s -u admin:$FUSEKI_PASSWORD "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?a ?b WHERE { ?a family:parentOf ?b . FILTER NOT EXISTS { ?b family:parent ?a } }'

# Spouse reciprocity
curl -s -u admin:$FUSEKI_PASSWORD "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?a ?b WHERE { ?a family:spouse ?b . FILTER NOT EXISTS { ?b family:spouse ?a } }'

# Sibling reciprocity
curl -s -u admin:$FUSEKI_PASSWORD "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?a ?b WHERE { ?a family:sibling ?b . FILTER NOT EXISTS { ?b family:sibling ?a } }'

# NeighborOf reciprocity
curl -s -u admin:$FUSEKI_PASSWORD "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?a ?b WHERE { ?a family:neighborOf ?b . FILTER NOT EXISTS { ?b family:neighborOf ?a } }'
```

### Process

1. **Create** a TTL file with new entities and relationships
2. **Upload** via `curl -X POST .../ds-rw/data --form "file=@file.ttl"`
3. **Audit** using the queries above
4. **Correct** any violations by creating a corrections TTL file
5. **Verify** all audit queries return empty results

---

## Phase 3: Apply Extended Dataset

### Upload Extended Data

Create an `extended-family.ttl` file with additional characters (e.g., grandparents, in-laws, neighbors, friends) following the same schema. Then upload:

```bash
curl -s -u admin:$FUSEKI_PASSWORD -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@extended-family.ttl"
```

### Audit

Run the audit queries from Phase 2. You will likely find violations:

- Parent/parentOf: Some parent relationships may be missing reciprocals
- Spouse: Some spouse relationships may be one-directional
- Sibling: Some sibling relationships may be incomplete
- NeighborOf: Neighbor relationships may be missing reciprocals

### Apply Corrections

Create a `corrections.ttl` file that adds the missing reciprocal relationships. For example:

```turtle
@prefix family: <http://example.org/family#> .

# Add missing parent relationships
<http://example.org/person/child> family:parent <http://example.org/person/parent> .

# Add missing sibling relationships
<http://example.org/person/sibling1> family:sibling <http://example.org/person/sibling2> .

# Add missing neighborOf relationships
<http://example.org/person/neighbor1> family:neighborOf <http://example.org/person/neighbor2> .
```

Upload:

```bash
curl -s -u admin:$FUSEKI_PASSWORD -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@corrections.ttl"
```

### Verify

Re-run all audit queries. All should return empty results.

### Final State

```bash
curl -s -u admin:$FUSEKI_PASSWORD "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=SELECT (COUNT(*) as ?n) WHERE { ?s ?p ?o }'
```

Expected: ~150-200 triples (varies based on data)

**Success criteria:**
- ✅ All audit queries return empty results
- ✅ All relationship invariants are satisfied
- ✅ Graph is internally consistent

---

## Cleanup

```bash
docker stop fuseki && docker rm fuseki
rm -f *.ttl
```

---

## Notes

- The data files (`simpsons.ttl`, `extended-family.ttl`, `corrections.ttl`) are **examples** demonstrating the process
- You can create your own data with different characters and relationships
- The key is maintaining the **invariants** through the **audit → correct → verify** cycle
- Exact triple counts will vary based on your specific data
