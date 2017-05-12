package XML::Validator::Schema::AttributeNode;
use base 'XML::Validator::Schema::Node';
use strict;
use warnings;

use XML::Validator::Schema::Util qw(_attr _err);
use Carp qw(confess);

=head1 NAME

XML::Validator::Schema::AttributeNode

=head1 DESCRIPTION

Temporary node in the schema parse tree to represent an attribute.

=cut

sub parse {
    my ($pkg, $data) = @_;
    my $self = $pkg->new();

    # squirl away data for latter use
    $self->{data} = $data;

    return $self;
}

sub compile {
    my ($self) = shift;

    # create a new attribute object and return it
    my $attr = XML::Validator::Schema::Attribute->parse($self->{data});

    # copy in type info if available
    $attr->{type} = $self->{type} if $self->{type};

    return $attr;
}

1;
