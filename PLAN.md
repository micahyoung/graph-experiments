# Fuseki Setup Plan

## Prerequisites
- Docker installed and running
- Empty working directory

## Steps

### 1. Pull and Start Fuseki Container

```bash
docker pull secoresearch/fuseki
docker run -d -p 3030:3030 --name fuseki secoresearch/fuseki
```

### 2. Get Admin Password

```bash
docker logs fuseki 2>&1 | grep "admin="
```

Output will show: `admin=<random-password>`

Note: Replace `<PASSWORD>` in subsequent commands with the actual password.

### 3. Create RDF Data File

Create `simpsons.ttl`:

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

### 4. Create Read-Write Dataset via API

```bash
curl -s -u admin:<PASSWORD> -X POST "http://localhost:3030/$/datasets?dbType=tdb2&dbName=ds-rw"
```

This creates a TDB2 dataset named `ds-rw` with all default services (read/write graph store, SPARQL query/update).

### 5. Upload Data

```bash
curl -s -u admin:<PASSWORD> -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@simpsons.ttl"
```

Expected response:
```json
{ "count" : 40 , "tripleCount" : 40 , "quadCount" : 0 }
```

### 6. Query the Data

```bash
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX family: <http://example.org/family#>

SELECT ?person ?name ?age
WHERE {
  ?person a foaf:Person ;
          foaf:name ?name ;
          foaf:age ?age .
}
ORDER BY ?name'
```

## Expected Results

Query returns 5 persons:
- Bart Simpson (age 10)
- Homer Simpson (age 45)
- Lisa Simpson (age 8)
- Maggie Simpson (age 1)
- Marge Simpson (age 43)

Total: 40 triples uploaded

---

## Extended Family Setup

### 7. Create Extended Family Data File

Create `extended-family.ttl`:

```turtle
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix family: <http://example.org/family#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Homer's relatives
<http://example.org/person/grandpa> a foaf:Person ;
    foaf:name "Abraham Simpson" ;
    foaf:age 84 ;
    foaf:jobTitle "Retired" ;
    family:parentOf <http://example.org/person/homer> ;
    family:spouse <http://example.org/person/jacqueline> .

<http://example.org/person/jacqueline> a foaf:Person ;
    foaf:name "Jacqueline Bouvier" ;
    foaf:age 82 ;
    foaf:jobTitle "Retired" ;
    family:parentOf <http://example.org/person/marge>, <http://example.org/person/patty>, <http://example.org/person/SELMA> ;
    family:spouse <http://example.org/person/grandpa> .

<http://example.org/person/patty> a foaf:Person ;
    foaf:name "Patty Bouvier" ;
    foaf:age 48 ;
    foaf:jobTitle "Teller" ;
    family:parent <http://example.org/person/jacqueline> ;
    family:sibling <http://example.org/person/marge>, <http://example.org/person/SELMA> ;
    family:spouse <http://example.org/person/HERBERT> .

<http://example.org/person/SELMA> a foaf:Person ;
    foaf:name "Selma Bouvier" ;
    foaf:age 46 ;
    foaf:jobTitle "Alcohol Abuse Counselor" ;
    family:parent <http://example.org/person/jacqueline> ;
    family:sibling <http://example.org/person/marge>, <http://example.org/person/patty> ;
    family:spouse <http://example.org/person/lenny> ;
    family:parentOf <http://example.org/person/rod>, <http://example.org/person/todd> .

<http://example.org/person/HERBERT> a foaf:Person ;
    foaf:name "Herbert Powell" ;
    foaf:age 50 ;
    foaf:jobTitle "Unemployed" ;
    family:spouse <http://example.org/person/patty> .

# Ned Flanders family
<http://example.org/person/ned> a foaf:Person ;
    foaf:name "Ned Flanders" ;
    foaf:age 45 ;
    foaf:jobTitle "Minister" ;
    family:neighborOf <http://example.org/person/homer> ;
    family:spouse <http://example.org/person/marilyn> ;
    family:parentOf <http://example.org/person/rod_f>, <http://example.org/person/todd_f> .

<http://example.org/person/marilyn> a foaf:Person ;
    foaf:name "Marilyn Flanders" ;
    foaf:age 43 ;
    foaf:jobTitle "Homemaker" ;
    family:spouse <http://example.org/person/ned> ;
    family:parentOf <http://example.org/person/rod_f>, <http://example.org/person/todd_f> .

<http://example.org/person/rod_f> a foaf:Person ;
    foaf:name "Rod Flanders" ;
    foaf:age 12 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/ned>, <http://example.org/person/marilyn> ;
    family:sibling <http://example.org/person/todd_f> .

<http://example.org/person/todd_f> a foaf:Person ;
    foaf:name "Todd Flanders" ;
    foaf:age 9 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/ned>, <http://example.org/person/marilyn> ;
    family:sibling <http://example.org/person/rod_f> .

# Moe
<http://example.org/person/moe> a foaf:Person ;
    foaf:name "Moe Szyslak" ;
    foaf:age 48 ;
    foaf:jobTitle "Bar Owner" ;
    family:friendOf <http://example.org/person/homer> .

# Lenny and Carl
<http://example.org/person/lenny> a foaf:Person ;
    foaf:name "Lenny Leonard" ;
    foaf:age 44 ;
    foaf:jobTitle "Nuclear Plant Worker" ;
    family:colleagueOf <http://example.org/person/homer>, <http://example.org/person/carl> ;
    family:spouse <http://example.org/person/SELMA> ;
    family:parentOf <http://example.org/person/rod>, <http://example.org/person/todd> .

<http://example.org/person/carl> a foaf:Person ;
    foaf:name "Carl Carlson" ;
    foaf:age 46 ;
    foaf:jobTitle "Nuclear Plant Worker" ;
    family:colleagueOf <http://example.org/person/homer>, <http://example.org/person/lenny> ;
    family:spouse <http://example.org/person/louise> ;
    family:parentOf <http://example.org/person/edna> .

<http://example.org/person/louise> a foaf:Person ;
    foaf:name "Louise Carlson" ;
    foaf:age 44 ;
    foaf:jobTitle "Teacher" ;
    family:spouse <http://example.org/person/carl> ;
    family:parentOf <http://example.org/person/edna> .

# Selma and Lenny's children (Leonards, not Flanders)
<http://example.org/person/rod> a foaf:Person ;
    foaf:name "Rod Leonard" ;
    foaf:age 14 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/SELMA>, <http://example.org/person/lenny> ;
    family:sibling <http://example.org/person/todd> .

<http://example.org/person/todd> a foaf:Person ;
    foaf:name "Todd Leonard" ;
    foaf:age 12 ;
    foaf:jobTitle "Student" ;
    family:parent <http://example.org/person/SELMA>, <http://example.org/person/lenny> ;
    family:sibling <http://example.org/person/rod> .

# Carl and Louise's child
<http://example.org/person/edna> a foaf:Person ;
    foaf:name "Edna Carlson" ;
    foaf:age 6 ;
    foaf:jobTitle "Child" ;
    family:parent <http://example.org/person/carl>, <http://example.org/person/louise> .
```

### 8. Upload Extended Family Data

```bash
curl -s -u admin:<PASSWORD> -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@extended-family.ttl"
```

Expected response:
```json
{ "count" : 114 , "tripleCount" : 114 , "quadCount" : 0 }
```

Total triples: 154

### 9. Audit the Graph

Check for data inconsistencies:

```bash
# Check for missing parent relationships
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?parent ?child
WHERE {
  ?parent family:parentOf ?child .
  FILTER NOT EXISTS { ?child family:parent ?parent }
}'

# Check for non-reciprocal spouse relationships
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?person1 ?person2
WHERE {
  ?person1 family:spouse ?person2 .
  FILTER NOT EXISTS { ?person2 family:spouse ?person1 }
}'

# Check for non-reciprocal sibling relationships
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?person1 ?person2
WHERE {
  ?person1 family:sibling ?person2 .
  FILTER NOT EXISTS { ?person2 family:sibling ?person1 }
}'
```

### 10. Apply Corrections

Create `corrections.ttl`:

```turtle
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix family: <http://example.org/family#> .

# Fix 1: Add missing parent relationships
<http://example.org/person/homer> family:parent <http://example.org/person/grandpa> .
<http://example.org/person/marge> family:parent <http://example.org/person/jacqueline> .

# Fix 2: Add missing sibling relationships (Marge should list her sisters)
<http://example.org/person/marge> family:sibling <http://example.org/person/patty> .
<http://example.org/person/marge> family:sibling <http://example.org/person/SELMA> .

# Fix 3: Make neighborOf reciprocal
<http://example.org/person/homer> family:neighborOf <http://example.org/person/ned> .
```

Upload corrections:

```bash
curl -s -u admin:<PASSWORD> -X POST "http://localhost:3030/ds-rw/data" \
  --form "file=@corrections.ttl"
```

Expected response:
```json
{ "count" : 7 , "tripleCount" : 7 , "quadCount" : 0 }
```

### 11. Verify Corrections

```bash
# Verify all parent relationships are consistent (should return empty)
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?parent ?child
WHERE {
  ?parent family:parentOf ?child .
  FILTER NOT EXISTS { ?child family:parent ?parent }
}'

# Verify all sibling relationships are reciprocal (should return empty)
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?person1 ?person2
WHERE {
  ?person1 family:sibling ?person2 .
  FILTER NOT EXISTS { ?person2 family:sibling ?person1 }
}'

# Verify all neighborOf relationships are reciprocal (should return empty)
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=PREFIX family: <http://example.org/family#>
SELECT ?person1 ?person2
WHERE {
  ?person1 family:neighborOf ?person2 .
  FILTER NOT EXISTS { ?person2 family:neighborOf ?person1 }
}'

# Final count (should be 159 triples)
curl -s -u admin:<PASSWORD> "http://localhost:3030/ds-rw/sparql" \
  --data-urlencode 'query=SELECT (COUNT(*) as ?totalTriples) WHERE { ?s ?p ?o }'
```

## Final Results

- **Total persons**: 21
- **Total triples**: 159
- **All parent/parentOf relationships**: Consistent
- **All spouse relationships**: Reciprocal
- **All sibling relationships**: Reciprocal
- **All neighborOf relationships**: Reciprocal

### Persons in Graph

**Core Simpsons**: Homer, Marge, Bart, Lisa, Maggie

**Extended Family**:
- Abraham Simpson (Grandpa)
- Jacqueline Bouvier (Marge's mother)
- Patty Bouvier (Marge's sister)
- Selma Bouvier (Marge's sister)
- Herbert Powell (Patty's ex-husband)

**Flanders Family**:
- Ned Flanders (Homer's neighbor)
- Marilyn Flanders
- Rod Flanders (age 12)
- Todd Flanders (age 9)

**Friends & Colleagues**:
- Moe Szyslak (Homer's friend)
- Lenny Leonard (Homer's colleague)
- Carl Carlson (Homer's colleague)
- Louise Carlson (Carl's wife)

**Children**:
- Rod Leonard (age 14, Selma & Lenny's son)
- Todd Leonard (age 12, Selma & Lenny's son)
- Edna Carlson (age 6, Carl & Louise's daughter)
