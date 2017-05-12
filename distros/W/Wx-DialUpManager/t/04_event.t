#!/usr/bin/perl -w

use Test::More qw(no_plan);

use_ok( 'Wx::DialUpManager' );


ok( Wx::DialUpManager->import(':all') || 1, 'imported all');

my $manager = Wx::DialUpManager->new();
isa_ok($manager ,'Wx::DialUpManager');


is( defined(&EVT_DIALUP_CONNECTED),1, 'EVT_DIALUP_CONNECTED exported');
is( defined(&EVT_DIALUP_DISCONNECTED),1, '&EVT_DIALUP_DISCONNECTED exported');

exit unless $ENV{DO_NET_TEST};
unless($manager->IsAlwaysOnline()){
    undef $manager;
    MyApp->new->MainLoop;
}

package MyApp;
use base qw[ Wx::App ];
use Wx::DialUpManager ':all';

sub OnInit {
    EVT_DIALUP_CONNECTED( sub { Test::More::ok(1,"yes, we're a connected ")} );
    Test::More::ok(1,'register EVT_DIALUP_DISCONNECTED');
    EVT_DIALUP_DISCONNECTED( sub { Test::More::ok(1,"yes, we're a DIS-connected ")} );
    Test::More::ok(1,'register EVT_DIALUP_DISCONNECTED');

    my $timer = Wx::Timer->new( shift );
    
    Wx::Event::EVT_TIMER(
        Wx::wxTheApp(), -1, sub {
            Wx::wxTheApp()->ExitMainLoop;
                Test::More::ok(1,"exiting");
            }
    );
    my $m = Wx::DialUpManager->new();
    $timer->Start( 5000, 1 ); # 5 seconds to hang up
    &Wx::WakeUpIdle;
    if( $m->IsOnline() ){
        Test::More::ok($m->HangUp(),"hanging up");
    } else {
        Test::More::ok(1,"can't hangup, not online, not gonna dial");
    }

    return 1;
}




