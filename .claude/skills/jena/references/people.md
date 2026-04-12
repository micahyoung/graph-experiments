# People and relationships: load → audit → correct

This reference covers the core workflow for building a graph of people who are connected to each other — families, friend groups, casts, organisational hierarchies, anything where entities refer to one another via named relationships that should hold reciprocally. It walks through authoring a Turtle file, uploading it, running invariant audits, and repairing the graph via a corrections file.

All commands below use three generic variables. Set them once for your session before running anything:

```bash
FUSEKI_URL="<scheme://host:port>"       # e.g. from local-fuseki.md or provided by the user
FUSEKI_CREDENTIALS="<user:password>"    # e.g. from local-fuseki.md or provided by the user
FUSEKI_DATASET="ds-rw"
```

For a local Docker instance started via `references/local-fuseki.md`, substitute the host/port and credentials from that setup. For any other Fuseki, use whatever the user supplies.

---

## 1. Model the relationships

Before writing any Turtle, decide for each relationship in your domain whether it is:

1. **Symmetric** — the same predicate applies in both directions. A is a `spouse` of B, and B is a `spouse` of A (same predicate both times). Good examples: `spouse`, `sibling`, `neighborOf`, `friendOf`, `coworkerOf`.
2. **Inverse-paired** — one predicate for each direction. A `parentOf` B, and B `parent` A (two different predicates). Good examples: `parent`/`parentOf`, `employs`/`employedBy`, `mentors`/`mentoredBy`.

Capture this decision up front because it determines the shape of the audit queries you will run later. For every symmetric predicate you need one audit query; for every inverse pair you need two (one per direction).

### A minimal example

Using a made-up `example:` vocabulary:

```turtle
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix ex: <http://example.org/rel#> .

<http://example.org/person/alice> a foaf:Person ;
    foaf:name "Alice" ;
    ex:spouse <http://example.org/person/bob> ;
    ex:parentOf <http://example.org/person/carol> .

<http://example.org/person/bob> a foaf:Person ;
    foaf:name "Bob" ;
    ex:spouse <http://example.org/person/alice> ;
    ex:parentOf <http://example.org/person/carol> .

<http://example.org/person/carol> a foaf:Person ;
    foaf:name "Carol" ;
    ex:parent <http://example.org/person/alice>, <http://example.org/person/bob> .
```

Note: `spouse` is symmetric (authored in both directions), while `parent`/`parentOf` is an inverse pair. This file is self-consistent, but a larger hand-written file almost certainly won't be on the first pass — that's what the audit queries are for.

---

## 2. Upload and verify

Write your Turtle into a named file (conventionally `people.ttl`, `extended.ttl`, etc.) and POST it to the dataset's data endpoint:

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/$FUSEKI_DATASET/data" \
  --form "file=@people.ttl"
```

Fuseki responds with a small JSON document reporting how many triples it ingested:

```json
{
  "count": 23,
  "tripleCount": 23,
  "quadCount": 0
}
```

**Always compare that number to the number of triples you expected to write.** If you intended ten entities with roughly five triples each and the response says `"tripleCount": 12`, something went wrong — usually a syntax error that caused Fuseki to silently drop statements, or a missing `@prefix` that caused predicates to be parsed as relative URIs. Fix the file and re-upload before moving on.

Uploads are **additive** — POSTing the same file twice doubles its triples (Fuseki deduplicates identical triples, so this is usually harmless, but if you've edited the file it may produce surprises). If you need to start over, drop and recreate the dataset rather than trying to surgically delete things.

---

## 3. Audit the invariants

The pattern for every audit query is the same: *find the pairs where the relationship goes in one direction but not the other*. An empty result set means the invariant holds.

### Symmetric relationship template

For a symmetric predicate `ex:REL`:

```bash
curl -s -u $FUSEKI_CREDENTIALS "$FUSEKI_URL/$FUSEKI_DATASET/sparql" \
  --data-urlencode 'query=PREFIX ex: <http://example.org/rel#>
SELECT ?a ?b WHERE { ?a ex:REL ?b . FILTER NOT EXISTS { ?b ex:REL ?a } }'
```

Reads as: "give me every `(a, b)` such that `a REL b` but `b` does not `REL a`". For a clean graph this returns `"bindings": [ ]`. Any rows are the exact gaps you need to close.

### Inverse-pair template

For an inverse pair `ex:FORWARD` / `ex:INVERSE` you need **two** queries — one per direction — because a graph can be missing either side:

```bash
# Forward → inverse
curl -s -u $FUSEKI_CREDENTIALS "$FUSEKI_URL/$FUSEKI_DATASET/sparql" \
  --data-urlencode 'query=PREFIX ex: <http://example.org/rel#>
SELECT ?a ?b WHERE { ?a ex:FORWARD ?b . FILTER NOT EXISTS { ?b ex:INVERSE ?a } }'

# Inverse → forward
curl -s -u $FUSEKI_CREDENTIALS "$FUSEKI_URL/$FUSEKI_DATASET/sparql" \
  --data-urlencode 'query=PREFIX ex: <http://example.org/rel#>
SELECT ?a ?b WHERE { ?a ex:INVERSE ?b . FILTER NOT EXISTS { ?b ex:FORWARD ?a } }'
```

In practice, authored data is usually written in one canonical direction (e.g. "parents declare their children via `parentOf`") and the other direction is sparse, so the first of the two queries usually finds everything. Run both anyway — the cost is one more HTTP call and the reassurance is worth it.

### When to run the audits

Run the full audit battery **after every upload** — the base file, every extension, and every corrections file. This is how you guarantee that the correction cycle actually converges: a corrections file itself can technically introduce a new gap, so you are not done until the audits come back clean *after the most recent upload*.

---

## 4. Write a corrections file

For every row an audit query returns, you need to add one missing triple. The corrections file is just more Turtle, stored in its own file (`corrections-1.ttl`, `corrections-2.ttl`, …) so the provenance stays clean:

```turtle
@prefix ex: <http://example.org/rel#> .

# Missing inverses found by audit:
<http://example.org/person/alice> ex:spouse <http://example.org/person/bob> .
<http://example.org/person/carol> ex:parent <http://example.org/person/alice>, <http://example.org/person/bob> .
```

A few tips:

- **Name the file by cycle, not by content.** `corrections-1.ttl` is the first round of corrections, `corrections-2.ttl` is the second round (if the first one missed anything), and so on. This makes the session history legible after the fact.
- **Compact multiple fixes per subject.** Turtle lets you list several objects after a predicate with a comma. Use this — it matches how you think about the fix ("alice's parents are …") and makes the file shorter.
- **Don't restate the entity's type or labels.** The corrections file should contain *only* the missing triples. `a foaf:Person` is already in the original data; repeating it just bloats the count.

Upload it with the same curl pattern:

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/$FUSEKI_DATASET/data" \
  --form "file=@corrections-1.ttl"
```

Fuseki again reports a count — this is how you verify the corrections actually landed.

---

## 5. Re-audit

Re-run the exact same audit queries from step 3. If any of them still has rows, write `corrections-2.ttl` from those rows and upload it. Repeat until every audit query returns `"bindings": [ ]`. In practice this almost always converges in one or two cycles — if you're on cycle four, stop and check whether your corrections file is introducing new asymmetries (e.g. you wrote `ex:parent` when you meant `ex:parentOf`).

---

## 6. Final verification

Once the audits are clean, report the total triple count so the user has a sanity check on the size of the graph:

```bash
curl -s -u $FUSEKI_CREDENTIALS "$FUSEKI_URL/$FUSEKI_DATASET/sparql" \
  --data-urlencode 'query=SELECT (COUNT(*) as ?n) WHERE { ?s ?p ?o }'
```

This should equal the sum of all `tripleCount` values Fuseki reported across every upload in the session. If they don't match, some upload contained duplicates of already-present triples — usually harmless, but worth a one-line mention to the user.

At this point the extension is **done**. The success criteria are:

1. Every audit query returns empty bindings.
2. The total triple count is consistent with what you uploaded.
3. The user has enough context to query the graph themselves (dataset name, URL, credentials).

---

## Common gotchas

- **Relative URIs.** Turtle will happily resolve `<alice>` as a relative URI against the server's base — you almost never want this. Always use absolute `<http://…>` URIs for entities and prefix-expanded predicates, or declare a `@base` explicitly.
- **Typos in predicate names.** `ex:spouce` and `ex:spouse` are two entirely different predicates as far as SPARQL is concerned, and the audit queries will not catch the typo — they will just report that nothing is symmetric with `ex:spouce`. If audits come back with suspiciously complete or suspiciously empty results, grep the turtle file for predicate spellings.
- **Dangling references.** Turtle lets you mention a URI as the object of a statement without ever declaring it as a subject. This is fine for RDF but often not what the user intended. A quick `SELECT DISTINCT ?o WHERE { ?s ex:parentOf ?o . FILTER NOT EXISTS { ?o a ?t } }` will surface entities that are referenced but never defined.
- **Whitespace and trailing dots.** Turtle statements end with `.`, predicate-object pairs within a statement are separated by `;`, and objects for the same predicate are separated by `,`. Mixing these up is the single most common source of parse errors. When in doubt, put each triple on its own line with an explicit `.`.
