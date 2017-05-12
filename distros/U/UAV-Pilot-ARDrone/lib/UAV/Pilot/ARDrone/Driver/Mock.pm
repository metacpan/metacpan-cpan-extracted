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
package UAV::Pilot::ARDrone::Driver::Mock;
$UAV::Pilot::ARDrone::Driver::Mock::VERSION = '1.1';
use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::ARDrone::NavPacket;

extends 'UAV::Pilot::ARDrone::Driver';


has 'last_cmd' => (
    is     => 'ro',
    isa    => 'Str',
    writer => '_set_last_cmd',
);
has '_saved_commands' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        '_add_saved_command' => 'push',
    },
);


sub connect
{
    my ($self) = @_;
    $self->_init_nav_data;
    $self->_init_drone;
    return 1;
}


sub _send_multi_cmds
{
    my ($self) = @_;
    my @multi_cmds = @{ $self->_multi_cmds };
    $self->_set_last_cmd( join( '', @multi_cmds ) );
    $self->_add_saved_command( $_ ) for @multi_cmds;
    return 1;
}

sub _send_cmd
{
    my ($self, $cmd) = @_;

    if( $self->_is_multi_cmd_mode ) {
        $self->_add_multi_cmd( $cmd );
    }
    else {
        $self->_set_last_cmd( $cmd );
        $self->_add_saved_command( $cmd );
    }
    return 1;
}

sub read_nav_packet
{
    my ($self, @packet) = @_;
    my $packet = pack( 'H*', join('', @packet) );
    my $nav_packet = UAV::Pilot::ARDrone::NavPacket->new({
        packet => $packet,
    });
    $self->_set_last_nav_packet( $nav_packet );
    return 1;
}

sub _init_nav_data
{
    my ($self) = @_;

    $self->at_config(
        $self->ARDRONE_CONFIG_GENERAL_NAVDATA_DEMO,
        $self->TRUE,
    );

    return 1;
}

sub saved_commands
{
    my ($self) = @_;
    my @cmds = @{ $self->_saved_commands };
    $self->_saved_commands( [] );
    return @cmds;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

