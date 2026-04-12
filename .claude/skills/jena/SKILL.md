---
name: jena
description: Load, extend, and audit RDF graph data in an Apache Jena Fuseki instance running locally in Docker. Covers the create-dataset → upload-turtle → audit-invariants → correct → re-audit cycle that keeps a graph internally consistent as it grows. Use this skill whenever the user mentions Fuseki, Jena, TDB2, SPARQL update workflows, loading .ttl / turtle / RDF files, iterating on a knowledge graph, reciprocal relationship validation, or graph invariant auditing — even if they don't name the tool explicitly (e.g. "stand up a local triple store and load this data").
---

# Jena Fuseki: iterative graph building with invariant audits

This skill captures a repeatable workflow for building a small-to-medium RDF graph in a local Jena Fuseki instance. The central idea is that a graph is built up **incrementally**, and after each addition the model runs a set of **audit queries** that check domain-specific invariants (e.g. "every X relationship has its reciprocal Y"). Violations are fixed via a corrections file, then the audits are re-run until they come back clean. This cycle is what keeps the graph consistent as it grows — it is much cheaper to catch a missing reciprocal one batch at a time than to discover it hundreds of triples later.

## When to reach for this skill

- The user wants a local triple store up quickly to experiment with
- The user is describing data as entities-and-relationships and asks for it to be queryable
- The user says things like "extend the graph with …" or "add … to the dataset"
- The user wants to validate that a graph has certain structural properties (reciprocity, connectedness, coverage)
- The user wants to configure or explore the graph visually in Graph Explorer

## Overall workflow

The workflow has five phases. Most extensions only exercise phases 2–3 repeatedly.

1. **Bootstrap** *(optional — skip if Fuseki is already running)* — start a local Fuseki container, extract credentials, and create an empty dataset. Read `references/local-fuseki.md` only if you need to spin one up from scratch. If the user already has a Fuseki endpoint, just confirm `$FUSEKI_URL`, `$FUSEKI_CREDENTIALS`, and `$FUSEKI_DATASET` and proceed to phase 2.
2. **Load** — write a Turtle file, upload it, verify the reported triple count matches expectation.
3. **Audit & correct** — run domain-specific invariant queries, generate a corrections file for any violations, upload it, re-run the audits until they come back empty.
4. **Cleanup** — tear down the container and remove scratch files when the session is finished (only on request — do not tear down a running instance without confirmation, the user may still be exploring the graph).
5. **Explore** *(optional)* — configure Graph Explorer UI for visual exploration. Read `references/graph-explorer-ui.md` for Search, Namespaces, Predicate Styling, and Layout operations.

Each phase has a reference file with the concrete commands. Read the reference at the moment you need it; you don't need to load everything up front.

## References

Read these on demand — they are small and self-contained.

| File | Read it when … |
|------|----------------|
| `references/local-fuseki.md` | *(optional)* You need to start, inspect, or tear down a local Fuseki container (specific Docker image, password extraction, lifecycle). Skip entirely if a Fuseki instance is already running — just set `$FUSEKI_URL` and `$FUSEKI_CREDENTIALS`. |
| `references/local-graph-explorer.md` | *(optional)* You want to visually explore or browse the graph in a browser UI. Covers pulling the AWS Graph Explorer Docker image, connecting it to a running Fuseki instance, and tear down. |
| `references/graph-explorer-ui.md` | You need to interact with Graph Explorer's UI programmatically or manually. Covers Search, Namespaces, Predicate Styling, Expand, and Layout operations. |
| `references/datasets.md` | You need to create / delete / list a dataset inside a running Fuseki (TDB2 and in-memory). |
| `references/people.md` | The data you're loading models people and their relationships (family, social, organisational, fictional cast, etc.). This covers the Turtle authoring, upload, invariant audit, and correction loop in detail, and it is the reference most extensions need. |

If the user's domain isn't "people and relationships", the same pattern still applies — use `references/people.md` as a template and adapt the invariants to the new domain. The mechanical parts (upload / verify / audit / correct) don't change.

## Guiding principles

- **Let the audit queries find problems.** Don't try to hand-verify a turtle file before uploading it — it's faster to upload, run the reciprocity queries, and let them enumerate the exact gaps. The queries are the source of truth.
- **Corrections are additive.** Never edit the original data file to fix a reciprocity gap. Instead, write a small `corrections-N.ttl` file that adds the missing inverse triples. This keeps the history of what the user authored versus what was derived, and it composes naturally with further extensions.
- **Verify triple counts at each upload.** Fuseki's upload response reports `count` / `tripleCount`. If that number doesn't match what you expected from the file, stop and investigate before running audits — a parse error is easier to catch here than three steps later.
- **Empty bindings mean success.** All audit queries are written as "find things that violate the invariant". A clean graph makes them return `"bindings": [ ]`. That, combined with a sensible total triple count, is the definition of done for an extension.
- **Confirm before destructive actions.** Stopping the container, removing it, and deleting `*.ttl` files are all part of the documented workflow but they throw away the session's data. Ask the user before running the cleanup unless they have explicitly authorised it.

## Output expectations

When executing this workflow, narrate progress tersely: one line per phase beat (e.g. "dataset created", "extension uploaded, 30 triples", "audit found 9 parentOf gaps, writing corrections", "all invariants clean"). Show the final triple count so the user can sanity-check the total. Do not paste the full SPARQL JSON output back at the user unless they ask — they only care about the counts and whether the audits are empty.
