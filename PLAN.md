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
