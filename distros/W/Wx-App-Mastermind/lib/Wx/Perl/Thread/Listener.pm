package Wx::Perl::Thread::Listener;

use Wx; # before 'use base'

use strict;
use warnings;
use base qw(Wx::EvtHandler);

use threads::shared;
use Wx::Event qw(EVT_COMMAND);

my $EVENT_ID : shared;

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( );
    $self->init;

    return $self;
}

sub init {
    my( $self ) = @_;

    $EVENT_ID ||= Wx::NewEventType();
    EVT_COMMAND( $self, -1, $EVENT_ID,
                 sub {
                     my( $self, $event ) = @_;
                     my $data = $event->GetData;
                     $self->_notify_subscribers( $data );
                 } );
}

sub _send_event {
    my( $self, $value ) = @_;
    my $e = Wx::PlThreadEvent->new( -1, $EVENT_ID, $value );

    Wx::PostEvent( $self, $e );
}

sub _notify_subscribers { die 'Override in subclass' }

1;
