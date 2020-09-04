use strict;
use warnings;

package HeaderMap;
use Moose;
use src::com::zoho::crm::api::util::HeaderParamValidator;

has 'header_map' => (is=>'rw');

sub new
{
    my $class = shift;
    my $self =
    {
        header_map => ()
    };
    bless $self, $class;
    return $self;
}

sub add
{
    my($self, $header, $value) = @_;

    my $name = $header->get_name();

    my $class_name = $header->get_class_name();

    if(defined($class_name))
    {
        $value = HeaderParamValidator->new()->validate($header, $value);
    }

    if(!exists($self->{header_map}{$name}))
    {
        $self->{header_map}{$name} = "" . $value;
    }
    else
    {
        my $header_value = $self->{header_map}{$name};

        $header_value = $header_value . ",". ("" . $value);

        $self->{header_map}{$name} = $header_value;
    }
}

=head1 NAME

com::zoho::crm::api::HeaderMap - This class represents header name and value.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Returns the instance of the class HeaderMap

=item C<add>

This method is to add header name and value.
Param header : A Header class instance.
Param value : A  Header value for header class instance.

=back

=cut
1;
