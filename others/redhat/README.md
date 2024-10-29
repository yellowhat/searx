# searx

Deploy a custom [searx](https://searx.github.io/searx) instance

## Local

```console
podman build --file Dockerfile --tag searx .
podman run -it --rm -p 8080:8080 --user 1000:1000 searx
```

## [RedHat Developer](https://developers.redhat.com)

### Requirements

* A free account
* A `searx` container image

### How-to

1. Create a new account
2. Install kubernetes manifests:

    ```bash
    git clone https://github.com/yellowhat/searx searx
    cd searx
    kubectl create -f k8s/
    ```

## Add search engine (Firefox)

1. go to `https://<hostname>/search?q=searx`
2. Right click on the address bar
3. Click on `Add "searx"`
