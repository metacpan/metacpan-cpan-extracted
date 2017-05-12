use strict;
use Test::More;
#use Data::Hexdumper;
#use Data::Dumper;
use Badger::Constants 'CRLF';
use lib "../lib";

my $LF = "\012";

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 41);
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

my $noop = CRLF . CRLF . CRLF . "\000";
my $filter = XAS::Lib::Stomp::Parser->new(-target => '1.2');

for (1..2) {

    my $frame;
    my @parts = ($message, $noop, $message, $noop, "\n");

    while (my $part = shift(@parts)) {

        if ($frame = $filter->parse($part)) {

            isa_ok($frame, "XAS::Lib::Stomp::Frame");
            like($frame->command, qr/NOOP|MESSAGE/);

        }

    }

}

$noop = $LF . $LF . $LF . "\000";
$filter = XAS::Lib::Stomp::Parser->new(-target => '1.1');

for (1..2) {

    my $frame;
    my @parts = ($message, $noop, $message);

    while (my $part = shift(@parts)) {

        if ($frame = $filter->parse($part)) {

            isa_ok($frame, "XAS::Lib::Stomp::Frame");
            like($frame->command, qr/NOOP|MESSAGE/);

        }

    }

}

$noop = $LF . $LF . $LF . "\000";
$filter = XAS::Lib::Stomp::Parser->new(-target => '1.0');

for (1..2) {

    my $frame;
    my @parts = ($message, $noop, $message);

    while (my $part = shift(@parts)) {

        if ($frame = $filter->parse($part)) {

            isa_ok($frame, "XAS::Lib::Stomp::Frame");
            like($frame->command, qr/NOOP|MESSAGE/);

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

