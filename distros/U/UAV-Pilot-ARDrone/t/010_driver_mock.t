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
use Test::More tests => 41;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::Exceptions;
use UAV::Pilot::Driver;
use UAV::Pilot::ARDrone::Driver;
use UAV::Pilot::ARDrone::Driver::Mock;
use Test::Moose;

my $ardrone_mock = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
    port => 7776,
});
ok( $ardrone_mock, "Created object" );
isa_ok( $ardrone_mock => 'UAV::Pilot::ARDrone::Driver::Mock' );
does_ok( $ardrone_mock => 'UAV::Pilot::Driver' );
cmp_ok( $ardrone_mock->port, '==', 7776, "Port set" );

ok( $ardrone_mock->connect, "Connect to ARDrone" );


my $seq = 2;
my @saved_cmds = $ardrone_mock->saved_commands;
is_deeply(
    \@saved_cmds,
    [
        qq{AT*CONFIG=1,"general:navdata_demo","TRUE"\r},
        "AT*FTRIM=2,\r",
    ],
    "Connect to drone and set Flat Trim, navdata demo config",
);


my @TESTS = (
    {
        run       => 'at_ref',
        args      => [ 1, 0 ],
        expect    => "AT*REF=~SEQ~,290718208\r",
        test_name => 'Takeoff command',
    },
    {
        run       => 'at_pcmd',
        args      => [ 1, 1, -0.8, -0.8, -0.8, -0.8 ],
        expect    => "AT*PCMD=~SEQ~,3,-1085485875,-1085485875,-1085485875,-1085485875\r",
        test_name => 'Set progressive motion command',
    },
    {
        run       => 'at_pcmd',
        args      => [ 0, 1, -0.8, -0.8, -0.8, -0.8 ],
        expect    => "AT*PCMD=~SEQ~,7,-1085485875,-1085485875,-1085485875,-1085485875\r",
        test_name => 'Set absolute motion command',
    },
    {
        run       => 'at_pcmd_mag',
        args      => [ 1, 1, -0.8, -0.8, -0.8, -0.8, -0.8, -0.8 ],
        expect    => "AT*PCMD_MAG=~SEQ~,3,-1085485875,-1085485875,-1085485875,-1085485875,-1085485875,-1085485875\r",
        test_name => 'Set progressive motion command w/magnetometer',
    },
    {
        run       => 'at_ftrim',
        args      => [],
        expect    => "AT*FTRIM=~SEQ~,\r",
        test_name => 'Set reference to horizontal plane command',
    },
    {
        run       => 'at_calib',
        args      => [ $ardrone_mock->ARDRONE_CALIBRATION_DEVICE_NUMBER ],
        expect    => "AT*CALIB=~SEQ~,1\r",
        test_name => 'Calibration command',
    },
    {
        run       => 'at_config',
        args      => [ 'SYSLOG:output', '5' ],
        expect    => qq{AT*CONFIG=~SEQ~,"SYSLOG:output","5"\r},
        test_name => 'Set config option command',
    },
    {
        run       => 'at_config_ids',
        args      => [ '1234', '5678', '9012' ],
        expect    => "AT*CONFIG_IDS=~SEQ~,1234,5678,9012\r",
        test_name => 'Config IDs command',
    },
    {
        run       => 'at_comwdg',
        args      => [ ],
        expect    => "AT*COMWDG=~SEQ~\r",
        test_name => 'Reset comm watchdog command',
    },
    {
        run       => 'at_ctrl',
        args      => [ 1 ],
        expect    => "AT*CTRL=~SEQ~,1\r",
        test_name => 'Control command',
    },
);
foreach (@TESTS) {
    $seq++;

    my $method = $_->{run};
    my @args   = @{ $_->{args} };
    my $expect = $_->{expect};
    $expect =~ s/~SEQ~/$seq/g;
    my $test_name = $_->{test_name};

    $ardrone_mock->$method( @args );
    my $got = $ardrone_mock->last_cmd;
    cmp_ok( $got, 'eq', $expect, $test_name );
}


eval {
    $ardrone_mock->at_pcmd( 1, 1, 2, 0, 0, 0 );
};
if( $@ && $@->isa( 'UAV::Pilot::NumberOutOfRangeException' ) ) {
    ok( 'Caught Out of Range exception' );
    cmp_ok( $seq, '==', $ardrone_mock->seq,
        "Sequence was not incrmented for Out of Range error" );
}

my $ardrone_port_check = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
});
cmp_ok( $ardrone_port_check->port, '==', 5556, "Correct default port" );

$ardrone_mock->saved_commands; # Clear current command list
$ardrone_mock->at_ref( 1, 0 );
$ardrone_mock->at_ref( 1, 0 );
my @last_commands = $ardrone_mock->saved_commands;
is_deeply( 
    \@last_commands,
    [ "AT*REF=13,290718208\r", "AT*REF=14,290718208\r" ],
    "Gathered previously saved commands",
);
cmp_ok( scalar($ardrone_mock->saved_commands), '==', 0, "No more saved commands" );


cmp_ok( $ardrone_mock->ARDRONE_PORT_COMMAND, '==', 5556, "Command port" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_COMMAND_TYPE, 'eq', 'udp', "Command port type" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_NAV_DATA, '==', 5554, "Navigation data port" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_NAV_DATA_TYPE, 'eq', 'udp',
    "Navigation data port type" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_H264, '==', 5555, "Video port" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_H264_TYPE, 'eq', 'tcp', "Video port type" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_CTRL, '==', 5559, "Control port" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_CTRL_TYPE, 'eq', 'tcp', "Control port type" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_P264_V1, '==', 5555, "Video P264 v1" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_P264_V2, '==', 5555, "Video P264 v2" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_P264_V1_TYPE, 'eq', 'udp', "Video P264 v1 type" );
cmp_ok( $ardrone_mock->ARDRONE_PORT_VIDEO_P264_V2_TYPE, 'eq', 'tcp', "Video P264 v2 type" );


my $last_nav_packet = $ardrone_mock->last_nav_packet;
ok(! $last_nav_packet, "No nav packet yet" );

$ardrone_mock->read_nav_packet(
    # These are in little-endian order
    '88776655',   # Header
    'd004800f',   # Drone state
    '336f0000',   # Sequence number
    '01000000',   # Vision flag
    # No options on this packet besides checksum
    'ffff',       # Checksum ID
    '0800',       # Checksum size
    'c1030000',   # Checksum data
);
$last_nav_packet = $ardrone_mock->last_nav_packet;
isa_ok( $last_nav_packet => 'UAV::Pilot::ARDrone::NavPacket' );
cmp_ok( $last_nav_packet->header, '==', 0x55667788, "Header (magic number) parsed" );

cmp_ok( $ardrone_mock->ARDRONE_USERBOX_CMD_STOP, '==', 0,
    "Userbox stop config command" );
cmp_ok( $ardrone_mock->ARDRONE_USERBOX_CMD_CANCEL, '==', 3,
    "Userbox cancel config command" );
cmp_ok( $ardrone_mock->ARDRONE_USERBOX_CMD_START, '==', 1,
    "Userbox start config command" );
cmp_ok( $ardrone_mock->ARDRONE_USERBOX_CMD_SCREENSHOT, '==', 2,
    "userbox screenshot config command" );

$seq = $ardrone_mock->seq;
$ardrone_mock->multi_cmds( sub {
    $ardrone_mock->at_config_ids( 1234, 5678, 9012 );
    $ardrone_mock->at_config( 'video:camif_fps', 30 );
    $ardrone_mock->at_config( 'video:bitrate', 1000 );
});
my $multi_cfg_expect = join( "\r",
    'AT*CONFIG_IDS=' . ($seq+1) . ',1234,5678,9012',
    'AT*CONFIG=' . ($seq+2) . ',"video:camif_fps","30"',
    'AT*CONFIG=' . ($seq+3) . ',"video:bitrate","1000"',
) . "\r";
my $multi_cfg_got = $ardrone_mock->last_cmd;
cmp_ok( $multi_cfg_got, 'eq', $multi_cfg_expect, "Sent multiple commands at once" );
