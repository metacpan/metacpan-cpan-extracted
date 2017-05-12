use strict;
use Test::More;
#use Data::Dumper;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 11);
       use_ok("XAS::Lib::Stomp::Frame");

    }

}

my $body = join(
    "\n",
    ("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz") x 10
);

my $frame = XAS::Lib::Stomp::Frame->new();

isa_ok($frame, "XAS::Lib::Stomp::Frame");

ok($frame->target('1.2'));
ok($frame->command('MESSAGE'));
ok($frame->body($body));
ok($frame->header->add('destination', '/queue/foo'));

is($frame->command, "MESSAGE");
is($frame->header->destination, "/queue/foo");
is($frame->body, $body);

ok($frame->header->remove('destination'));
is($frame->header->destination, undef);

