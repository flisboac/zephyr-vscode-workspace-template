# zephyr-vscode-workspace-template

Template for a Visual Studio Code Workspace prepared for development of Zephyr projects.

Focus on using Devcontainers, for some dependency isolation.

Auto-generated files are git-ignored, and have a `*.tpl.sh` file that's responsible for generating them. Most files in this repository are templates. On first execution, those files are generated, and can be edited freely by the user (in general).

Extension recommendations are provided at workspace-level.

This workspace template expects minimal Shell support (e.g. Dash, Bash, etc.) and the availability of a `docker` and `docker-compose` command. It's supposed to work on Linux and WSL, but no other platforms were tested. Having `git` and `diff` commands available is also highly recommended.


# Quickstart

The first step is to initialize the repository on the host side.

On the host, open a terminal, and execute:

```sh
# NOTE: The name you give to the cloned repository's folder
# will be the name of the workspace as a whole (e.g. for the Devcontainer).
# The name is assigned when calling `host-init.sh`.
git clone <REPOSITORY_URL> zephyr-workspace
cd ./zephyr-workspace
./scripts/host-init.sh
```

Then, open the workspace file [`zephyr.code-workspace`](/zephyr.code-workspace), generated as part of the initialization script.


## Choosing West Workspace's folder

Inside the container, you'll have access to West and Zephyr SDK.

It's recommended to initialize your project **inside the devcontainer**. It's expected that the initialized project is inside a subfolder of the VSCode Workspace's root folder, for which the name is indicated by the env-var `WEST_WORKSPACE_DIRNAME`. Effectively, `WEST_WORKSPACE_DIRNAME` will be West's Workspace root.

By default, this env-var points to [`projects/`](/projects/) after initialization, but you're free to change it by assigning `WEST_WORKSPACE_DIRNAME` prior to calling `scripts/host-init.sh`. For example, if you prefer that the name be `west-workspace`:

```sh
# Add the `--pristine` flag ig you've already generated the templates;
# note, however, that it'll OVERWRITE ALL templated files!
WEST_WORKSPACE_DIRNAME="west-workspace" ./scripts/host-init.sh --pristine
```

It's important to assign `WEST_WORKSPACE_DIRNAME` properly, as most scripts depend on its value to construct the path of projects and such.

Just be careful to not commit files in the folder indicated in `WEST_WORKSPACE_DIRNAME`. The purpose is to open each cloned repository in `WEST_WORKSPACE_DIRNAME` into the VSCode Workspace, and work with them separately. This way, each of them will be tracked by VSCode separately (in terms of Git, etc.). Because of that, the default `projects/` folder is automatically ignored via [`.gitignore`](/.gitignore); consider doing the same if you prefer a different subfolder name.


## Initializing West

Now, to initialize West proper, execute the following command (e.g. in an integrated terminal):

```sh
# Assuming your current folder (pwd)  is the VSCode Workspace's root folder.
#
# Replace "projects/" by your chosen folder.
#
# <OTHER_REPO_URL> is the URL of your repository.
#
# For correctness, you can also `source host.env`
# (or `. host.env`, for strict POSIX compatibility, e.g., dash, etc.),
# and replace "projects/" with "${WEST_WORKSPACE_DIRNAME}"
west init -m <OTHER_REPO_URL> projects/

# Optionally, you can use a script that's prepared to ensure this command pattern,
# i.e., using "${WEST_WORKSPACE_DIRNAME}":
./scripts/west-init-url.sh <OTHER_REPO_URL>
```


## Updating templated files

From time to time, templates may be updated. You can run `scripts/host-init.sh` on the host side again in order to know which templates have been changed. The script won't overwrite the already generated (but possibly older/different) files; instead, a `WARN` will be emitted on the CLI for each occurrence of an outdated file (e.g. in content, in generation time, etc.).

To force re-generation of files, you have three options:

1. Pass the flag `-p`/`--pristine`, which will regenerate ONLY the current templated file. If a dependent file is outdated, a warning will me emitted;
2. Pass the flag `-P`/`--pristine-all`, which will regenerate not only the current templated file, but ALL templated files for which this file depends on;
3. Assign `PRISTINE=1` when executing the command, which is equivalent to `--pristine-all`.

Example:

```sh
# Choose either the flag...
./scripts/host-init.sh -p
# ... or env-var assignment:
PRISTINE=1 ./scripts/host-init.sh
```

> NOTE: Assigning and/or exporting `PRISTINE=1` is the mechanism through which all scripts identify and/or propagate regeneration of files.


## Updating individual templated files

`scripts/host-init.sh` will update the whole project/workspace. Optionally, you can call and update specific files. Just search for files ending with `.tpl.sh` to know which are templated; liewise, remove this suffix to know the name of the generated file. Those `.tpl.;sh` files are executable POSIX Shell scripts.

For example, to change the Compose file used by the devcontainer, you can change `DEVCONTAINER_COMPOSE_FILE_NAME` in [`host.env`](/host.env) and regenerate [`devcontainer.json`](/.devcontainer/devcontainer.json) by executing:

```sh
# `--pristine` is important, to force re-generation.
./.devcontainer/devcontainer.json.tpl.sh --pristine
```

> TODO: Proper documentation, list all installed tools/extensions, etc.
