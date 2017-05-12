package Wx::Perl::Thread::ClassPublisher;

use Wx; # before 'use base'

use strict;
use warnings;
use base qw(Wx::Perl::Thread::Listener Class::Publisher);

use Storable;

sub _notify_subscribers {
    my( $self, $data ) = @_;

    $self->notify_subscribers( @{Storable::thaw( $data )} );
}

sub notify_subscribers {
    my( $self, @data ) = @_;

    if( Wx::Thread::IsMain() ) {
        $self->SUPER::notify_subscribers( @data );
    } else {
        $self->_send_event( Storable::freeze( \@data ) );
    }
}

1;
