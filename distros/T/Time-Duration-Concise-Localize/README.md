**Time-Duration-Concise-Localize**

Time::Duration::Concise::Localize is an another time utility, which converts your concise time string to time duration and it also localize it in your language.

This module uses Time::Duration::Concise as base module to convert concise string to duration


[![Build Status](https://travis-ci.org/binary-com/perl-Time-Duration-Concise-Localize.svg?branch=master)](https://travis-ci.org/binary-com/perl-Time-Duration-Concise-Localize)
[![codecov](https://codecov.io/gh/binary-com/perl-Time-Duration-Concise-Localize/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Time-Duration-Concise-Localize)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-Time-Duration-Concise-Localize.png)](https://gitter.im/binary-com/perl-Time-Duration-Concise-Localize)

NOTE

Our concise time interval can also have decimal values

example:

    1.5h
    1d3.5h10s


SYNOPSIS

    use Time::Duration::Concise::Localize;

    my $duration = Time::Duration::Concise::Localize->new(

        # concise time interval
        'interval' => '1.5h',

        # Local in which string will be translated
        'locale' => 'hi',

    );

    # gets you localized time duration string
    $duration->as_string;

    # In Arabic
    $duration->locale('ar');
    $duration->as_string();

    # In Chinese - China
    $duration->locale('zh_cn');
    $duration->as_string();

    ...

CONCISE FORMAT

The format is an integer followed immediatley by its duration identifier.  White-space will be ignored.
    
  The following table explains the format.

    | identifier | duration |
    |------------|----------|
    | d          | day      |
    | h          | hour     |
    | m          | minute   |
    | s          | second   |
    


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Time::Duration::Concise::Localize
    perldoc Time::Duration::Concise

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Duration-Concise-Localize

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Time-Duration-Concise-Localize
        http://annocpan.org/dist/Time-Duration-Concise

    CPAN Ratings
        http://cpanratings.perl.org/d/Time-Duration-Concise-Localize
        http://cpanratings.perl.org/dist/Time-Duration-Concise

    Search CPAN
        http://search.cpan.org/dist/Time-Duration-Concise-Localize/
        http://search.cpan.org/dist/Time-Duration-Concise


LICENSE AND COPYRIGHT

Copyright (C) 2014 Binary.com

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

