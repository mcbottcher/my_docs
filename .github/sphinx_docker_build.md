# Old Sphinx Build: Docker-based CI

Before switching to Poetry, the Sphinx build in CI used a custom Docker image via a [composite GitHub Action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action).

## How it worked

### `.github/actions/Dockerfile`

The image extended the official `sphinxdoc/sphinx` image, copied the repo in, installed extra dependencies, and ran `make html`.

```dockerfile
FROM sphinxdoc/sphinx

COPY . /home/my_docs/

WORKDIR /home/my_docs

RUN pip install -r docs/requirements.txt

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["cd docs && make html"]
```

### `.github/actions/script.sh`

The shell script built the image, ran the container, copied the build output out, then cleaned up.

```bash
#!/bin/bash

set -e

echo $(pwd)

# build image
docker build -t my_image -f .github/actions/Dockerfile .

# run image: don't delete container
docker run -t my_image

# copy the build folder from container to host machine
docker cp $(docker ps -a -q):/home/my_docs/docs/build ./docs/

# remove the container
docker rm $(docker ps -a -q)

# remove the image
docker rmi $(docker images -q)
```

### `.github/actions/action.yml`

The composite action simply invoked the script.

```yaml
name: 'Sphinx Build'
description: 'Builds documentation using Sphinx'
author: 'Mikkel Caschetto-Bottcher'

branding:
  icon: 'cpu'
  color: 'gray-dark'

runs:
  using: "composite"
  steps:
    - name: "Run Sphinx Build Script"
      run: $GITHUB_ACTION_PATH/script.sh
      shell: bash
```

### `sphinx.yml` (relevant step)

The workflow called the composite action like this:

```yaml
- name: Build HTML
  uses: ./.github/actions
```

## Why it was replaced

The Docker approach was replaced with Poetry directly in the workflow, mirroring the local `build_docs.sh` script. This removed the need for the Dockerfile, script, and composite action entirely.
