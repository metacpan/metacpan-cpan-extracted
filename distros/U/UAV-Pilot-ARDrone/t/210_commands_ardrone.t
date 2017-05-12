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
use Test::More tests => 58;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Control;
use UAV::Pilot::Commands;
use AnyEvent;

my $LIB_DIR = 'share';


my $ardrone = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
});
$ardrone->connect;
my $controller = UAV::Pilot::ARDrone::Control->new({
    driver => $ardrone,
});
my $repl = UAV::Pilot::Commands->new({
    controller_callback_ardrone => sub { $controller },
});
my $cv = AnyEvent->condvar;


$ardrone->saved_commands; # Flush saved commands from connect() call

eval {
    $repl->run_cmd( 'takeoff;' );
};
ok( $@, "No commands loaded into namespace yet" );

$repl->add_lib_dir( UAV::Pilot->default_module_dir );
$repl->load_lib( 'ARDrone', {
    condvar => $cv,
});
pass( "ARDrone basic flight library loaded" );


UAV::Pilot::Commands::run_cmd( 'takeoff;' );
cmp_ok( scalar($ardrone->saved_commands), '==', 0,
    'run_cmd does nothing when called without $self' );

my $seq = 2; # Commands already sent by $ardrone->connect()
my @TESTS = (
    {
        cmd    => 'takeoff;',
        expect => [ "AT*REF=~SEQ~,290718208\r" ],
        name   => "Takeoff command",
    },
    {
        cmd    => 'land;',
        expect => [ "AT*REF=~SEQ~,290717696\r" ],
        name   => "Land command",
    },
    {
        cmd    => 'pitch -1;',
        expect => [ "AT*PCMD=~SEQ~,1,0,-1082130432,0,0\r" ],
        name   => "Pitch command executed",
    },
    {
        cmd    => 'roll -1;',
        expect => [ "AT*PCMD=~SEQ~,1,-1082130432,0,0,0\r" ],
        name   => "Roll command executed",
    },
    {
        cmd    => 'yaw 1;',
        expect => [ "AT*PCMD=~SEQ~,1,0,0,0,1065353216\r" ],
        name   => "Yaw command executed",
    },
    {
        cmd    => 'vert_speed 0.5;',
        expect => [ "AT*PCMD=~SEQ~,1,0,0,1056964608,0\r" ],
        name   => "Vert Speed command executed",
    },
    {
        cmd    => 'calibrate;',
        expect => [ "AT*CALIB=~SEQ~,0\r" ],
        name   => "Calibrate command executed",
    },
    {
        cmd    => 'phi_m30;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","0,1000"\r} ],
        name   => "Phi m30 command executed",
    },
    {
        cmd    => 'phi_30;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","1,1000"\r} ],
        name   => "Phi 30 command executed",
    },
    {
        cmd    => 'theta_m30;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","2,1000"\r} ],
        name   => "Theta m30 command executed",
    },
    {
        cmd    => 'theta_30;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","3,1000"\r} ],
        name   => "Theta 30 command executed",
    },
    {
        cmd    => 'theta_20deg_yaw_200;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","4,1000"\r} ],
        name   => "Theta_20deg_yaw_200 command executed",
    },
    {
        cmd    => 'theta_20deg_yaw_m200;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","5,1000"\r} ],
        name   => "Theta_20deg_yaw_m200 command executed",
    },
    {
        cmd    => 'turnaround;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","6,5000"\r} ],
        name   => "Turnaround command executed",
    },
    {
        cmd    => 'turnaround_godown;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","7,5000"\r} ],
        name   => "Turnaround God Own (go down) command executed",
    },
    {
        cmd    => 'yaw_shake;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","8,2000"\r} ],
        name   => "Yaw Shake command executed",
    },
    {
        cmd    => 'yaw_dance;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","9,5000"\r} ],
        name   => "Yaw Dance command executed",
    },
    {
        cmd    => 'phi_dance;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","10,5000"\r} ],
        name   => "Phi Dance command executed",
    },
    {
        cmd    => 'theta_dance;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","11,5000"\r} ],
        name   => "Theta Dance command executed",
    },
    {
        cmd    => 'vz_dance;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","12,5000"\r} ],
        name   => "VZ Dance command executed",
    },
    {
        cmd    => 'wave;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","13,5000"\r} ],
        name   => "Wave command executed",
    },
    {
        cmd    => 'phi_theta_mixed;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","14,5000"\r} ],
        name   => "Phi Theta Mixed command executed",
    },
    {
        cmd    => 'double_phi_theta_mixed;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","15,5000"\r} ],
        name   => "Double Phi Theta Mixed command executed",
    },
    {
        cmd    => 'flip_ahead;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","16,15"\r} ],
        name   => "Flip Ahead command executed",
    },
    {
        cmd    => 'flip_behind;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","17,15"\r} ],
        name   => "Flip Behind command executed",
    },
    {
        cmd    => 'flip_left;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","18,15"\r} ],
        name   => "Flip left command executed",
    },
    {
        cmd    => 'flip_right;',
        expect => [ qq{AT*CONFIG=~SEQ~,"control:flight_anim","19,15"\r} ],
        name   => "Flip Right command executed",
    },
    {
        cmd    => 'emergency;',
        expect => [ "AT*REF=~SEQ~,290717952\r" ],
        name   => "Emergency command",
    },
    {
        cmd    => 'led_blink_green_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","0,1073741824,2"\r} ],
        name   => "led_blink_green_red command",
    },
    {
        cmd    => 'led_blink_green 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","1,1073741824,2"\r} ],
        name   => "led_blink_green command",
    },
    {
        cmd    => 'led_blink_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","2,1073741824,2"\r} ],
        name   => "led_blink_red command",
    },
    {
        cmd    => 'led_blink_orange 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","3,1073741824,2"\r} ],
        name   => "led_blink_orange command",
    },
    {
        cmd    => 'led_snake_green_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","4,1073741824,2"\r} ],
        name   => "led_snake_green_red command",
    },
    {
        cmd    => 'led_fire 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","5,1073741824,2"\r} ],
        name   => "led_fire command",
    },
    {
        cmd    => 'led_standard 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","6,1073741824,2"\r} ],
        name   => "led_standard command",
    },
    {
        cmd    => 'led_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","7,1073741824,2"\r} ],
        name   => "led_red command",
    },
    {
        cmd    => 'led_green 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","8,1073741824,2"\r} ],
        name   => "led_green command",
    },
    {
        cmd    => 'led_red_snake 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","9,1073741824,2"\r} ],
        name   => "led_red_snake command",
    },
    {
        cmd    => 'led_blank 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","10,1073741824,2"\r} ],
        name   => "led_blank command",
    },
    {
        cmd    => 'led_right_missile 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","11,1073741824,2"\r} ],
        name   => "led_right_missile command",
    },
    {
        cmd    => 'led_left_missile 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","12,1073741824,2"\r} ],
        name   => "led_left_missile command",
    },
    {
        cmd    => 'led_double_missile 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","13,1073741824,2"\r} ],
        name   => "led_double_missile command",
    },
    {
        cmd    => 'led_front_left_green_others_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","14,1073741824,2"\r} ],
        name   => "led_front_left_green_others_red command",
    },
    {
        cmd    => 'led_front_right_green_others_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","15,1073741824,2"\r} ],
        name   => "led_front_right_green_others_red command",
    },
    {
        cmd    => 'led_rear_right_green_others_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","16,1073741824,2"\r} ],
        name   => "led_rear_right_green_others_red command",
    },
    {
        cmd    => 'led_rear_left_green_others_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","17,1073741824,2"\r} ],
        name   => "led_rear_left_green_others_red command",
    },
    {
        cmd    => 'led_left_green_right_red 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","18,1073741824,2"\r} ],
        name   => "led_left_green_right_red command",
    },
    {
        cmd    => 'led_left_red_right_green 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","19,1073741824,2"\r} ],
        name   => "led_left_red_right_green command",
    },
    {
        cmd    => 'led_blink_standard 2.0, 2;',
        expect => [ qq{AT*CONFIG=~SEQ~,"leds:leds_anim","20,1073741824,2"\r} ],
        name   => "led_blink_standard command",
    },
    {
        cmd    => 'hover;',
        expect => [ ],
        name   => "hover command",
    },
    {
        cmd    => 'start_userbox_nav_data;',
        expect => [ qq{AT*CONFIG=~SEQ~,"userbox:userbox_cmd","1"\r} ],
        name   => "start_userbox_nav_data",
    },
    {
        cmd    => 'stop_userbox_nav_data;',
        expect => [ qq{AT*CONFIG=~SEQ~,"userbox:userbox_cmd","0"\r} ],
        name   => "stop_userbox_nav_data",
    },
    {
        cmd    => 'cancel_userbox_nav_data;',
        expect => [ qq{AT*CONFIG=~SEQ~,"userbox:userbox_cmd","3"\r} ],
        name   => "cancel_userbox_nav_data",
    },
    {
        cmd    => 'take_picture 5, 3, "20130629_173900";',
        expect => [ qq{AT*CONFIG=~SEQ~,"userbox:userbox_cmd","2,5,3,20130629_173900"\r} ],
        name   => "take_picture",
    },
    {
        cmd    => 'record_usb;',
        expect => [ qq{AT*CONFIG=~SEQ~,"video:video_on_usb","TRUE"\r} ],
        name   => "record_usb",
    },
);
foreach my $test (@TESTS) {
    $seq++ if @{ $$test{expect} };

    my $cmd       = $$test{cmd};
    my $test_name = $$test{name};
    my @expect    = map {
        my $out = $_;
        $out =~ s/~SEQ~/$seq/g;
        $out;
    } @{ $$test{expect} };
    
    $repl->run_cmd( $cmd );
    my @saved_cmds = $ardrone->saved_commands;
    is_deeply( 
        \@saved_cmds,
        \@expect,
        $test_name,
    );
}
