URL::Google::GURL - perl bindings for the google url library
============================================================

This project provides basic perl bindings for some portions of the standards compliant, high performance url parsing library, google-url. This project currently only exposes select portions of the GURL class that is part of this library. This is a convenient high-level abstraction that is useful for decomposing and validating urls.

The google-url project is hosted [here](http://code.google.com/p/google-url/). We have included the necessary source code here for convenient building of the module and will endeavor to keep the sources up to date with the source project<sup>\**</sup>.

<sub>\** - the source is current to r183 of the google-url project</sub>

Basic build instructions
-------------------------

clone the repository and cd to the project directory. Then:

    perl Build.PL
    ./Build
    prove -b -l -v (to run tests)

Build prerequisites
-------------------

There are several prerequisites required to build/install. The following perl modules must be installed (all are available from CPAN):

* Module::Build::WithXSpp
* ExtUtils::Typemaps::Default
* Devel::CheckLib

The [ICU library - ICU4C](http://site.icu-project.org/download) is also required for building and installing. If precompiled packages are availble for your system, that is the easiest way to install (be sure to include the development headers). Otherwise, you can consider using one of the precompiled binary packages available on the project site or you can build from source.

The build script included here attempts to verify that the ICU libs are installed. It will exit without generating its artifacts if the check fails.


