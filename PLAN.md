# Fuseki Setup Plan

## Prerequisites
- Docker installed and running
- Empty working directory

## Steps

### 1. Pull and Start Fuseki Container

```bash
docker run -d -p 3030:3030 --name fuseki secoresearch/fuseki
```

### 2. Get Admin Password

```bash
docker logs fuseki 2>&1 | grep "admin="
```

Output will show: `admin=<random-password>`

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

### 4. Access Fuseki UI

Navigate to: `http://admin:<PASSWORD>@localhost:3030/`

### 5. Create Read-Write Dataset

1. Click "manage" in navigation
2. Click "new dataset"
3. Enter dataset name: `ds-rw`
4. Enable services:
   - Graph Store Protocol (read)
   - Graph Store Protocol (write)
   - SPARQL Query
   - SPARQL Update
5. Click "create"

### 6. Upload Data

1. Navigate to: `http://admin:<PASSWORD>@localhost:3030/#/dataset/ds-rw/upload`
2. Click "select files" and choose `simpsons.ttl`
3. Click "upload now"
4. Wait for "Triples uploaded: 40"

### 7. Query the Data

Via curl:

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

Or via UI: `http://admin:<PASSWORD>@localhost:3030/#/dataset/ds-rw/query`

## Expected Results

Query returns 5 persons:
- Bart Simpson (age 10)
- Homer Simpson (age 45)
- Lisa Simpson (age 8)
- Maggie Simpson (age 1)
- Marge Simpson (age 43)

Total: 40 triples uploaded
