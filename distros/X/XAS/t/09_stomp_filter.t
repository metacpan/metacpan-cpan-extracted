use strict;
use Test::More;
use Data::Dumper;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 7);
       use_ok("XAS::Lib::Stomp::POE::Filter");

    }

}

my $message = join(
    "\n",
    "DISCONNECT",
    "",
    "\000",
);

my $filter = XAS::Lib::Stomp::POE::Filter->new();

for (1..2) {

    my @parts = split_message($message . $message . $message);
    $filter->get_one_start(\@parts);

    for (1..3) {

        my $arrayref = $filter->get_one;
        if (defined(my $frame = $arrayref->[0])) {
            isa_ok($frame, "XAS::Lib::Stomp::Frame");
            is($frame->command, "DISCONNECT");
        }

    }

}

sub split_message {
    my $message = shift;

    my $len = length($message);
    my @ret;

    while ($len > 0) {

        push @ret, substr($message, 0, int(rand($len) + 1), '');
        $len = length($message);

    }

    return @ret;

}

