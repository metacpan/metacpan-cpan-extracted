use strict;
use Test::More;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 17);
       use_ok("XAS::Lib::Stomp::POE::Filter");

    }

}

my $body = join(
    "\n",
    ("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz") x 10
);
my $length = length($body);
my $message = join(
    "\n",
    "MESSAGE",
    "destination: /queue/foo",
	"content-length: " . $length,
    "",
    "$body\000",
);

my $filter = XAS::Lib::Stomp::POE::Filter->new;

for (1..2) {

    my @parts = split_message($message . "\n" . $message);
    $filter->get_one_start(\@parts);

    for (1..2) {

        my $arrayref = $filter->get_one;
        my $frame = $arrayref->[0];
        isa_ok($frame, "XAS::Lib::Stomp::Frame");
        is($frame->body, $body );
        is($frame->header->destination, '/queue/foo');
        is($frame->header->content_length, $length);

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

