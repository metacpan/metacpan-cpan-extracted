package XML::Validator::Schema::ElementLibrary;
use strict;
use warnings;

use XML::Validator::Schema::Util qw(XSD _err);
use base 'XML::Validator::Schema::Library';

=head1 NAME

XML::Validator::Schema::ElementLibrary

=head1 DESCRIPTION

Internal module used to implement a library of elements.

=cut

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(what => 'element', @_);

    return $self;
}



1;

