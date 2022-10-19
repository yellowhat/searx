# searx

Deploy a custom [searx](https://searx.github.io/searx) instance

## Local

```console
podman build -t searx -f Dockerfile .
podman run -it --rm -p 8080:8080 searx
```

## [mogenius](https://mogenius.io)

### Requirements

* A free account
* A `searx` container image

### How-to

1. Create a new account
2. `Service name`: `searx`
3. `Add a service` (Container image):
    * `Container image`: `ghcr.io/yellowhat/searx`
    * `CPU`: 0.5
    * `RAM`: 1 GB
    * `Temp. Storage`: 1 GB
    * `Ports`: HTTPS/8080

## Add search engine (Firefox)

1. go to `https://<hostname>/search?q=searx`
2. Right click on the address bar
3. Click on `Add "searx"`
