use strict;
use Test::More;
#use Data::Dumper;
#use Data::Hexdumper;
use lib "../lib";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 11);
       use_ok("XAS::Lib::Stomp::Parser");

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

my @parts = split_message($message . "\n" . $message);
my $filter1 = XAS::Lib::Stomp::Parser->new;
my $filter2 = XAS::Lib::Stomp::Parser->new;

for (1..2) {

    my $buffer;
    my $frame1;
    my $frame2;

    while (my $part = shift(@parts)) {

        if ($frame1 = $filter1->parse($part)) {

            isa_ok($frame1, "XAS::Lib::Stomp::Frame");
            is($frame1->command, 'MESSAGE');
            is($frame1->header->destination, '/queue/foo');
            is($frame1->header->content_length, $length);
            is($frame1->body, $body );

            $buffer = $frame1->as_string;
#warn hexdump($buffer);

#            $frame2 = $filter2->parse($buffer);
#warn Dumper($frame2);

#            isa_ok($frame2, "XAS::Lib::Stomp::Frame");
#            is($frame2->command, 'MESSAGE');
#            is($frame2->header->destination, '/queue/foo');
#            is($frame2->header->content_length, $length);
#            is($frame2->body, $body );

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

