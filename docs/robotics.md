# Robotics (optional)

[ROS 2](https://docs.ros.org/), [Gazebo](https://gazebosim.org/), and
[Isaac Sim](https://developer.nvidia.com/isaac-sim) are **opt-in**. They are
large, Ubuntu/NVIDIA-skewed, and not every machine needs them — so they are
never installed by `./bootstrap.sh all`.

Installers live under `installers/optional/`.

## Platform matrix

| Stack | Ubuntu 24.04 + NVIDIA | macOS |
|---|---|---|
| ROS 2 Jazzy | yes | no (use an Ubuntu host) |
| Gazebo Harmonic | yes | no |
| Isaac Sim | yes (driver 535+, CUDA 12.x) | no |

## Install

```sh
./bootstrap.sh --dry-run ros2     # review
./bootstrap.sh ros2               # ROS 2 Jazzy + common robotics packages
./bootstrap.sh gazebo             # Gazebo Harmonic + ros_gz bridge (needs ROS 2)
./bootstrap.sh isaac              # check GPU/CUDA; print Omniverse Launcher steps
```

Override pins when needed:

```sh
ROS_DISTRO=jazzy ./bootstrap.sh ros2
ROS_DISTRO=jazzy GZ_DISTRO=harmonic ./bootstrap.sh gazebo
```

## Activate ROS 2 (per shell)

Do **not** add `source /opt/ros/.../setup.bash` to tracked `.bashrc` /
`.zprofile`. That injects ROS's Python and paths into every shell and fights
[uv](https://docs.astral.sh/uv/).

Use the helper (Linux only, from `shell/functions.linux.sh`):

```sh
ros2-env          # default: jazzy
ros2-env jazzy    # explicit
```

For a robotics workspace, source from that project's `.envrc` instead so
direnv activates ROS only inside that directory:

```sh
# example .envrc in a ROS workspace
source /opt/ros/jazzy/setup.bash
# … then uv/venv as needed for non-ROS Python tools
```

A dedicated robotics box that *always* wants ROS can put `ros2-env` in
untracked `~/.shell.local`.

## Coexistence with uv

- Outside `ros2-env` / a robotics `.envrc`: uv owns Python (see
  [workflow.md](workflow.md)).
- Inside a sourced ROS shell: use ROS tooling (`ros2`, `colcon`) as usual;
  do not assume the same `python3` as your uv project venvs.
- Keep project application code on uv; treat ROS workspaces as their own
  environment.

## Isaac Sim

`./bootstrap.sh isaac` verifies Ubuntu, NVIDIA driver (≥535), and CUDA
(`nvcc`), then prints Omniverse Launcher steps. The Launcher needs a GUI and
an NVIDIA Developer login — it cannot be fully automated here.

## Doctor

`./bootstrap.sh doctor` reports whether ROS / Gazebo / Omniverse paths are
present. Missing extras are informational, not failures.
