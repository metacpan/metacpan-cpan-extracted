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
package UAV::Pilot::ArdupilotProtocol::Packet::Ack;
use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 3,
    message_id     => 0x00,
    payload_fields => [qw{
        message_received_id
        checksum_received1
        checksum_received2
    }],
    payload_fields_length => {
        message_received_id => 1,
        checksum_received1  => 1,
        checksum_received2  => 1,
    },
};


has 'message_received_id' => (
    is  => 'rw',
    isa => 'Int',
);
has 'checksum_received1' => (
    is  => 'rw',
    isa => 'Int',
);
has 'checksum_received2' => (
    is  => 'rw',
    isa => 'Int',
);

with 'UAV::Pilot::ArdupilotProtocol::Packet';


sub make_ack_packet_queue_key
{
    my ($self) = @_;
    my $key = join( $self->_PACKET_QUEUE_MAP_KEY_SEPERATOR,
        $self->message_received_id,
        $self->checksum_received1,
        $self->checksum_received2,
    );
    return $key;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

