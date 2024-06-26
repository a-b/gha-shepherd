# GitHub Action for managing shepherd leases
[![.github/workflows/test.yml](https://github.com/a-b/gha-shepherd/actions/workflows/test.yml/badge.svg)](https://github.com/a-b/gha-shepherd/actions/workflows/test.yml)
## Usage

This action abstracts claiming and unclaiming shepherd leases.

[.github/workflows/test.yml](.github/workflows/test.yml) provides a good starting point.

## Development

1. Open with VisualStudion Code
   - Check if [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension is installed.
1. Create [.secrets](.secrets) file with real API token.
   - `echo "API_TOKEN: $(shepherd create service-account gha-shepherd --json | jq -r .secret)" >> .secrets`
   - Local workflow dev runner [act](https://github.com/nektos/act) injects content of [.env](.env) and [.secrets](.secrets) into workflow execution context.
1. Open project inside the dev container.
1. Run `make run` to start.

## Deployment

1. To upload variables and secrets to the default remote repo for the current branch. **PROCEED WITH CARE** use `make repo-context-setup`. This will overwrite remote vaules with local from [.env](.env) and [.secrets](.secrets)

## ADR

1. Parameter validation happens inside shell script, inputs in [./action.yml] are maximum permissive.
