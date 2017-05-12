use strict;
use warnings;
use Test::More;
use lib ("t");
use testlib::MockLingr qw(mock_useragent create_lingr);

my $USER = $testlib::MockLingr::USERNAME;
my $PASS = $testlib::MockLingr::PASSWORD;
my $SID  = $testlib::MockLingr::SESSION_ID;
my $ROOM = $testlib::MockLingr::ROOM;

{
    note("--- re-create session if it's obsolete");
    my $ua = mock_useragent();
    my $lingr = create_lingr($ua);
    my @messages = $lingr->get_archives($ROOM, {limit => 5, before => 100});
    
    my ($method, $args) = $ua->next_call();
    is($args->[1], "http://lingr.com/api/session/create?user=$USER&password=$PASS", "session/create URL OK");
    ($method, $args) = $ua->next_call();
    is($args->[1], "http://lingr.com/api/room/get_archives?session=$SID&room=$ROOM&before=100&limit=5", "get_archives URL OK");
    ($method, $args) = $ua->next_call();
    is($method, undef, "no more call");

    $ua->clear;
    $lingr->{session_id} = "INVALID_SESSION";  ## force messing up session

    @messages = $lingr->get_archives($ROOM, {before => 10});
    ($method, $args) = $ua->next_call();
    is($method, "get", "method OK");
    is($args->[1], "http://lingr.com/api/room/get_archives?session=INVALID_SESSION&room=$ROOM&before=10", "first get_archives OK");
    ($method, $args) = $ua->next_call();
    is($method, "get", "method OK");
    is($args->[1], "http://lingr.com/api/session/create?user=$USER&password=$PASS", "retry session/create OK");
    ($method, $args) = $ua->next_call();
    is($args->[1], "http://lingr.com/api/room/get_archives?session=$SID&room=$ROOM&before=10", "second get_archives OK");
    ($method, $args) = $ua->next_call();
    is($method, undef, "no more call");
}

done_testing();
