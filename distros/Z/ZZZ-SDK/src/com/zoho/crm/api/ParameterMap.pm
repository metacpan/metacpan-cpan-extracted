use strict;
use warnings;

package ParameterMap;
use Moose;
use src::com::zoho::crm::api::util::HeaderParamValidator;

has 'parameter_map' => (is=>'rw');

sub new
{
    my $class = shift;

    my $self =
    {
        parameter_map => ()
    };

    bless $self, $class;

    return $self;
}

sub add
{
    my($self, $param, $value) = @_;

    my $name = $param->get_name();

    my $class_name = $param->get_class_name();

    if(defined($class_name))
    {
        $value = HeaderParamValidator->new()->validate($param, $value);
    }

    if(!exists($self->{parameter_map}{$name}))
    {
        $self->{parameter_map}{$name} = "" . $value;
    }
    else
    {
        my $param_value = $self->{parameter_map}{$name};

        $param_value = $param_value . ",". ("" . $value);

        $self->{parameter_map}{$name} = $param_value;
    }
}

=head1 NAME

com::zoho::crm::api::parameterMap - This class representing the HTTP parameter name and value

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Returns the instance of the parameterMap

=item C<add>

This method to add parameter name and value

Param header_inst : A Param class instance

Param value : The parameter value for param class instance

=back

=cut
1;
