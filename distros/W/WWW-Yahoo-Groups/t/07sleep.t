use strict;
use Test::More tests => 7;
BEGIN { use_ok 'WWW::Yahoo::Groups' }

{
    my $w = WWW::Yahoo::Groups->new();

    isa_ok( $w => 'WWW::Yahoo::Groups' );

    my $interval = 4;
    $w->autosleep( $interval );

    my $back = $w->autosleep();
    is( $back => $interval, "autosleep() returns what was given");

    my $before = time;
    $w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );
    ok( $w->loggedin, "We are logged in" );
    my $after = time;

    my $diff = $after - $before;
    diag "autosleep(): $after - $before = $diff";
    # Logging in usually loads 4 pages.
    my $logintime = $interval * 2;
    ok ( $diff > $logintime, "Either sleep or had a slow network connection." );

}

{
    my $w = WWW::Yahoo::Groups->new();

    isa_ok( $w => 'WWW::Yahoo::Groups' );

    my $before = time;
    $w->login( 'perligain7ya5h00grrzogups' => 'redblacktrees' );
    ok( $w->loggedin, "We are logged in" );
    my $after = time;

    my $diff = $after - $before;
    diag "No sleep(): $after - $before = $diff";
}
