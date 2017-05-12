# Copyright (c) 2016  Timm Murray
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
use Test::More tests => 1;
use strict;
use warnings;
use UAV::Pilot::Wumpus::PacketFactory;
use UAV::Pilot::Wumpus::Server::Backend;
use UAV::Pilot::Wumpus::Server::Backend::Mock;
use UAV::Pilot::Wumpus::Server::Mock;
use Test::Moose;

my $backend = UAV::Pilot::Wumpus::Server::Backend::Mock->new;
my $server = UAV::Pilot::Wumpus::Server::Mock->new({
    listen_port => 65534,
    backend     => $backend,
    packet_callback => \&callback,
});

my $callback_count = 0;
my $packet_count = 0;
my $startup_request = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'StartupRequest' );
$startup_request->set_packet_count( $packet_count++ );
$startup_request->make_checksum_clean;
$server->process_packet( $startup_request );


cmp_ok( $callback_count, '==', 1, "Callback was made" );


sub callback
{
    my ($server, $packet) = @_;
    $callback_count++;
    return;
}
