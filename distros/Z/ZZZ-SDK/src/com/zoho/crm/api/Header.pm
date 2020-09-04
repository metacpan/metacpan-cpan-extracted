use strict;
use warnings;

package Header;
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

com::zoho::crm::api::Header - This class represents HTTP Header name

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an Header class instance with the specified header name.

Param name : A String containing the header name.

=back

=cut

1;
