[![MetaCPAN Release](https://badge.fury.io/pl/vars-i.svg)](https://metacpan.org/release/vars-i) [![Build Status](https://travis-ci.org/cxw42/Perl-vars-i.svg?branch=master)](https://travis-ci.org/cxw42/Perl-vars-i)
# NAME

vars::i - Perl pragma to declare and simultaneously initialize global variables.

# SYNOPSIS

    use Data::Dumper;
    $Data::Dumper::Deparse = 1;

    use vars::i '$VERSION' => 3.44;
    use vars::i '@BORG' => 6 .. 6;
    use vars::i '%BORD' => 1 .. 10;
    use vars::i '&VERSION' => sub(){rand 20};
    use vars::i '*SOUTH' => *STDOUT;

    BEGIN {
        print SOUTH Dumper [
            $VERSION, \@BORG, \%BORD, \&VERSION
        ];
    }

    use vars::i [ # has the same effect as the 5 use statements above
        '$VERSION' => 3.66,
        '@BORG' => [6 .. 6],
        '%BORD' => {1 .. 10},
        '&VERSION' => sub(){rand 20},
        '*SOUTH' => *STDOUT,
    ];

    print SOUTH Dumper [ $VERSION, \@BORG, \%BORD, \&VERSION ];

# DESCRIPTION

For whatever reason, I once had to write something like

    BEGIN {
        use vars '$VERSION';
        $VERSION = 3;
    }

or

    our $VERSION;
    BEGIN { $VERSION = 3; }

and I really didn't like typing that much.  With this package, I can say:

    use vars::i '$VERSION' => 3;

and get the same effect.

Also, I like being able to say

    use vars::i '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/);

    use vars::i [
     '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/),
     '$REVISION'=> '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $',
    ];

Like with `use vars;`, there is no need to fully qualify the variable name.
However, you may if you wish.

# NOTES

- Specifying a variable but not a value will succeed silently, and will **not**
create the variable.  E.g., `use vars::i '$foo';` is a no-op.

    Now, you might expect that `use vars::i '$foo';` would behave the same
    way as `use vars '$foo';`.  That would not be an unreasonable expectation.
    However, `use vars::i qw($foo $bar);` has a very different
    effect than does `use vars qw($foo $bar);`!  In order to avoid
    subtle errors in the two-parameter case, `vars::i` also rejects the
    one-parameter case.

- Trying to create a special variable is fatal.  E.g., `use vars::i '$@', 1;`
will die at compile time.
- The sigil is taken into account (context sensitivity!)  So:

        use vars::i '$foo' => [1,2,3];  # now $foo is an arrayref
        use vars::i '@bar' => [1,2,3];  # now @bar is a three-element list

# SEE ALSO

See [vars](https://metacpan.org/pod/vars), ["our" in perldoc](https://metacpan.org/pod/perldoc#our), ["Pragmatic Modules" in perlmodlib](https://metacpan.org/pod/perlmodlib#Pragmatic-Modules).

# VERSIONING

Since version 1.900000, this module is numbered using
[Semantic Versioning 2.0.0](https://semver.org),
packed in the compatibility format of `vX.Y.Z -> X.00Y00Z`.

This version supports Perl 5.6.1+.  If you are running an earlier Perl:

- Perl 5.6:

    Use version 1.10 of this module
    ([CXW/vars-i-1.10](https://metacpan.org/pod/release/CXW/vars-i-1.10/lib/vars/i.pm)).

- Pre-5.6:

    Use version 1.01 of this module
    ([PODMASTER/vars-i-1.01](https://metacpan.org/pod/release/PODMASTER/vars-i-1.01/lib/vars/i.pm)).

# DEVELOPMENT

This module uses [Minilla](https://metacpan.org/pod/Minilla) for release management.  When developing, you
can use normal `prove -l` for testing based on the files in `lib/`.  Before
submitting a pull request, please:

- make sure all tests pass under `minil test`
- add brief descriptions to the `Changes` file, under the `{{$NEXT}}` line.
- update the `.mailmap` file to list your PAUSE user ID if you have one, and
if your git commits are not under your `@cpan.org` email.  That way you will
be properly listed as a contributor in MetaCPAN.

# AUTHORS

D.H. <podmaster@cpan.org>

Christopher White <cxw@cpan.org>

## Thanks

Thanks to everyone who has worked on [vars](https://metacpan.org/pod/vars), which served as the basis for
this module.

# SUPPORT

Please report any bugs at [https://github.com/cxw42/Perl-vars-i/issues](https://github.com/cxw42/Perl-vars-i/issues).

You can also see the old bugtracker at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=vars-i](http://rt.cpan.org/NoAuth/Bugs.html?Dist=vars-i) for older bugs.

# LICENSE

Copyright (c) 2003--2019 by D.H. aka PodMaster, and contributors.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
