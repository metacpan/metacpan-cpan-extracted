package XML::Validator::Schema::ElementRefNode;
use strict;
use warnings;

use base 'XML::Validator::Schema::ElementNode';

use XML::Validator::Schema::Util qw(_err _attr);
use Carp qw(croak);

=head1 NAME

XML::Validator::Schema::ElementRefNode - an element reference node

=head1 DESCRIPTION

This is an internal module used by XML::Validator::Schema to represent
an element reference node.

=cut

sub parse {
    my ($pkg, $data) = @_;
    my $self = $pkg->new();

    my $ref = _attr($data, 'ref');
    croak("Why did you create an ElementRefNode if you didn't have a ref?")
      unless $ref;
    $self->{unresolved_ref} = 1;
    $self->name($ref);

    my $name = _attr($data, 'name');
    _err("Found <element> with illegal combination of 'ref' and 'name' ".
         "attributes.")
      if $name;

    my $type_name = _attr($data, 'type');
    _err("Found <element> with illegal combination of 'ref' and 'type' ".
         "attributes.")
      if $type_name;


    my $min = _attr($data, 'minOccurs');
    $min = 1 unless defined $min;
    _err("Invalid value for minOccurs '$min' found in <element>.")
      unless $min =~ /^\d+$/;
    $self->{min} = $min;

    my $max = _attr($data, 'maxOccurs');
    $max = 1 unless defined $max;
    _err("Invalid value for maxOccurs '$max' found in <element>.")
      unless $max =~ /^\d+$/ or $max eq 'unbounded';
    $self->{max} = $max;

    return $self;
}

1;

