package WSST::SchemaParser::YAML;

use strict;
use base qw(WSST::SchemaParser);
use YAML ();

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $self = {};
    return bless($self, $class);
}

sub types {
    return [".yml", ".yaml"];
}

sub parse {
    my $self = shift;
    my $path = shift;
    
    my $data = YAML::LoadFile($path);
    
    return WSST::Schema->new($data);
}

=head1 NAME

WSST::SchemaParser::YAML - YAML SchemaParser class of WSST

=head1 DESCRIPTION

This class is YAML schema parser.

=head1 METHODS

=head2 new

Constructor.

=head2 types

Returns [".yml", ".yaml"]

=head2 parse

Parses YAML schema file, and returns Schema object.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
