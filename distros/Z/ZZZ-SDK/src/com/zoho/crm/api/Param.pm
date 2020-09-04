use strict;
use warnings;

package Param;
use Moose;

has 'name' =>(is => 'rw');

sub new
{
    my($class, $name, $class_name) = @_;

    my $self =
    {
        name       => $name,
        class_name => $class_name
    };

    bless $self, $class;

    return $self;
}

sub get_name
{
    my($self) = shift;

    return $self->{name};
}

sub get_class_name
{
    my($self) = shift;

    return $self->{class_name};
}

=head1 NAME

com::zoho::crm::api::Param - This class representing the HTTP parameter name

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an Param class instance with the specified parameter name

Param name : A String containing the parameter name

=back

=cut

1;
