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
package UAV::Pilot::ArdupilotProtocol::Packet::RadioMins;
use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 16,
    message_id     => 0x51,
    payload_fields => [qw{
        ch1_min
        ch2_min
        ch3_min
        ch4_min
        ch5_min
        ch6_min
        ch7_min
        ch8_min
    }],
    payload_fields_length => {
        ch1_min => 2,
        ch2_min => 2,
        ch3_min => 2,
        ch4_min => 2,
        ch5_min => 2,
        ch6_min => 2,
        ch7_min => 2,
        ch8_min => 2,
    },
};

has 'ch1_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch2_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch3_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch4_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch5_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch6_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch7_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch8_min' => (
    is  => 'rw',
    isa => 'Int',
);

with 'UAV::Pilot::ArdupilotProtocol::Packet';


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

