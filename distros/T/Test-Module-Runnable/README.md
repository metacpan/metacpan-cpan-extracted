# README #

Base class for runnable unit tests using Moose introspection
and a user-defined pattern for subtest routines.

## What is this repository for? ##

* This is the source code for Test::Module::Runnable

## How do I get set up? ##

* The easiest way to install this package is via the cpan CLI;
  Simply type install Test::Module::Runnable
* Alternatively, Debian packages are available via the author's website.

## Contribution guidelines ##

### Writing tests (internal) ###

nb. not to be confused with writing your own tests, for your own code.

All tests line under the t/ directory.

All tests are based on the framework itself, either as a subclass, or via the 'sut',
("system under test") member attribute.  We keep to the standard 'test' pattern,
unless testing the pattern code itself.

### Code review ###

* SourceHut [discuss](https://lists.sr.ht/~m6kvm/libtest-module-runnable-perl-discuss) mailing list

or using pull requests via the following sites:

* [BitBucket](https://bitbucket.org/2E0EOL/libtest-module-runnable-perl/pull-requests/)
* [GitHub](https://github.com/daybologic/libtest-module-runnable-perl/pulls)

## Other guidelines ##

We use the [Git](https://git-scm.com) source control system and the following mirrors are known to
be under the control of the official maintainer and can therefore be trusted to be legitimate and
may be used for first strata contributions:

* [BitBucket](https://bitbucket.org/2E0EOL/libtest-module-runnable-perl)
* [GitHub](https://github.com/daybologic/libtest-module-runnable-perl)
* [Sourcehut](https://git.sr.ht/~m6kvm/libtest-module-runnable-perl)

nb. although the project formerly used the [Mercurial](https://www.mercurial-scm.org/) version control system,
this is no longer supported.  If you have contributions in that format, please generate a diff and apply it to
the new Git tree before submitting a pull request.

## Contacting us ##

* [Duncan Ross Palmer](http://www.daybologic.co.uk/contact.php)
* [announce](https://lists.sr.ht/~m6kvm/libtest-module-runnable-perl-announce) mailing list
* [discuss](https://lists.sr.ht/~m6kvm/libtest-module-runnable-perl-discuss) mailing list

### Availability ###

The project is available for download from the following sites:
* [BitBucket](https://bitbucket.org/2E0EOL/libtest-module-runnable-perl)
* [CPAN](https://metacpan.org/pod/Test::Module::Runnable)
* [Daybo Logic](http://www.daybologic.co.uk/software.php?content=libtest-module-runnable-perl)
* [GitHub](https://github.com/daybologic/libtest-module-runnable-perl)
* [Sourcehut](https://git.sr.ht/~m6kvm/libtest-module-runnable-perl)

#### Direct download links ####

* [CPAN (.tar.gz)](https://cpan.metacpan.org/authors/id/D/DD/DDRP/Test-Module-Runnable-0.6.1.tar.gz)
* [Daybo Logic (.tar.gz)](http://downloads.daybologic.co.uk/Test-Module-Runnable-0.6.1.tar.gz)
* [Daybo Logic (Debian package)](http://downloads.daybologic.co.uk/libtest-module-runnable-perl_0.6.1_all.deb)
* [Sourcehut (.tar.gz)](https://git.sr.ht/~m6kvm/libtest-module-runnable-perl/archive/libtest-module-runnable-perl-0.6.1.tar.gz)
