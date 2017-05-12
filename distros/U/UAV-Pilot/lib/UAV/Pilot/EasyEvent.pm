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
package UAV::Pilot::EasyEvent;
$UAV::Pilot::EasyEvent::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;

#with 'MooseX::Clone';


use constant {
    UNITS_MILLISECOND => 0,
};

has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has '_timers' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef[Any]]',
    default => sub { [] },
    handles => {
        _add_timer => 'push',
    },
);
has '_events' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[HashRef[Item]]]',
    default => sub { {} },
    handles => {
        '_set_event_callbacks' => 'set',
        '_event_type_exists'   => 'exists',
        '_get_event_callbacks' => 'get',
    },
);


sub add_timer
{
    my ($self, $args) = @_;
    my $duration       = $$args{duration};
    my $duration_units = $$args{duration_units};
    my $callback       = $$args{cb};

    my $true_time = $self->_convert_time_units( $duration, $duration_units );
    my $new_self = ref($self)->new({
        condvar => $self->condvar,
    });

    $self->_add_timer({
        time         => $true_time,
        cb           => $callback,
        child_events => $new_self,
    });

    return $new_self;
}

sub add_event
{
    my ($self, $name, $callback, $is_oneoff) = @_;
    $is_oneoff //= 0;

    my @callbacks;
    if( $self->_event_type_exists( $name ) ) {
        @callbacks  = @{ $self->_get_event_callbacks( $name ) };
    }
    else {
        @callbacks = ();
    }

    push @callbacks, {
        callback   => $callback,
        is_one_off => $is_oneoff,
    };
    $self->_set_event_callbacks( $name => \@callbacks );

    return 1;
}

sub send_event
{
    my ($self, $name, @args) = @_;
    my $callbacks            = $self->_get_event_callbacks( $name );
    return 1 unless defined $callbacks;
    my @callbacks            = (@$callbacks);
    my $is_callbacks_changed = 0;

    foreach my $i (0 .. $#callbacks) {
        # Always modify the *original* arrayref $callbacks here, not the 
        # copy @callbacks.  If we splice out a one-off, @callbacks will be
        # changed and the index will be off.
        my $cb         = $callbacks->[$i]{callback};
        my $is_one_off = $callbacks->[$i]{is_one_off};
        $cb->(@args);

        if( $is_one_off ) {
            splice @callbacks, $i, 1;
            $is_callbacks_changed = 1;
        }
    }

    $self->_set_event_callbacks( $name => \@callbacks) if $is_callbacks_changed;
    return 1;
}

sub init_event_loop
{
    my ($self) = @_;

    foreach my $timer_def (@{ $self->_timers }) {
        my $timer; $timer = AnyEvent->timer(
            after => $timer_def->{time},
            cb    => sub {
                $timer_def->{cb}->();
                $timer_def->{child_events}->init_event_loop;
                $timer;
            },
        );
    }

    return 1;
}


sub _convert_time_units
{
    my ($self, $time, $unit) = @_;

    if( $self->UNITS_MILLISECOND == $unit ) {
        $time /= 1000;
    }

    return $time;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::EasyEvent

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar;
    my $event = UAV::Pilot::EasyEvent->new({
        condvar => $cv,
    });
    
    my @events;
    my $event2 = $event->add_timer({
        duration       => 100,
        duration_units => $event->UNITS_MILLISECOND,
        cb             => sub {
            push @events => 'First event',
        },
    })->add_timer({
        duration       => 10,
        duration_units => $event->UNITS_MILLISECOND,
        cb             => sub {
            push @events => 'Second event',
        },
    });
    
    $event2->add_timer({
        duration       => 50,
        duration_units => $event->UNITS_MILLISECOND,
        cb             => sub {
            push @events => 'Fourth event',
            $cv->send;
        },
    });
    $event2->add_timer({
        duration       => 10,
        duration_units => $event->UNITS_MILLISECOND,
        cb             => sub {
            push @events => 'Third event',
        },
    });
    
    
    $event->init_event_loop;
    $cv->recv;
    
    # After time passes, prints:
    # First event
    # Second event
    # Third event
    # Fourth event
    #
    say $_ for @events;

=head1 DESCRIPTION

C<AnyEvent> is the standard event framework used for C<UAV::Pilot>.  However, its 
interface isn't convenient for some of the typical things done for UAV piloting.  For 
instance, to put the code into plain English, we might want to say:

    Takeoff, wait 5 seconds, then pitch forward for 2 seconds, then pitch backwards 
    for 2 seconds, then land

In the usual C<AnyEvent> interface, this requires building the timers inside the callbacks 
of other timers, which leads to several levels of indentation.  C<UAV::Pilot::EasyEvent> 
simplifies the handling and syntax of this kind of event workflow.

=head1 METHODS

=head2 new

    new({
        condvar => $cv,
    })

Constructor.  The C<condvar> argument should be an C<AnyEvent::CondVar>.

=head2 add_timer

    add_timer({
        duration       => 100,
        duration_units => $event->UNITS_MILLISECOND,
        cb             => sub { ... },
    })

Add a timer to run in the event loop.  It will run after C<duration> units of time, with 
the units specified by C<duration_units>.  The C<cb> parameter is a reference to a 
subroutine to use as a callback.

Returns a child C<EasyEvent> object.  When the timer above has finished, any timers on 
child objects will be setup for execution.  This makes it easy to chain timers to run 
after each other.

=head2 init_event_loop

This method must be called after running a series of C<add_timer()> calls.  You only need 
to call this on the root object, not the children.

You must call C<recv> on the C<condvar> yourself.

=head1 add_event

  add_event( 'foo', sub {...}, 0 )

Add a subref that will be called when the named event is fired off.  The 
first parameter is the name of the event, and the second is the subref.

The third is optional, and specifies if the call will be a "one-off" or not.  
If it's a one-off, then after the first call to the sub, it will be removed 
from list of callbacks.  Defaults to false.

The callback will receive the arguments that were passed to C<send_event()> 
when the event is triggered.

=head1 send_event

  send_event( 'foo', @args )

Trigger an event with the given name.  The first arg is the name of the event.  
All subsequent args will be passed to the callbacks attached to that event 
name.

=cut
