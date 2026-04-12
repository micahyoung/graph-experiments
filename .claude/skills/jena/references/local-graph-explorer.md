# Local Graph Explorer in Docker

The quickest way to get a working Graph Explorer is the `public.ecr.aws/neptune/graph-explorer` image from AWS ECR Public. This reference covers the full container lifecycle: pull, run, connect to a Fuseki instance, and tear down.

## Prerequisites

A running Fuseki instance. For local development, see `local-fuseki.md` to start one. Set these variables once for your session before running anything:

```bash
GRAPH_EXPLORER_PORT="3031"              # host port to expose the UI on
FUSEKI_URL="<scheme://host:port>"       # e.g. from local-fuseki.md or provided by the user
DATASET="<dataset-name>"                # e.g. from datasets.md
```

For a local Docker instance started via `references/local-fuseki.md`, `$FUSEKI_URL` is the host/port from that setup. For any other Fuseki, substitute whatever the user supplies.

## Image

```
public.ecr.aws/neptune/graph-explorer
```

This image exposes the Graph Explorer UI internally on port `80`, mapped to `$GRAPH_EXPLORER_PORT` on the host. For local development, disable HTTPS to avoid certificate warnings.

## Start the container

```bash
docker pull public.ecr.aws/neptune/graph-explorer
docker run -d -p $GRAPH_EXPLORER_PORT:80 \
  --name graph-explorer \
  --env PROXY_SERVER_HTTPS_CONNECTION=false \
  --env GRAPH_EXP_HTTPS_CONNECTION=false \
  public.ecr.aws/neptune/graph-explorer
```

The container needs a moment to initialise. A short sleep is the most reliable way to wait:

```bash
sleep 3
```

## Connect to Fuseki

Graph Explorer connects to your RDF store via a connection configuration. Open the UI at `http://localhost:$GRAPH_EXPLORER_PORT/explorer` and configure the connection:

1. Click "Add New Connection"
2. Set **Query Language** to `SPARQL - RDF (Resource Description Framework)`
3. Set **Public or Proxy Endpoint** to `$FUSEKI_URL/$DATASET`
4. Click "Add Connection"

## Sanity check

You can confirm the connection works by checking the synchronization status in the UI. A successful connection shows:

- **Resources**: count of distinct subjects
- **Predicates**: count of distinct predicates
- **Last Synchronization**: timestamp

## Stop and remove

```bash
docker stop graph-explorer && docker rm graph-explorer
```

This throws away any connection configurations stored in the container. If you need persistent connections, export them via the UI before stopping.

## Notes and gotchas

- **Port `$GRAPH_EXPLORER_PORT` must be free.** If the run fails with `port is already allocated`, either stop the conflicting container or set `GRAPH_EXPLORER_PORT` to a different value and re-run.
- **HTTPS disabled by default for local use.** The environment variables `PROXY_SERVER_HTTPS_CONNECTION=false` and `GRAPH_EXP_HTTPS_CONNECTION=false` prevent certificate warnings. For production, remove these and configure proper TLS.
- **SPARQL endpoint path.** Use the dataset path in the URL: `$FUSEKI_URL/$DATASET` not `$FUSEKI_URL/$DATASET/sparql`. Graph Explorer appends the appropriate endpoint suffix automatically.
- **Authentication.** If your Fuseki instance requires authentication, the credentials are handled via the proxy server when "Using Proxy-Server" is enabled. For direct connections, Fuseki's CORS settings must allow the Graph Explorer origin.
