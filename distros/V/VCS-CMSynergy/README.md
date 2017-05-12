# VCS::CMSynergy -- Perl interface to IBM Rational Synergy

This module is a Perl interface to **IBM Rational Synergy** (at various
times also known as Continuus/CM, CM Synergy or Teleogic SYNERGY/CM),
a change and configuration management system from IBM.
It is implemented on top of the Synergy CLI,
hence you **must have the command line client ("ccm") installed** to use it.

## BUILDING

Unpack the distribution, change to its top level directory, and then
```
perl Makefile.PL
make
```

## TESTING

Make sure that the Synergy command client is installed and working:

- check your setting of the CCM_HOME environment variable
- test the installation with
```
$CCM_HOME/bin/ccm version
```

Run the tests with
```
make test
```

If everything looks OK, install the module with
```
make install
```

## COPYRIGHT AND LICENSE

The VCS::CMSynergy module was written by Roderich Schupp, <schupp@argumentum.de>
Copyright (c) 2001-2015 argumentum GmbH, 
<http://www.argumentum.de>.  All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


