# efa-m - Commandline Public Transit Departure Monitor

efa-m is a commandline client and Perl module for EFA public transit departure
interfaces such as [efa.vrr.de](https://efa.vrr.de/vrr/XSLT_DM_REQUEST). See
the [Travel::Status::DE::VRR
homepage](https://finalrewind.org/projects/Travel-Status-DE-VRR/) for details.

## Installation

efa-m is available as
[perl-travel-status-de-vrr-git](https://aur.archlinux.org/packages/perl-travel-status-de-vrr-git/)
in the archlinux User Repository (AUR).

For other distributions, you have four installation options:

* Nightly `.deb` builds for Debian-based distributions
* Installing the latest release from CPAN
* Installation from source
* Using a Docker image

Except for Docker, __efa-m__ is available in your PATH after installation. You
can run `efa-m --version` to verify this. Documentation is available via
`man efa-m`.

### Nightly Builds for Debian

[lib.finalrewind.org/deb](https://lib.finalrewind.org/deb) provides Debian
packages of both development and release versions. Note that these are not part
of the official Debian repository and are not covered by its quality assurance
process.

To install the latest release, run:

```
wget https://lib.finalrewind.org/deb/libtravel-status-de-vrr-perl_latest_all.deb
sudo dpkg -i libtravel-status-de-vrr-perl_latest_all.deb
sudo apt --fix-broken install
rm libtravel-status-de-vrr-perl_latest_all.deb
```

For a (possibly broken) development snapshot of the Git master branch, run:

```
wget https://lib.finalrewind.org/deb/libtravel-status-de-vrr-perl_dev_all.deb
sudo dpkg -i libtravel-status-de-vrr-perl_dev_all.deb
sudo apt --fix-broken install
rm libtravel-status-de-vrr-perl_dev_all.deb
```

Note that dpkg, unlike apt, does not automatically install missing
dependencies. If a dependency is not satisfied yet, `dpkg -i` will complain
about unmet dependencies and bail out. `apt --fix-broken install` installs
these dependencies and also silently finishes the Travel::Status::DE::VRR
installation.

Uninstallation works as usual:

```
sudo apt remove libtravel-status-de-vrr-perl
```

### Installation from CPAN

Travel::Status::DE::VRR releases are published on the Comprehensive Perl
Archive Network (CPAN) and can be installed using standard Perl module tools
such as `cpanminus`.

Before proceeding, ensure that you have standard build tools (i.e. make,
pkg-config and a C compiler) installed. You will also need the following
libraries with development headers:

* libssl
* libxml2
* zlib

Now, use a tool of your choice to install the module. Minimum working example:

```
cpanm Travel::Status::DE::VRR
```

If you run this as root, it will install script and module to `/usr/local` by
default.

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
./Build
./Build manifest
./Build test
sudo ./Build install
```

If you do not have superuser rights or do not want to perform a system-wide
installation, you may leave out `Build install` and use **efa-m** from the
current working directory.

With carton:

```
carton exec efa-m --version
```

Otherwise (also works with carton):

```
perl -Ilocal/lib/perl5 -Ilib bin/efa-m --version
```

### Running efa-m via Docker

An efa-m image is available on Docker Hub. It is intended for testing purposes:
due to the latencies involved in spawning a container for each efa-m
invocation, it is less convenient for day-to-day usage.

Installation:

```
docker pull derfnull/efa-m:latest
```

Use it by prefixing efa-m commands with `docker run --rm
derfnull/efa-m:latest`, like so:

```
docker run --rm derfnull/efa-m:latest --version
```

Documentation is not available in this image. Please refer to the
[online efa-m manual](https://man.finalrewind.org/1/efa-m/) instead.
