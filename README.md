# runner-images

Docker images for [Gitea Actions](https://docs.gitea.com/usage/actions/overview) runners (`act_runner`),
rebuilt weekly so they keep picking up .NET patches and OS updates.

## `ghcr.io/lucas7yoshi/runner-dotnet`

| | |
|---|---|
| Base | `mcr.microsoft.com/dotnet/sdk:11.0-resolute` (Ubuntu 26.04, includes ICU) |
| .NET SDKs | 11.0 and 10.0, side by side in `/usr/share/dotnet` |
| Node.js | current LTS (needed by JavaScript actions such as `actions/checkout`) |
| Tools | `git`, `zip`, `unzip`, `openssh-client`, `curl`, `ca-certificates`, `jq` |

Tags: `latest`, plus a dated `YYYYMMDD` tag for every build so you can pin or roll back.

Every build is smoke tested before it is pushed: both SDKs are listed, and a console app
is built and run with invariant globalization **off**, so a missing ICU fails the build.

### Use as an act_runner label

In the runner's `config.yaml`:

```yaml
runner:
  labels:
    - "ubuntu-latest-dotnet:docker://ghcr.io/lucas7yoshi/runner-dotnet:latest"
container:
  force_pull: true   # pick up new :latest builds automatically
```

Then in a workflow:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest-dotnet
    steps:
      - uses: actions/checkout@v4
      - run: dotnet build -c Release
```

No `actions/setup-dotnet` step is needed.
