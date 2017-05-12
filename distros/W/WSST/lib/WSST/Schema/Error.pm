package WSST::Schema::Error;

use strict;
use base qw(WSST::Schema::Node);
__PACKAGE__->mk_accessors(qw(values error_message error_message_map));

use constant BOOL_FIELDS => qw(multiple nullable error_message);

our $VERSION = '0.1.1';

=head1 NAME

WSST::Schema::Error - Schema::Error class of WSST

=head1 DESCRIPTION

This class represents the error elements of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 values

Accessor for the values.

=head2 error_message

Accessor for the service name.

=head2 error_message_map

Accessor for the service name.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
