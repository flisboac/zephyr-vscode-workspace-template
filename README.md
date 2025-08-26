# zephyr-vscode-workspace-template

Template for a Visual Studio Code Workspace prepared for development of Zephyr projects.

Focus on using Devcontainers, for some dependency isolation.

Auto-generated files are git-ignored, and have a `*.tpl.sh` file that's responsible for generating them. Most files in this repository are templates. On first execution, those files are generated, and can be edited freely by the user (in general).

Extension recommendations are provided at workspace-level.


# Quickstart

First step is to initialize the repository on the host side.

```sh
# NOTE: The name you give to the cloned repository's folder
# will be the name of the workspace as a whole (e.g. for the Devcontainer).
git clone <REPOSITORY_URL> zephyr-workspace
cd ./zephyr-workspace
./scripts/host-init.sh
```

Then, open the workspace file [`zephyr.code-workspace`](/zephyr.code-workspace), generated as part of the initialization script.

Inside the container, you'll have access to West. Just initialize your project, just remember to leave it inside the folder indicated by the env-var `WEST_WORKSPACE_DIRNAME` (which, by default, points to [`projects/`](projects/) after initialization). Example (e.g. in an integrated terminal):

```sh
west init -m <OTHER_REPO_URL> "${WEST_WORKSPACE_DIRNAME}"

# Optionally, you can use a script that's prepared to ensure this command pattern:
./scripts/west-init-url.sh <OTHER_REPO_URL>
```

> TODO: Proper documentation, list all installed tools/extensions, etc.
