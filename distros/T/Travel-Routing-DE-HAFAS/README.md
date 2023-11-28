# hafas - Commandline Public Transit Routing Interface

**hafas** is a commandline client and Perl module for HAFAS pulic transit
routing interfaces. See the [Travel::Routing::DE::HAFAS homepage](https://finalrewind.org/projects/Travel-Routing-DE-HAFAS/) for details.

## Installation

You have three installation options:

* Installing the latest release from CPAN
* Installation from source
* Using a Docker image

Except for Docker, **hafas** is available in your PATH after installation.
You can run `hafas --version` to verify this. Documentation is available via
`man hafas`.

### Installation from CPAN

Travel::Routing::DE::HAFAS releases are published on the Comprehensive Perl
Archive Network (CPAN) and can be installed using standard Perl module tools
such as `cpanminus`.

Before proceeding, ensure that you have standard build tools (i.e. make,
pkg-config and a C compiler) installed. You will also need the following
libraries with development headers:

* libssl
* zlib

Now, use a tool of your choice to install the module. Minimum working example:

```
cpanm Travel::Routing::DE::HAFAS
```

If you run this as root, it will install script and module to `/usr/local` by
default.

### Installation from Source

In this variant, you must ensure availability of dependencies by yourself.
You may use carton or cpanminus with the provided `Build.PL`, Module::Build's
installdeps command, or rely on the Perl modules packaged by your distribution.

To check whether dependencies are satisfied, run:

```
perl Build.PL
```

If it complains about "... is not installed" or "ERRORS/WARNINGS FOUND IN
PREREQUISITES", it is missing dependencies.

Once all dependencies are satisfied, use Module::Build to build, test and
install the module. Testing is optional -- you may skip the "Build test"
step if you like.

If you downloaded a release tarball, proceed as follows:

```
./Build
./Build test
sudo ./Build install
```

If you are using the Git repository, use the following commands:

```
./Build
./Build manifest
./Build test
sudo ./Build install
```

If you do not have superuser rights or do not want to perform a system-wide
installation, you may leave out `Build install` and use **hafas** from the
current working directory.

With carton:

```
carton exec hafas --version
```

Otherwise (also works with carton):

```
perl -Ilocal/lib/perl5 -Ilib bin/hafas --version
```

### Running hafas-m via Docker

A hafas image is available on Docker Hub. It is intended for testing
purposes: due to the latencies involved in spawning a container for each
hafas invocation, it is less convenient for day-to-day usage.

Installation:

```
docker pull derfnull/hafas:latest
```

Use it by prefixing hafas commands with `docker run --rm
derfnull/hafas:latest`, like so:

```
docker run --rm derfnull/hafas:latest --version
```

Documentation is not available in this image. Please refer to the
[online hafas manual](https://man.finalrewind.org/1/hafas/) instead.
