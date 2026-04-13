# Local Fuseki in Docker

The quickest way to get a working Fuseki is the `secoresearch/fuseki` image, which ships a pre-wired admin account with a freshly generated password that is written to the container's stdout on startup. This reference covers the full container lifecycle: pull, run, capture credentials, and tear down.

## Image

```
secoresearch/fuseki
```

This image exposes the Fuseki UI/API on port `3030`, uses `admin` as the admin username, and regenerates the admin password on every `docker run` (it is *not* stable across restarts — always re-extract after you start a fresh container).

## Start the container

```bash
docker pull secoresearch/fuseki
docker run -d -p 3030:3030 --name fuseki secoresearch/fuseki
```

The container needs a moment to initialise before the password line appears in its logs. A short sleep is the most reliable way to wait:

```bash
sleep 2
```

## Extract the admin password

The password is printed to the container logs as a line of the form `admin=<value>`. Pull it out with:

```bash
export FUSEKI_PASSWORD=$(docker logs fuseki 2>&1 | grep "admin=" | cut -d= -f2)
```

From here on, use `admin:$FUSEKI_PASSWORD` as the HTTP basic-auth credentials for every curl call against `http://localhost:3030/…`. Consider echoing the password once so the user can reach the UI at `http://localhost:3030` in a browser if they want to poke around manually.

## Other variables

```bash
export FUSEKI_URL="http://localhost:3030"            # if using default port
export FUSEKI_CREDENTIALS="admin:$FUSEKI_PASSWORD"   # if using default username
```

## Sanity check

You can confirm the server is up and the credentials work by asking Fuseki for its list of datasets (it should be empty on a fresh container):

```bash
curl -s -u $FUSEKI_CREDENTIALS $FUSEKI_URL/$/datasets
```

## Stop and remove

```bash
docker stop fuseki && docker rm fuseki
```

This throws away all datasets and their contents — the image is not persistent. If the user wants the data to survive a restart they should mount a volume, but that is out of scope for this reference (and for the quick-experiments workflow this skill targets).

## Notes and gotchas

- **Port 3030 must be free.** If the run fails with `port is already allocated`, either stop the conflicting container or map a different host port (`-p 3031:3030`) and adjust subsequent URLs accordingly.
- **Don't amend the `--name fuseki` flag lightly.** The rest of the workflow hard-codes that name when running `docker logs fuseki` and `docker stop fuseki`. If you need a different name, update both places.
- **The password is ephemeral.** Re-extract it after any `docker restart fuseki` — the image regenerates it.
- **The container's log buffer is small.** If you leave the container running for a while and then re-run `docker logs fuseki`, the `admin=` line is still in there (it was written at startup), but if you rotate the logs or redeploy you'll lose it. When in doubt, just stop, remove, and re-run.
