# The PodTatoHead Server
Podtato-head is a cloud-native application built to colorfully demonstrate delivery scenarios using different tools and services. This repository contains the PodTatoHead Application, it's manifest and a helm chart for easy deployment.

## Requirements

To run the application with Docker, the application entry at [cmd/main.go](cmd/main.go) requires 4 variables which can be set either by providing the var names when invoking the file or by setting the following env variables:

- PODTATO_COMPONENT (Public)
- PODTATO_PORT (Public)
- PODTATO_STARTUP_DELAY (Public)
- PODTATO_SECRET_MESSAGE (Private)

The go-side names, default values and some usage info are detailed in the aforementioned file.

Packages required:

- docker
- docker-buildx

## Installing

### Docker
Run the [root Makefile](Makefile) (bare or with `init`) to initialize the required environment variables. Set `DEPLOYMENT_METHOD` to change the deployment platform and env init workflow.

Afterwards the image can be build and run with the same named make recipes.

```shell
make
make build
make run
```

### Kubernetes Manifest
The Kubernetes manifest is located in the `deploy` folder. It can be deployed using `kubectl` or `kustomize`.

<!---x-release-please-start-version-->
> ```kubectl apply -f https://github.com/podtato-head/podtato-head-app/releases/download/v0.3.3/manifest.yaml```
<!---x-release-please-end-->

### Helm Chart
The Helm chart is located in the `charts` folder. It can be deployed using `helm`.

> ```helm upgrade --install --wait podtato --namespace default oci://ghcr.io/podtato-head/charts/podtato-head```
