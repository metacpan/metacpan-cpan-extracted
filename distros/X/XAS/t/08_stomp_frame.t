use strict;
use Test::More;
#use Data::Dumper;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 13);
       use_ok("XAS::Lib::Stomp::Parser");

    }

}

my $message = join(
    "\n",
    "CONNECTED",
	"session: client-290",
    "",
    "\000",
);

my $filter = XAS::Lib::Stomp::Parser->new;

for (1..2) {

    my $frame;
    my @parts = split_message($message . $message);

    while (my $part = shift(@parts)) {

        if ($frame = $filter->parse($part)) {

            isa_ok($frame, "XAS::Lib::Stomp::Frame");
            is($frame->command, "CONNECTED");
            is($frame->header->session, "client-290");

       }

    }

}

sub split_message {
    my $message = shift;
    my $len     = length($message);

    my @ret;

    while ($len > 0) {

        push @ret, substr($message, 0, int(rand($len) + 1), '');
        $len = length($message);

    }

    return @ret;

}

