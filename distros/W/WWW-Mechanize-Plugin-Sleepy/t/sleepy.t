use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;
use Test::Timer;

use WWW::Mechanize::Pluggable;

note "Pluggable should have loaded Plugin::Sleepy...";

ok my $mech = WWW::Mechanize::Pluggable->new(),
    "created new pluggable object";

ok $mech->can('sleep'), "sleep method created";
is $mech->sleep, 0, "sleep 0 by default";

foreach ( 'x', '10x', '1..', '1 .. 10' ) {
    dies_ok { WWW::Mechanize::Pluggable->new( sleep => $_ ) }
    "dies with invalid sleep value ($_)";
}

ok $mech= WWW::Mechanize::Pluggable->new( sleep => 5 ),
    "created new pluggable object with sleep";

is $mech->sleep, 5, "sleep set to 5 seconds";

my @tests = (
    {   name => 'get',
        code => sub { $mech->get("http://www.google.com/webhp?hl=en") },
    },
    {   name => 'follow_link',
        code => sub { $mech->follow_link( text => "Images" ) },
    },
    {   name => 'back',
        code => sub { $mech->back() },
    },
    {   name => 'reload',
        code => sub { $mech->reload() },
    },
    {   name => 'submit',
        code => sub { $mech->submit() },
    },
);

ok $mech->sleep(2), "setting sleep";
is $mech->sleep, 2, "now set to 2 second";

foreach my $test (@tests) {
    note $test->{name};
    time_atleast( $test->{code}, 1, "get took over 1 second" );
}

ok $mech->sleep('2..4'), "setting sleep to range";
is $mech->sleep, '2..4', "now set to between 2 and 4 seconds";

foreach my $test (@tests) {
    note $test->{name};
    time_between( $test->{code}, 2, 5, "slept for between 2 and 4 seconds" );
}
