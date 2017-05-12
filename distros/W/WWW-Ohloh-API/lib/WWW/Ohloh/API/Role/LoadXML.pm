package WWW::Ohloh::API::Role::LoadXML;

use strict;
use warnings;

use Object::InsideOut;

my %init_args : InitArgs = ( 'xml' => '', );

sub _init : Init {
    my ( $self, $args ) = @_;

    $self->load_xml( $args->{xml} ) if $args->{xml};
}

1;
