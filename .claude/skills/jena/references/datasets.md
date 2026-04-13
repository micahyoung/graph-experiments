# Managing Fuseki datasets

A Fuseki *dataset* is the top-level container for RDF data. Each Fuseki instance can hold many datasets, each independently queryable at `http://<host>:<port>/<dataset-name>/…`. This reference shows the API commands for creating, listing, and removing them. The commands below use three variables — set them once for your session before running anything:

```bash
export FUSEKI_URL="<scheme://host:port>"       # e.g. from local-fuseki.md or provided by the user
export FUSEKI_CREDENTIALS="<user:password>"    # e.g. from local-fuseki.md or provided by the user
export FUSEKI_DATASET="my-dataset"             # choose appropriate value for your graph
```

For a local Docker instance started via `references/local-fuseki.md`, use `$FUSEKI_URL` and `$FUSEKI_CREDENTIALS` from there.

## Create a TDB2 dataset

TDB2 is the right choice for anything you want to persist and query efficiently. It's disk-backed inside the container and supports the full SPARQL surface.

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/\$/datasets?dbType=tdb2&dbName=$FUSEKI_DATASET"
```

A successful create returns an empty body and HTTP 200. Trying to create a dataset that already exists returns HTTP 409 `Conflict` — that's usually fine, it just means you already have one with that name.

**Naming:** the dataset name becomes the URL segment for all further queries and uploads, so keep it short, lowercase, and free of URL-unsafe characters. Conventional choices are things like `ds-rw`, `kg`, `scratch`.

## Create an in-memory dataset (optional)

For throwaway experiments where persistence across a container restart doesn't matter, an in-memory dataset is slightly faster and uses no disk:

```bash
curl -s -u $FUSEKI_CREDENTIALS \
  -X POST "$FUSEKI_URL/\$/datasets?dbType=mem&dbName=$FUSEKI_DATASET"
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
  -X DELETE "$FUSEKI_URL/\$/datasets/$FUSEKI_DATASET"
```

This is irreversible — it drops every triple in the dataset. Prefer creating a fresh dataset with a new name over deleting and recreating during a working session.

## The `$` in the URL

The `$` in `$/datasets` (note: `$` + `/` + `datasets`) is part of Fuseki's admin API path, not a shell variable. In double-quoted shell strings you have to escape it (`\$`) to stop the shell from expanding it. In single-quoted strings you can write `$` literally.
