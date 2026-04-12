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

## Connect to Fuseki (Programmatic)

Graph Explorer supports programmatic connection configuration via environment variables. This approach pre-configures the connection on startup, eliminating the need for manual UI configuration.

### Environment Variable Approach

For a direct SPARQL connection to Fuseki:

```bash
docker run -d -p $GRAPH_EXPLORER_PORT:80 \
  --name graph-explorer \
  --env PROXY_SERVER_HTTPS_CONNECTION=false \
  --env GRAPH_EXP_HTTPS_CONNECTION=false \
  --env PUBLIC_OR_PROXY_ENDPOINT=$FUSEKI_URL/$DATASET \
  --env GRAPH_TYPE=sparql \
  public.ecr.aws/neptune/graph-explorer
```

Key environment variables:
- `PUBLIC_OR_PROXY_ENDPOINT` (required): The SPARQL endpoint URL (e.g., `http://localhost:3030/kennedy`)
- `GRAPH_TYPE` (optional): Set to `sparql` for RDF/SPARQL endpoints. If not specified, multiple connections are created for all query languages.
- `GRAPH_EXP_HTTPS_CONNECTION`: Set to `false` for HTTP connections
- `PROXY_SERVER_HTTPS_CONNECTION`: Set to `false` to disable proxy HTTPS

### Alternative: JSON Configuration

For more complex configurations, create a `config.json` file:

```json
{
  "PUBLIC_OR_PROXY_ENDPOINT": "http://localhost:3030/kennedy",
  "GRAPH_TYPE": "sparql",
  "GRAPH_EXP_HTTPS_CONNECTION": false,
  "PROXY_SERVER_HTTPS_CONNECTION": false
}
```

Then mount it into the container:

```bash
docker run -d -p $GRAPH_EXPLORER_PORT:80 \
  --name graph-explorer \
  -v /path/to/config.json:/graph-explorer/config.json \
  public.ecr.aws/neptune/graph-explorer
```

See [AWS Graph Explorer default connection docs](https://github.com/aws/graph-explorer/blob/main/docs/references/default-connection.md) for all available options.

## Sanity check

Open the UI at `http://localhost:$GRAPH_EXPLORER_PORT/explorer`. A successful connection shows:

- **Connection name** at the top (e.g., "Default Connection")
- **Search panel** with resources from your dataset
- **Resources count** in the search results header

For SPARQL endpoints, you should see your RDF resources listed in the search panel.

## Stop and remove

```bash
docker stop graph-explorer && docker rm graph-explorer
```

This throws away any connection configurations stored in the container. If you need persistent connections, export them via the UI before stopping.

## Notes and gotchas

- **Port `$GRAPH_EXPLORER_PORT` must be free.** If the run fails with `port is already allocated`, either stop the conflicting container or set `GRAPH_EXPLORER_PORT` to a different value and re-run.
- **HTTPS disabled by default for local use.** The environment variables `PROXY_SERVER_HTTPS_CONNECTION=false` and `GRAPH_EXP_HTTPS_CONNECTION=false` prevent certificate warnings. For production, remove these and configure proper TLS.
- **SPARQL endpoint path.** Use the dataset path in the URL: `$FUSEKI_URL/$DATASET` not `$FUSEKI_URL/$DATASET/sparql`. Graph Explorer appends the appropriate endpoint suffix automatically.
- **Authentication.** For Fuseki instances requiring authentication, you may need to configure the proxy server with `USING_PROXY_SERVER=true` and `GRAPH_CONNECTION_URL`. See the [default connection documentation](https://github.com/aws/graph-explorer/blob/main/docs/references/default-connection.md) for details.
- **JSON vs environment variables.** If both a JSON config file and environment variables are provided, JSON takes precedence.
- **Platform warning.** On Apple Silicon (arm64), you may see a platform mismatch warning since the image is built for amd64. This is harmless and the container runs fine via emulation.
