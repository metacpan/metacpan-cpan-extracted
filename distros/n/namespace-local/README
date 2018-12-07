# NAME

namespace::local - Confine imports and/or functions to a given scope

# USAGE

## Confining imports and prototypes

    # normal code here
    {
        use namespace::local;
        use Some::Crazy::DSL;
    };
    # symbol table restored

## Hiding private functions

    package My::Class;
    use Moo::Role;
    sub visible {
        # is available as $self->visible
    };

    use namespace::local -below;
    sub private {
        # only visible within this module
    };

## Hiding imports

Emulate `namespace::clean` by which this module was expired:

    use Lots::Of::Imports qw(do_this do_that frobnicate);
    use namespace::local -above;

    # do_this, do_that, and frobnicate are only visible until end of scope

# CONTENT OF THIS PACKAGE

* `lib` - the module itself

* `t` - tests

* `xt` - author tests

* `it` - integration tests involving Moo, Moose, overload & so on
(not required for installation)

* `example` - usage examples

# INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc namespace::local

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=namespace-local

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/namespace-local

    CPAN Ratings
        http://cpanratings.perl.org/d/namespace-local

    Search CPAN
        http://search.cpan.org/dist/namespace-local/

# LICENSE AND COPYRIGHT

Copyright (C) 2018 Konstantin S. Uvarin

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

