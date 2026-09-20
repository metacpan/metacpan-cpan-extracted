# Crawl4AI live-test stack (Kubernetes + local Docker)

A minimal, self-contained stack for running the `WWW::Crawl4AI` **live** tests
(`t/70-live-client.t`, `t/75-live-chain.t`, `t/78-live-smoke.t`) against a real
Crawl4AI REST service:

- **crawl4ai** — the Crawl4AI Docker API on port 11235 (`unclecode/crawl4ai`).
- **crawl4ai-fixture** — plain nginx serving two deterministic HTML pages
  (`examples/fixture/`), so the assertions never depend on the public internet.

The live tests are **env-gated**: with no env set they `skip_all`, so the normal
mocked suite (`dzil test` / `prove -l t`) stays offline and green. They read:

| env var                | meaning                                                                 |
|------------------------|-------------------------------------------------------------------------|
| `CRAWL4AI_URL`         | the Crawl4AI REST base URL, reachable from *you*                        |
| `CRAWL4AI_API_TOKEN`   | bearer token the client sends; **must** match the server's token        |
| `CRAWL4AI_FIXTURE_URL` | the fixture URL as reachable **from the crawl4ai container** (t/70, t/75)|
| `CRAWL4AI_LIVE_PUBLIC` | set to `1` to also run the public-internet smoke (t/78)                  |

## Crawl4AI 0.9.3 gotchas (baked into the manifests)

Three server settings are required and each is a real change from an
unconfigured run:

- **`CRAWL4AI_API_TOKEN`** — without it the server binds the *container's*
  loopback only; published ports / Services get connection resets and the
  readiness probe never passes. Setting it binds `0.0.0.0` **and** requires
  `Authorization: Bearer <token>` on every endpoint except `/health`.
- **`CRAWL4AI_ALLOW_INTERNAL_URLS=true`** — 0.9.3's SSRF guard refuses to crawl
  private/internal hosts; the in-cluster fixture is one. Leave this **off** for
  any internet-facing deployment.
- **`CRAWL4AI_EXECUTE_JS_ENABLED=true`** — `/execute_js` is disabled by default.

## Kubernetes

```sh
kubectl apply -f examples/k8s/                       # namespace + secret + crawl4ai + fixture
kubectl -n crawl4ai-test rollout status deploy/crawl4ai --timeout=300s
kubectl -n crawl4ai-test rollout status deploy/crawl4ai-fixture --timeout=120s

# Reach the REST API from your machine:
kubectl -n crawl4ai-test port-forward svc/crawl4ai 11235:11235 &

# Use the same token the Secret holds (default sample: change-me-sample-token).
# The fixture is reached by crawl4ai over in-cluster DNS, not by you:
CRAWL4AI_URL=http://127.0.0.1:11235 \
CRAWL4AI_API_TOKEN=change-me-sample-token \
CRAWL4AI_FIXTURE_URL=http://crawl4ai-fixture.crawl4ai-test.svc.cluster.local/ \
  prove -lv t/70-live-client.t t/75-live-chain.t

# Teardown:
kubectl delete namespace crawl4ai-test
```

## Local Docker (no cluster needed)

Same REST surface, handy when a cluster is unavailable. crawl4ai reaches the
fixture by container name on a shared user network:

```sh
docker network create crawl4ai-live-net
docker run -d --name crawl4ai-fixture --network crawl4ai-live-net \
  -v "$PWD/examples/fixture:/usr/share/nginx/html:ro" nginx:alpine
docker run -d --name crawl4ai-live --network crawl4ai-live-net \
  -p 127.0.0.1:11235:11235 --shm-size=1g \
  -e CRAWL4AI_API_TOKEN=livetesttoken123 \
  -e CRAWL4AI_ALLOW_INTERNAL_URLS=true \
  -e CRAWL4AI_EXECUTE_JS_ENABLED=true \
  unclecode/crawl4ai:latest

CRAWL4AI_URL=http://127.0.0.1:11235 \
CRAWL4AI_API_TOKEN=livetesttoken123 \
CRAWL4AI_FIXTURE_URL=http://crawl4ai-fixture/ \
  prove -lv t/70-live-client.t t/75-live-chain.t

# Teardown:
docker rm -f crawl4ai-live crawl4ai-fixture
docker network rm crawl4ai-live-net
```

## Public smoke (optional)

```sh
CRAWL4AI_URL=http://127.0.0.1:11235 CRAWL4AI_API_TOKEN=livetesttoken123 \
  CRAWL4AI_LIVE_PUBLIC=1 prove -lv t/78-live-smoke.t
```

`bin/www-crawl4ai-doctor --base-url http://127.0.0.1:11235` (with
`CRAWL4AI_API_TOKEN` exported) is a quick way to confirm the service is
reachable and see the active strategy chain before running the suite.
