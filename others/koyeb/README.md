# searx

Deploy a custom [searx](https://searx.github.io/searx) instance

## Local

```console
podman build -t searx .
podman run -it --rm -p 8080:8080 searx
```

## [koyeb](https://koyeb.com)

### Requirements

* A free account
* A `searx` container image

### How-to

1. Create a new account
2. `Service name`: `searx`
3. `Add a service` (Container image):
    * `Container image`: `ghcr.io/yellowhat/searx`
    * `CPU Eco`: `Free`
    * `Exposed Ports`: `8080`, `HTTP`, `/`
    * `Health checks`: `8080`, `HTTP`, `/`, `GET`

## Add search engine (Firefox)

1. go to `https://<hostname>/search?q=searx`
2. Right click on the address bar
3. Click on `Add "searx"`
