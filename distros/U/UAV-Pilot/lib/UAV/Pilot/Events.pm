# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::Events;
$UAV::Pilot::Events::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;
use AnyEvent;
use UAV::Pilot::EventHandler;


use constant TIMER_INTERVAL => 1 / 60;


has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has '_handlers' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[UAV::Pilot::EventHandler]',
    default => sub {[]},
    handles => {
        register => 'push',
    },
);


sub init_event_loop
{
    my ($self) = @_;

    my $timer; $timer = AnyEvent->timer(
        after => 1,
        interval => $self->TIMER_INTERVAL,
        cb       => sub {
            $_->process_events for @{ $self->_handlers };
            $timer;
        },
    );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Events

=head1 SYNOPSIS

    my $condvar = AnyEvent->condvar;
    my $events = UAV::Pilot::Events->new({
        condvar => $condvar,
    });
    $events->register( ... );
    $events->init_event_loop;
    $condvar->recv;

=head1 DESCRIPTION

Handles event loops on a regular timer.

=head1 METHODS

=head2 new

    new({
        condvar => $cv,
    })

Constructor.  The C<condvar> argument is an C<AnyEvent::Condvar>.

=head2 register

    register( $event_handler )

Adds a object that does the C<UAV::Pilot::EventHandler> role to the list.  The 
C<process_events> method on that object will be called each time the event loop runs.

=head2 init_event_loop

Sets up the event loop.  Note that you must still call C<recv> on the C<AnyEvent::Condvar> 
to start the loop running.

=cut
