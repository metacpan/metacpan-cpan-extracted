package ZMQ::Raw::Context;
$ZMQ::Raw::Context::VERSION = '0.32';
use strict;
use warnings;
use ZMQ::Raw;

=head1 NAME

ZMQ::Raw::Context - ZeroMQ Context class

=head1 VERSION

version 0.32

=head1 DESCRIPTION

A L<ZMQ::Raw::Context> represents a ZeroMQ context.

=head1 METHODS

=head2 new( )

Create a new ZeroMQ context.

=head2 set( $option, $value )

Set a ZeroMQ context option.

=head2 shutdown( )

Shutdown the ZeroMQ context. Context shutdown will cause any blocking operations
currently in progress on sockets open within the context to return immediately
with an error code of C<ETERM>. Any further operations on sockets open within
the context shall also fail with an erro code of C<ETERM>.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of ZMQ::Raw::Context
