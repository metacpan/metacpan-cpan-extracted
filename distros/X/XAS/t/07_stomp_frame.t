use strict;
use Test::More;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 6);
       use_ok("XAS::Lib::Stomp::Parser");

    }

}

my $body = join(
    "\n",
    ("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz") x 10
);

my $message = join(
    "\n",
    "MESSAGE",
    "destination: /queue/foo",
    "",
    "$body\000",
);

my $frame;
my @parts = split_message($message . "\n" . $message);
my $filter = XAS::Lib::Stomp::Parser->new;

while (my $part = shift(@parts)) {

    if ($frame = $filter->parse($part)) {

        isa_ok($frame, "XAS::Lib::Stomp::Frame");
        is( $frame->body, $body );
        my $buffer = $filter->get_pending;
        ok($buffer) if ($buffer);

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

