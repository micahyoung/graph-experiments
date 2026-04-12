# Managing Fuseki datasets

A Fuseki *dataset* is the top-level container for RDF data. Each Fuseki instance can hold many datasets, each independently queryable at `http://<host>:<port>/<dataset-name>/…`. This reference shows the generic one-liners for creating, listing, and removing them. The commands below use three generic variables — set them once for your session before running anything:

```bash
FUSEKI_URL="<scheme://host:port>"       # e.g. from local-fuseki.md or provided by the user
FUSEKI_CREDENTIALS="<user:password>"    # e.g. from local-fuseki.md or provided by the user
DATASET="my-dataset"
```

For a local Docker instance started via `references/local-fuseki.md`, `$FUSEKI_URL` is the host/port from that setup and `$FUSEKI_CREDENTIALS` is `admin:<extracted-password>`. For any other Fuseki, substitute whatever the user supplies.

## Create a TDB2 dataset

TDB2 is the right choice for anything you want to persist and query efficiently. It's disk-backed inside the container and supports the full SPARQL surface.

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/\$/datasets?dbType=tdb2&dbName=$DATASET"
```

A successful create returns an empty body and HTTP 200. Trying to create a dataset that already exists returns HTTP 409 `Conflict` — that's usually fine, it just means you already have one with that name.

**Naming:** the dataset name becomes the URL segment for all further queries and uploads, so keep it short, lowercase, and free of URL-unsafe characters. Conventional choices are things like `ds-rw`, `kg`, `scratch`.

## Create an in-memory dataset (optional)

For throwaway experiments where persistence across a container restart doesn't matter, an in-memory dataset is slightly faster and uses no disk:

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/\$/datasets?dbType=mem&dbName=$DATASET"
```

Everything downstream (upload, SPARQL, correction cycle) works identically to TDB2. Default to TDB2 unless the user asks for memory explicitly.

## List existing datasets

```bash
curl -s -u $FUSEKI_CREDENTIALS "$FUSEKI_URL/\$/datasets"
```

Returns a JSON object with a `datasets` array. Each entry has `ds.name`, `ds.state`, and related metadata. Use this to confirm your create succeeded or to find out what's already loaded in a container you just inherited.

## Delete a dataset

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X DELETE "$FUSEKI_URL/\$/datasets/$DATASET"
```

This is irreversible — it drops every triple in the dataset. Prefer creating a fresh dataset with a new name over deleting and recreating during a working session.

## The `$` in the URL

The `$` in `\$/datasets` is part of Fuseki's admin API path, not a shell variable. In double-quoted shell strings you have to escape it (`\$`) to stop the shell from expanding it. In single-quoted strings you can write `$` literally.

## What this reference deliberately does not cover

- **Security configuration** — the image used in `references/local-fuseki.md` ships with sensible defaults; production hardening is out of scope.
- **Backup / restore** — for the experimental workflow this skill targets, "delete and re-upload the turtle files" is the recovery strategy. If the user asks about tdb2.tdbbackup, escalate to the Jena docs.
- **Graph names / named graphs** — all uploads in `references/people.md` go to the default graph. If the user needs named graph support, the same POST endpoint accepts a `?graph=<uri>` parameter.
