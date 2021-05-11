# **V** version 0.14

This module uses stolen code from
[`Module::Info`](https://metacpan.org/pod/Module::Info) to find the location
and version of the specified module(s). It prints them and exit()s.

It works by definening `import()` and is based on an idea from Michael Schwern
on the perl5-porters list. See [the
discussion](https://www.nntp.perl.org/group/perl.perl5.porters/2002/01/msg51007.html)

```
    $ perl -MV=CPAN
```

or if you want more than one package

```
    $ perl -MV=CPAN,V
```

# INSTALLATION

To install this module type the following commands:

-   `perl Makefile.PL`
-   `make test`
-   `make install`

# DEPENDENCIES

This module requires no other modules or libraries (exept
[`Test::More`](https://metacpan.org/pod/Test::More) for the test-suite).

# SEE ALSO

To get more info on the programming interface see [`perldoc
V`](https://metacpan.org/pod/V)

# COPYRIGHT

&copy; 2002 Abe Timmerman <abeltje@cpan.org>. All rights reserved.

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

