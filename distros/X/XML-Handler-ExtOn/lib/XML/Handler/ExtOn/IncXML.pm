package XML::Handler::ExtOn::IncXML;
use base 'XML::Handler::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;
    unless ( $self->{__NOT_SKIPED}++ ) {
        $elem->delete_element;
    }
    $elem;
}
1
