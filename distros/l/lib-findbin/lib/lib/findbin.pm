package lib::findbin;

use strict;
use warnings;
use FindBin ();
use lib     ();

$lib::findbin::VERSION = '0.2';

sub import {
    shift;
    lib->import( map { "$FindBin::Bin/$_" } ( @_ ? @_ : qw(lib ../lib) ) );
}

sub unimport {
    shift;
    lib->unimport( map { "$FindBin::Bin/$_" } ( @_ ? @_ : qw(lib ../lib) ) );
}

1;

__END__

=encoding utf-8

=head1 NAME

lib::findbin - add paths to @INC relative to the directory the script resides in

=head1 VERSION

This document describes lib::findbin version 0.2

=head1 SYNOPSIS

These are all equivalent:

    use FindLib;
    use lib "$FindBin::Bin/lib", $FindBin::Bin/..lib";

    use lib::findbin;

    use lib::findbin qw(lib ../lib);

    use FindLib;
    no lib "$FindBin::Bin/lib", $FindBin::Bin/..lib";

    no lib::findbin;

    no lib::findbin qw(lib ../lib);

=head1 DESCRIPTION

All this does is encapsulate simple logic we tend to do over and over and over. Its not terribly magical just simplifies things a little.

=head1 INTERFACE 

=head2 import()

It take a list of paths relative to the directory the script is in and adds them to @INC as absolute paths. (Using FindBin for that).

That list defaults to (lib ../lib) if no paths are given.

Typically called implicitly via use();

=head2 unimport()

It take a list of paths relative to the directory the script is in and adds them to @INC as absolute paths. (Using FindBin for that).

That list defaults to (lib ../lib) if no paths are given.

Typically called implicitly via no();

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

lib::findbin requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<FindBin>, L<lib>

=head1 SEE ALSO

L<lib::tiny>, L<lib::tiny::findbin>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lib-findbin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
