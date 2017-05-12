package Thrift::IDL::Method;

=head1 NAME

Thrift::IDL::Method

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);
__PACKAGE__->mk_accessors(qw(name oneway returns arguments throws service));
use Data::Dumper;

=head1 METHODS

=head2 name

=head2 oneway

=head2 returns

=head2 arguments

=head2 throws

=head2 service

Scalar accessors

=head2 fields

Alias to C<arguments>

=head2 field_named ($name)

=head2 argument_named ($name)

=head2 field_id ($id)

=head2 argument_id ($id)

Returns object found in named array with given key value

=cut

# Having similarly named functions as Structs allows us to be processed similarly

sub fields {
    my $self = shift;
    $self->arguments(@_);
}

sub field_named {
    my ($self, $name) = @_;
    $self->array_search($name, 'arguments', 'name');
}
*argument_named = \&field_named;

sub field_id {
    my ($self, $name) = @_;
    $self->array_search($name, 'arguments', 'id');
}
*argument_id = \&field_id;

=head2 setup

A method C<arguments> and C<throws> has children of type L<Thrift::IDL::Field> and L<Thrift::IDL::Comment>. Walk through all these children and associate the comments with the fields that preceeded them (if perl style) or with the field following.

=cut
    
sub setup {
    my $self = shift;
    foreach my $children_key (qw(arguments throws)) {
		$self->_setup($children_key);
    }
}

sub to_str {
    my ($self) = @_;

    return sprintf '%s (%s)',
        $self->name,
        join(', ',
            map { $_ .': '. $self->$_ }
            grep { defined $self->$_ }
            qw(returns oneway)
        );
}

1;
