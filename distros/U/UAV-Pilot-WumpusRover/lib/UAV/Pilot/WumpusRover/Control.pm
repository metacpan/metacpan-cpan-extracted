# Copyright (c) 2014  Timm Murray
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
package UAV::Pilot::WumpusRover::Control;
use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::WumpusRover::PacketFactory;
use IO::Socket::INET;


has 'turn' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);
has 'throttle' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);
has 'driver' => (
    is  => 'ro',
    isa => 'UAV::Pilot::WumpusRover::Driver',
);

with 'UAV::Pilot::ControlRover';
with 'UAV::Pilot::Logger';


sub process_sdl_input
{
    my ($self, $args) = @_;
    my $turn     = $args->{roll};
    my $throttle = $args->{throttle};

    # TODO Send output min/max settings in packet for initial setup, rather 
    # than hardcoding here
    $turn = $self->_map_values( $self->JOYSTICK_MIN_AXIS_INT,
        $self->JOYSTICK_MAX_AXIS_INT, 0, 180, $turn );
    $throttle = $self->_map_values( $self->JOYSTICK_MIN_AXIS_INT,
        $self->JOYSTICK_MAX_AXIS_INT, 0, 100, $throttle );

    $self->turn( $turn );
    $self->throttle( $throttle );

    return 1;
}

sub send_move_packet
{
    my ($self) = @_;
    my @channels = (
        $self->throttle,
        $self->turn,
    );
    return $self->driver->send_radio_output_packet( @channels );
}

sub _map_values
{
    my ($self, $in_min, $in_max, $out_min, $out_max, $in) = @_;
    my $output = ($in - $in_min) / ($in_max - $in_min)
        * ($out_max - $out_min) + $out_min;
    return $output
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

    UAV::Pilot::WumpusRover::Control

=head1 SYNOPSIS

    my $driver = UAV::Pilot::WumpusRover::Driver->new({
        host => $hostname,
    });
    $driver->connect;
    
    my $control = UAV::Pilot::WumpusRover::Control::Event->new({
        driver => $driver,
    });

    $control->turn( 30 );
    $control->throttle( 70 );

=head1 DESCRIPTION

B<NOTE>: You probably want to use C<UAV::Pilot::WumpusRover::Control::Event> 
instead of this.

A controller for the WumpusRover.  Does the C<UAV::Pilot::ControlRover> and 
C<UAV::Pilot::Logger> roles.

=head1 METHODS

=head2 send_move_packet

Sends a packet using the passed C<driver> containing the current movement 
settings.

=head1 ATTRIBUTES

=head2 turn

A read/write attribute that takes values between 0 and 180.  0 is to the left 
and 180 is to the right.

=head2 throttle

A read/write attribute that takes values between 0 and 100.  0 is stop or 
full reverse (depending on how your ESC is setup).  100 is full speed ahead.

=cut
