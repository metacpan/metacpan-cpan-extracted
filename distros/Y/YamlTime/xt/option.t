use Test::More tests => 3;
use Capture::Tiny 'capture_merged';

my $output = capture_merged {
    system("perl bin/yt help status");
};

like $output, qr/--from\s+Range start/, '--from option';
like $output, qr/--to\s+Range end/, '--to option';
like $output, qr/--tags\s+Comma/, '--tag option';

