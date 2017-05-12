package XML::Validator::Schema::AttributeLibrary;
use strict;
use warnings;

use XML::Validator::Schema::Util qw(XSD _err);
use base 'XML::Validator::Schema::Library';

=head1 NAME

XML::Validator::Schema::AttributeLibrary

=head1 DESCRIPTION

Internal module used to implement a library of attributes.

=cut

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(what => 'attribute', @_);

    return $self;
}



1;

