use Test2::Bundle::Extended -target => 'Test2::Plugin::IOMuxer::Layer';
use File::Temp qw/tempfile/;

{
    no warnings 'redefine';
    *Test2::Plugin::IOMuxer::Layer::time = sub() { 12345 };
}

use ok $CLASS;
ok($INC{'Test2/Plugin/OpenFixPerlIO.pm'}, "Loaded OpenFixPerlIO");

my ($fh, $name) = tempfile("$$-XXXXXXXX");
my ($mh, $muxed) = tempfile("$$-XXXXXXXX");

binmode($fh, "via($CLASS)");
$Test2::Plugin::IOMuxer::Layer::MUX_FILES{$muxed} = $mh;
$Test2::Plugin::IOMuxer::Layer::MUXED{fileno($fh)} = $muxed;

print $fh "This is a test\n";
print $fh "This is a\nmulti-line test\n";
print $fh "This is a no line-end test 1";
print $fh "This is a no line-end test 2";
print $fh "\n";
print $fh "This is the final test\n";
$fh->flush;
close($fh);
close($mh);

open($fh, '<', $name) or die "$!";
open($mh, '<', $muxed) or die "$!";

is(
    [<$fh>],
    [
        "This is a test\n",
        "This is a\n",
        "multi-line test\n",
        "This is a no line-end test 1This is a no line-end test 2\n",
        "This is the final test\n",
    ],
    "Got all lines as expected in main handle"
);

like(
    [<$mh>],
    [
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^This is a test\n$},
        qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^This is a\n$},
        qr{^multi-line test\n$},
        qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^This is a no line-end test 1\n$},
        qr{^-STOP-TEST2-SYNC-\d+: 12345\n$},
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^This is a no line-end test 2\n$},
        qr{^-STOP-TEST2-SYNC-\d+: 12345\n$},
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^\n$},
        qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
        qr{^START-TEST2-SYNC-\d+: 12345\n$},
        qr{^This is the final test\n$},
        qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
    ],
    "Got all lines as expected, with markers in mux file"
);

unlink($name);
unlink($muxed);
done_testing;
