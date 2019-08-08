# parent::versioned

Perl module to provide ```ISA``` inheritance with parent module version checking.
Behaves exactly the same as ```parent```, a core Perl module, but adds version checking.

## Getting Started

Install this module using your favorite CPAN installer:

```
cpanm parent::versioned
```

... or download the tarball, unpack it, and perform the mantra:


```
perl Makefile.PL
make
make test
make install
```

### Prerequisites

This module has no dependencies aside from Perl version 5.6.1 or newer.
(5.6.1 dates back to April 2001, so don't worry, you're covered.)

## Synopsis

```
use parent::versioned qw(Foo Bar::Baz); # Exactly like parent module.

use parent::versioned ['Foo' => 0.25], ['Bar::Baz' => 1.0]; # Require minimum versions.
```

## Description

Behavior is exactly the same as the core Perl module ```parent```, but with the capability
added for specifying minimum version numbers in parent modules.

This module passes the entire ```parent``` test suite, plus tests for the version extension.
Coverage is 100%.

## Author

* **David Oswald** <davido@cpan.org>

## Version control

* [parent::versioned on Github](https://github.com/daoswald/parent-versioned)

This module is a fork of ```parent```. Please see the module's POD for a description of its
ancestry and the authors who provided the foundation for this module.

## See also

* parent
* base
* perldoc perlmod

## License

This module is licensed under the same terms as Perl 5 iteslf.


