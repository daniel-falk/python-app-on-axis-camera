# Rapid development using *python* applications in Axis cameras

Developing ACAPs (*AXIS Camera Application Platform*) applications, or any other cross compiled edge applications, can be a significant time investment. When developing computer vision software or analytics applications it is useful to be able to do fast prototyping and reduce the delay between an idea and use case driven feed back. This repository aims to show a quick and simple way to develop applications in *python* and run them in the camera. The aim is not to show a production ready process or a
best practice solution, but rather a simple prototyping environment to get started with a powerful high level language. 

This solution combines a pre-compiled *python* binary installed in an emulated debian enviroment with a cross compilation tool chain in the official *AXIS ACAP SDK* *docker* image. This allows rapid installation of open source *python* packages from binary distributions (with no need to cross compile) with the ability to cross compile external C modules which are dependent on the *AXIS ACAP SDK* libraries (such as video capture or accelerated CNN inference).

## Background

### Emulated *ARM* environment in debian *docker* container

The first step in the process is to use an emulated target environment such that we can use `apt-get install` to install binaries and shared libraries and `pip install` to install open source (or internal) *python* packages. The main downside of running an emulated environment is that it is very slow. Installing the *python* language and interpreter together with open source libraries such as numpy can take somewhere in the order of 15-60 minutes. This step is however only needed once as the *docker*
build scripts will cache the progress unless you touch any dependencies before this layer. I.e. you can add new requirements and rebuild the container using the *python* installation from the *docker* cache. This is all automatically handled by the *docker* daemon.

The build process in this repository assumes that *qemu* is configured such that *docker* can run containers with binaries compiled for the *ARM* architecture. This can be setup using just two commands:
```bash
apt-get install qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Cross compilation environment

Trying to compile *python* packages that relies on external C modules (such as e.g. the *Pillow* package) but does not have a binary distribution pre-compiled for the *ARM* architecture can take ours or more in the emulated *docker* environment. Therefore we perform the second part of the build process in a native *docker* container where a cross compiler is installed. Some modules (e.g. wrappers for the video capture interface) are relient on Axis specific C libraries, therfore the second build stage is
based on the official *AXIS ACAP SDK* container.

### Deployment of *python* binaries

The example application in this repository is based on the *python3-minimal* distribution. This distribution together with a few *python* modules such as numpy consumes in the range of 100-150 MB of storage. In a rapid prototyping setting there should not be a need to optimize the distribution footprint or limit the number of used libraries. Therefore using either an SD-card in the camera or a *NFS* (*Network File System*) solution, as is used in this project, is recommended. Axis' camera's comes with
*NFS* support out of the box. Using either a *NAS* (*Network-Attached Storage*) on the same network as the camera and the developer computer or a *Samba* server installed directly in the developer computer makes prototype deployment easy.

The downside with deploying the *python* interpreter and dependencies to the *NFS* storage is that the start-up time (when loading the binaries into memory) is extremely slow. The runtime impact, after loading the binaries, is however small.

## Building, deploying and running the application

### Pre-requirements

Make sure you have a Linux environment with *docker* installed. Make sure you can run emulated containers by following the instructions in 'Emulated *ARM* environment in debian *docker* container'.

You need an *ARMv7* based Axis camera (e.g. with the *S2L* SoC). The hostname of the camera is set to `axiscam` in the `Makefile`, you can configure this in the `~/.ssh/config` file:
```
Host axiscam
    HostName 192.168.0.90  # Set the camera IP
    User root  # Set the camera username
```

Make sure you have *SSH* enabled in the cameras' plain configuration and an *SSH* key uploaded to the camera so that you can *SSH* into it with no password using your developer machine.

Make sure you have a *NFS* share configured and mounted on both the developer machine and the camera (as configured from the Storage meny in the System tab in the camera's web GUI). If needed, adopt the paths in the Makefile to reflect the path where the *NFS* share is mounted.

### Build the development environment

This is the slowest step, we will now do a multi stage *docker* build where the first step is emulated and installs the binary distributions, including *python*. In the second stage the *python* related headers are copied to the SDK image.

```bash
make build-docker
```

We can now deploy the *python* interpreter to the *NFS* where the camera can access it:

```bash
make deploy-python
```

You can now run the *python* interpreter in the camera using the make target (or manually *SSH*:ing to the camera):
```bash
make run-interpreter
```

Try out something like this:
```
>>> import os
>>> os.uname()
posix.uname_result(sysname='Linux', nodename='axis-accc********', release='4.9.206-axis5', version='#1 PREEMPT Mon Jun 7 08:54:15 UTC 2021', machine='armv7l')
>>> import numpy as np
>>> np.cov(np.random.random((3,3)))
array([[0.01769723, 0.02763088, 0.01381708],
       [0.02763088, 0.08483894, 0.04148847],
       [0.01381708, 0.04148847, 0.02029964]])
```

### Build the *python* module (app)

The example *python* application in this repository uses a small C module which needs to be cross compiled for the camera architecture. The C code has been wrapped using the *Cython* module which is also the driver for the cross compilation using the *gcc* compiler. The application can be cross compiled using the command:

```bash
make build-app
```

This command builds the C modules which needs to be compiled. The *python* code itself is architecture independent and does only need to be copied to the camera to run it. Copy the application to the camera using:

```bash
make deploy-app
```

The application can now be run using this command (or by *SSH*:ing to the camera):
```bash
make run-app
```

## Things to consider

There are some pitfalls when developing an application using this method:

* The precompiled binaries must not be compiled against a newer version of libc than what is deployed on the camera, therefore `arm32v7/ubuntu:bionic` is used as base for the emualted container in this example.
* Special care needs to be taken with the version of shared libraries (so-files) that are linked to 1) in the emulated builder container, 2) in the SDK builder container 3) that are dynamically loaded in the camera. The version of the *AXIS ACAP SDK* *docker* image used here is `axisecp/acap-sdk:3.4.2-armv7hf-ubuntu20.04` where the shared libraries are built agains the version of libraries that are supported in the *20.04 LTS* version of *ubuntu*.
* Using different versions of *python* when building the external modules and when importing them can cause problems. Ideally the version and the configure flags should be the same in both containers.
