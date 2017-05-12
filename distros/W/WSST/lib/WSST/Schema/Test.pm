package WSST::Schema::Test;

use strict;
use base qw(WSST::Schema::Base);
__PACKAGE__->mk_accessors(qw(type name params));

our $VERSION = '0.1.1';

=head1 NAME

WSST::Schema::Test - Schema::Test class of WSST

=head1 DESCRIPTION

This class represents the test element of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 type

Accessor for the type.

=head2 name

Accessor for the name.

=head2 params

Accessor for the params.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
