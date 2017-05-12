package cPanel::MemTest;

use strict;
use Carp ();
use vars qw(@EXPORT_OK @ISA $VERSION);

use AutoLoader;
require DynaLoader;
use Exporter ();

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(testallocate);

$VERSION = '0.3';

bootstrap cPanel::MemTest $VERSION;

1; 

__END__

=head1 NAME

cPanel::MemTest - Test Memory Allocation

=head1 VERSION

This document describes cPanel::MemTest version 0.0.2

=head1 SYNOPSIS

    use cPanel::MemTest;

    my $megs_to_allocate = 200;
    my $megs_allocated   = cPanel::MemTest::testallocate( $megs_to_allocate );
    die 'There was a problem allocating memory' if $megs_allocated != $megs_to_allocate;

=head1 DESCRIPTION

If you know you'll be running a memory intensive script it can be nice to be able to see 
if there is enough memory first instead of hitting a memory limit partway 
through and failing with little or no control over it.

=head1 INTERFACE 

=head2 testallocate()

This exportable function takes one argument: the number of megabytes to try and allocate betwen 1 and 1024

It returns the number of allocated megabytes.

If they are not the same then the allocation had issues ( see SYNOPSIS )

=head1 DIAGNOSTICS

=over

=item C<< Unable to allocate %d Megabytes of memory (Invalid Argument) >>

Invalid argument was passed to testallocate() (IE it is not 1 .. 1024)

=item C<< Error while allocating memory! %d Megabytes already allocated >>

There was not enough free memory left to allocate the amount you requested.

=back

=head1 CONFIGURATION AND ENVIRONMENT

cPanel::MemTest requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cpanel-memtest@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

Semi related to this topic is limiting memory via L<BSD::Resource>

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, cPanel, Inc. All rights reserved.

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
