package ZMQ::Raw::Z85;
$ZMQ::Raw::Z85::VERSION = '0.34';
use strict;
use warnings;
use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Z85 - ZeroMQ Z85 methods

=head1 VERSION

version 0.34

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head2 encode( $decoded )

Encode C<$decoded>. The length of C<$decoded> shall be divisible by 4.

=head2 decode( $encoded )

Decode C<$encoded>. The length of C<$encoded> shall be divisible by 5.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Z85
