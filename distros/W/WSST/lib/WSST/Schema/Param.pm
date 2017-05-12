package WSST::Schema::Param;

use strict;
use base qw(WSST::Schema::Base);
__PACKAGE__->mk_accessors(qw(name title desc type require));

use constant BOOL_FIELDS => qw(require);

our $VERSION = '0.1.1';

=head1 NAME

WSST::Schema::Param - Schema::Param class of WSST

=head1 DESCRIPTION

This class represents the param element of schema.

=head1 METHODS

=head2 new

Constructor.

=head2 name

Accessor for the name.

=head2 title

Accessor for the title.

=head2 desc

Accessor for the desc.

=head2 type

Accessor for the type.

=head2 require

Accessor for the require.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
