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
package UAV::Pilot::ArdupilotProtocol::Packet::RadioOutputs;
use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 16,
    message_id     => 0x53,
    payload_fields => [qw{
        ch1_out
        ch2_out
        ch3_out
        ch4_out
        ch5_out
        ch6_out
        ch7_out
        ch8_out
    }],
    payload_fields_length => {
        ch1_out => 2,
        ch2_out => 2,
        ch3_out => 2,
        ch4_out => 2,
        ch5_out => 2,
        ch6_out => 2,
        ch7_out => 2,
        ch8_out => 2,
    },
};

has 'ch1_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch2_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch3_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch4_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch5_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch6_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch7_out' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch8_out' => (
    is  => 'rw',
    isa => 'Int',
);

with 'UAV::Pilot::ArdupilotProtocol::Packet';


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

