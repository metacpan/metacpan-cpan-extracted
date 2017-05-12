package WSST::SchemaParser::TEST;

use strict;
use base qw(WSST::SchemaParser);

our $VERSION = '0.1.0';

sub new {
    my $class = shift;
    my $self = {};
    return bless($self, $class);
}

sub types {
    return [".test"];
}

sub parse {
    my $self = shift;
    my $path = shift;
    return WSST::Schema->new();
}

1;
