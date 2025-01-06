# **V**

This module uses stolen code from
[`Module::Info`](https://metacpan.org/pod/Module::Info) to find the location
and version of the specified module(s). It prints them and exit()s.

It works by definening `import()` and is based on an idea from Michael Schwern
on the perl5-porters list. See [the
discussion](https://www.nntp.perl.org/group/perl.perl5.porters/2002/01/msg51007.html)

```bash
🐧 perl -MV=CPAN
CPAN
        /pro/lib/perl5/site_perl/5.40.0/CPAN.pm: 2.38
        /pro/lib/perl5/5.40.0/CPAN.pm: 2.36
```

or if you want more than one package

```bash
🐧 perl -MV=CPAN,V
```

As of version **0.17** it will show all `package`s and `class`es in a file with
a version. (If one wants *all* packages/classes in the files, set the
environment variable `PERL_V_SHOW_ALL`)

```bash
🐧 perl -MV=SOAP::Lite
SOAP::Lite
        /pro/lib/perl5/site_perl/5.40.0/SOAP/Lite.pm:
            SOAP::Lite: 1.27
            SOAP::Client: 1.27
```

# INSTALLATION

To install this module type the following commands:

-   `perl Makefile.PL`
-   `make test`
-   `make install`

# DEPENDENCIES

This module requires no extra modules or libraries from perl version 5.14.0
(exept [`Test::More`](https://metacpan.org/pod/Test::More),
[`Test::Warnings`](https://metacpan.org/pod/Test::Warnings),
[`Test::Fatal`](https://metacpan.org/pod/Test::Fatal) for the test-suite).

# SEE ALSO

To get more info on the programming interface see [`perldoc
V`](https://metacpan.org/pod/V)

# COPYRIGHT

&copy; 2002..2024 Abe Timmerman <abeltje@cpan.org>. All rights reserved.
&copy; 2024..2025 H.Merijn Brand <hmbrand@cpan.org>. All rights reserved.

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
