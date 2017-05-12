package WSST::SchemaParser;

use strict;
use WSST::Schema;

our $VERSION = '0.1.1';

sub types;

sub parse;

=head1 NAME

WSST::SchemaParser - SchemaParser interface of WSST

=head1 DESCRIPTION

SchemaParser is interface of schema file parser.

=head1 METHODS

=head2 types

Returns file types supported by parser.

=head2 parse

Parses schema file, and returns Schema object.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
