# dbris-m - Command Line Interface to bahn.de Public Transit Services

**dbris-m** is a commandline client and Perl module for bahn.de public transit
interfaces. It can show the arrivals/departures at a specific public transit
stop, give details on individual journeys, and look up stops by name or geo
coordinates. It supports text and JSON output.

This README documents installation of dbris-m and the associated
Travel::Status::DE::DBRIS Perl module.  See the [Travel::Status::DE::DBRIS
homepage](https://finalrewind.org/projects/Travel-Status-DE-DBRIS) and
[dbris-m manual](https://man.finalrewind.org/1/dbris-m) for a feature overview
and usage instructions.

## Installation

You have five installation options:

* `.deb` releases for Debian-based distributions
* finalrewind.org APT repository for Debian-based distributions
* Installing the latest release from CPAN
* Installation from source
* Using a Docker image

Except for Docker, __dbris-m__ is available in your PATH after installation.
You can run `dbris-m --version` to verify this. Documentation is available via
`man dbris-m`.

### Release Builds for Debian

[lib.finalrewind.org/deb](https://lib.finalrewind.org/deb) provides Debian
packages of all release versions. Note that these are not part of the official
Debian repository and are not covered by its quality assurance process.

To install the latest release, run:

```
wget https://lib.finalrewind.org/deb/libtravel-status-de-dbris-perl_latest_all.deb
sudo apt install ./libtravel-status-de-dbris-perl_latest_all.deb
rm libtravel-status-de-dbris-perl_latest_all.deb
```

Uninstallation works as usual:

```
sudo apt remove libtravel-status-de-dbris-perl
```

### finalrewind.org APT repository

[lib.finalrewind.org/apt](https://lib.finalrewind.org/apt) provides an APT
repository with Debian packages of the latest release versions. Note that this
is not a Debian repository; it is operated under a best-effort SLA and if you
use it you will have to trust me not to screw up your system with bogus
packages. Also, note that the packages are not part of the official Debian
repository and are not covered by its quality assurance process.

To set up the repository and install the latest Travel::Status::DE::DBRIS
release, run:

```
curl -s https://finalrewind.org/apt.asc | sudo tee /etc/apt/trusted.gpg.d/finalrewind.asc
echo 'deb https://lib.finalrewind.org/apt stable main' | sudo tee /etc/apt/sources.list.d/finalrewind.list
sudo apt update
sudo apt install libtravel-status-de-dbris-perl
```

Afterwards, `apt update` and `apt upgrade` will automatically install new
Travel::Status::DE::DBRIS releases.

Uninstallation of Travel::Status::DE::DBRIS works as usual:

```
sudo apt remove libtravel-status-de-dbris-perl
```

To remove the APT repository from your system, run:

```
sudo rm /etc/apt/trusted.gpg.d/finalrewind.asc \
        /etc/apt/sources.list.d/finalrewind.list
```

### Installation from CPAN

Travel::Status::DE::DBRIS releases are published on the Comprehensive Perl
Archive Network (CPAN) and can be installed using standard Perl module tools
such as `cpanminus`.

Before proceeding, ensure that you have standard build tools (i.e. make,
pkg-config and a C compiler) installed. You will also need the following
libraries with development headers:

* libssl
* zlib

Now, use a tool of your choice to install the module. Minimum working example:

```
cpanm Travel::Status::DE::DBRIS
```

If you run this as root, it will install script and module to `/usr/local` by
default. There is no well-defined uninstallation procedure.

### Installation from Source

In this variant, you must ensure availability of dependencies by yourself.
You may use carton or cpanminus with the provided `Build.PL`, Module::Build's
installdeps command, or rely on the Perl modules packaged by your distribution.
On Debian 10+, all dependencies are available from the package repository.

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
git submodule update --init
./Build
./Build manifest
./Build test
sudo ./Build install
```

Note that system-wide installation does not have a well-defined uninstallation
procedure.

If you do not have superuser rights or do not want to perform a system-wide
installation, you may leave out `Build install` and use **dbris-m** from the
current working directory.

With carton:

```
carton exec dbris-m --version
```

Otherwise (also works with carton):

```
perl -Ilocal/lib/perl5 -Ilib bin/dbris-m --version
```

### Running dbris-m via Docker

A dbris-m image is available on Docker Hub. It is intended for testing
purposes: due to the latencies involved in spawning a container for each
dbris-m invocation, it is less convenient for day-to-day usage.

Installation:

```
docker pull derfnull/dbris-m:latest
```

Use it by prefixing dbris-m commands with `docker run --rm
derfnull/dbris-m:latest`, like so:

```
docker run --rm derfnull/dbris-m:latest --version
```

Documentation is not available in this image. Please refer to the
[online dbris-m manual](https://man.finalrewind.org/1/dbris-m/) instead.
