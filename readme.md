# Docker LDC Darwin

This repository contains a Dockerfile for building a Docker image which has all
the necessary tools to cross-compile D applications targeting macOS x86-64.

## Features

* Uses Apple's ld64 linker so all features that are being used when linking on
    macOS should work. No reliance on custom linkers that need to be kept up to
    date with the system linker
* Ships with the full macOS SDK (for macOS version 10.15.4)
* No reliance on hacks like allowing undefined symbols when linking
* Minimal Docker image. Only the exact files that are required to run the
    compiler and linker are included. Not even a shell is included
* The Docker image, all tools and resources are fully reproducible and automated.
    No manual steps involved of uploading to random cloud storage accounts

The following tools are included:

* dub
* ldc2
* ldmd2
* rdmd
* ld64 (linker)
* clang (C compiler, used for linking)

## Building

### Prerequisites

* [git](https://git-scm.com)
* [Docker](https://www.docker.com)

### Building the Docker Image

Follow the steps below to build the Docker images by running the commands in
the terminal:

1. Clone the git repository:
    ```
    git clone https://github.com/d-cross-compiler/docker-ldc-darwin && cd docker-ldc-darwin
    ```
1. Build the Docker image:
    ```
    docker build -t ldc-x86_64-apple-macos .
    ```

### Specifying the Compiler Version

By default the Docker image will include LDC version 1.25.1 (see
[Dockerfile](/Dockerfile#L3) for an up to date version). To include a different
version of LDC, add the `--build-arg` flag when building the image:

```
docker build --build-arg LDC_VERSION=1.24.0 -t ldc-x86_64-apple-macos .
```

## Usage

By default, the `ldc2` compiler will be invoked.

### Compiling Hello World

Compile Hello World:

```
$ uname
Darwin
$ cat <<EOF > main.d
import std;

void main()
{
    writeln("Hello World");
}
EOF
$ docker run --rm -v "$(pwd):/work" ldc-x86_64-apple-macos main.d
$ ./main
Hello World
```

#### Breakdown of the `docker` Command

* The `run` command will create and run a Docker container
* The `--rm` flag will remove the container after it has finished running
* The `-v "$(pwd):/work"` flag will mount a directory from the host inside the
    container. The part before `:` is the path to the host directory to mount.
    The part after `:` is the target path inside the container. `/work` is the
    default working directory for the container
* `ldc-x86_64-apple-macos` is the name of the Docker image to create the
    container from
* Any flags that should be passed to the `docker` command must be passed before
    the name of the Docker image
* Anything after the name of the Docker image are arguments that will be passed
    to the entrypoint of the Docker container. The default entrypoint is the
    compiler (`ldc2`)

### Passing Flags to the Compiler

To pass flags to the compiler, just pass them after the Docker image:

```
$ cat <<EOF > main.d
import std;

void main()
{
    debug
        writeln("Debug Hello World");
    else
        writeln("Regular Hello World");
}
EOF
$ docker run --rm -v "$(pwd):/work" ldc-x86_64-apple-macos main.d --d-debug
$ ./main
Debug Hello World
```

#### Specifying the Minimum Deployment Target

The default minimum deployment target is 10.9. That means the executable that is
produced will run on macOS 10.9 or later. To change this, add the
`-mmacosx-version-min` C compiler flag:

```
$ cat <<EOF > main.d
import std;

void main()
{
    writeln("Hello World");
}
EOF
$ docker run --rm -v "$(pwd):/work" ldc-x86_64-apple-macos main.d -Xcc=-mmacosx-version-min=10.15
$ ./main
Hello World
```

### Invoking Other Tools

To invoke another tool than the compiler, use the `--entrypoint` flag:

```
$ cat <<EOF > main.d
import std;

pragma(msg, "compile time");

void main()
{
    writeln("Hello World");
}
EOF
$ docker run --rm --entrypoint rdmd -v "$(pwd):/work" ldc-x86_64-apple-macos --build-only main.d
compile time
compile time
$ ./main
Hello World
```
