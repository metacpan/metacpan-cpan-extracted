package XML::ExtOn::IncXML;
use base 'XML::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;
    unless ( $self->{__NOT_SKIPED}++ ) {
        $elem->delete_element;
    }
    $elem;
}

 
sub context {
    my $self = shift;
    #Handler namespaces
    return $self->{Handler}->context()
}



1
