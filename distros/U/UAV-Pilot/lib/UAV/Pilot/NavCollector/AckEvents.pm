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
package UAV::Pilot::NavCollector::AckEvents;
$UAV::Pilot::NavCollector::AckEvents::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;

with 'UAV::Pilot::NavCollector';
with 'UAV::Pilot::Logger';


has 'easy_event' => (
    is  => 'ro',
    isa => 'UAV::Pilot::EasyEvent',
);
has '_last_ack_status' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);


sub got_new_nav_packet
{
    my ($self, $packet) = @_;
    my $new_ack = $packet->state_control_received;
    my $last_ack = $self->_last_ack_status;
    my $event = $self->easy_event;
    my $logger = $self->_logger;

    $logger->info( "Got nav ACK of $new_ack, old ack is $last_ack" );
    my $send_event = $new_ack
        ? 'nav_ack_on'
        : 'nav_ack_off';
    $logger->info( "Sending $send_event event" );
    $event->send_event( $send_event );

    if( $new_ack != $last_ack ) {
        $logger->info( "Sending nav_ack_toggle event" );
        $event->send_event( 'nav_ack_toggle', $new_ack );
        $self->_last_ack_status( $new_ack );
    }

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::NavCollector::AckEvents

=head1 SYNOPSIS

   my $easy_event = UAV::Pilot::EasyEvent->new;
   my $ack = UAV::Pilot::NavCollector::AckEvents->new({
       easy_event => $easy_event,
   });

   $easy_event->add_event( 'nav_ack_on' => sub {
       say "ACK control bit is on";
   });
   $easy_event->add_event( 'nav_ack_off' => sub {
       say "ACK control bit is off";
   });
   $easy_event->add_event( 'nav_ack_toggle' => sub {
       say "ACK control bit toggled";
   });

=head1 DESCRIPTION

Does the C<UAV::Pilot::NavCollector> role to fire off events into 
C<UAV::Pilot::EasyEvent> based on the ACK control bit.  Each nav packet with 
the bit on will fire a C<nav_ack_on> event, and C<nav_ack_off> when off.  If 
the state toggles, C<nav_ack_toggle> is sent.

=cut
