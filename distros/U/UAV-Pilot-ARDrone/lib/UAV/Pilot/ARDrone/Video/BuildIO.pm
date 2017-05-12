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
package UAV::Pilot::ARDrone::Video::BuildIO;
$UAV::Pilot::ARDrone::Video::BuildIO::VERSION = '1.1';
use v5.14;
use warnings;
use Moose::Role;


sub _build_io
{
    my ($class, $args) = @_;
    my $driver = $$args{driver};
    my $host   = $driver->host;
    my $port   = $driver->ARDRONE_PORT_VIDEO_H264;

    my $io = IO::Socket::INET->new(
        PeerAddr  => $host,
        PeerPort  => $port,
        ReuseAddr => 1,
        Blocking  => 0,
    ) or UAV::Pilot::IOException->throw(
        error => "Could not connect to $host:$port for video: $@",
    );
    return $io;
}

sub init_event_loop
{
    my ($self) = @_;

    my $io_event; $io_event = AnyEvent->io(
        fh   => $self->_io,
        poll => 'r',
        cb   => sub {
            $self->_process_io;
            $io_event;
        },
    );
    return 1;
}


1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Video::BuildIO

=head1 DESCRIPTION

Role for video stream handling modules to create the socket for reading the 
stream from the Parrot AR.Drone.  Also sets up the AnyEvent io watcher.

=head1 PROVIDES

=head2 _build_io

   $class->_build_io({ driver => $driver })

Passed a C<UAV::Pilot::ARDrone::Driver>.  Sets up and returns a 
C<IO::Socket::INET> object that connects to the host and video port for the 
AR.Drone.

=head2 init_event_loop

Called to setup an AnyEvent io watcher to process the incoming video data.

=head1 REQUIRES

=head2 _io

Returns a filehandle for reading video data.

=head2 _process_io

Called when there is IO data to read from C<_io>.

=cut
