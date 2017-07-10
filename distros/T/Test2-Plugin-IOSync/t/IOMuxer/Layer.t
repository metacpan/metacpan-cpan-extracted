use Test2::Bundle::Extended -target => 'Test2::Plugin::IOMuxer::Layer';
use File::Temp qw/tempfile/;

BEGIN { *JSON = Test2::Plugin::IOMuxer::Layer->can('JSON') }

use Test2::Plugin::IOMuxer::STDOUT;
use Test2::Plugin::IOMuxer::STDERR;
use Test2::Plugin::IOMuxer::FORMAT;

use ok $CLASS;
ok($INC{'Test2/Plugin/OpenFixPerlIO.pm'}, "Loaded OpenFixPerlIO");

my ($fha, $namea) = tempfile("$$-XXXXXXXX", TMPDIR => 1);
my ($fhb, $nameb) = tempfile("$$-XXXXXXXX", TMPDIR => 1);
my ($fhc, $namec) = tempfile("$$-XXXXXXXX", TMPDIR => 1);
my ($mh,  $muxed) = tempfile("$$-XXXXXXXX", TMPDIR => 1);

binmode($fha, "via(Test2::Plugin::IOMuxer::FORMAT)");
binmode($fhb, "via(Test2::Plugin::IOMuxer::STDERR)");
binmode($fhc, "via(Test2::Plugin::IOMuxer::STDOUT)");
$Test2::Plugin::IOMuxer::Layer::MUX_FILES{$muxed} = $mh;
$Test2::Plugin::IOMuxer::Layer::MUXED{fileno($fha)} = $muxed;
$Test2::Plugin::IOMuxer::Layer::MUXED{fileno($fhb)} = $muxed;
$Test2::Plugin::IOMuxer::Layer::MUXED{fileno($fhc)} = $muxed;

print $fha "This is a test\n";
print $fhb "Before Multiline\n";
print $fha "This is a\nmulti-line test\n";
print $fhc "After Multiline\n";
print $fha "This is a no line-end test 1";
print $fhb "combo breaker 1\n";
print $fha "This is a no line-end test 2";
print $fhc "combo breaker 2\n";
print $fha "\n";
print $fha "This is the final test\n";
$fha->flush;
$fhb->flush;
$fhc->flush;
close($fha);
close($fhb);
close($fhc);
close($mh);

open($fha, '<', $namea) or die "$!";
open($fhb, '<', $nameb) or die "$!";
open($fhc, '<', $namec) or die "$!";
open($mh, '<', $muxed) or die "$!";

is(
    [<$fha>],
    [
        "This is a test\n",
        "This is a\n",
        "multi-line test\n",
        "This is a no line-end test 1This is a no line-end test 2\n",
        "This is the final test\n",
    ],
    "Got all lines as expected in format handle"
);

is(
    [<$fhb>],
    [
        "Before Multiline\n",
        "combo breaker 1\n",
    ],
    "Got all lines as expected in stderr handle"
);

is(
    [<$fhc>],
    [
        "After Multiline\n",
        "combo breaker 2\n",
    ],
    "Got all lines as expected in stdout handle"
);

like(
    [map { JSON->new->decode($_) } <$mh>],
    [
        {name => 'format', write_no => 1, fileno => fileno($fha), buffer => "This is a test\n"},
        {name => 'stderr', write_no => 1, fileno => fileno($fhb), buffer => "Before Multiline\n"},
        {name => 'format', write_no => 2, fileno => fileno($fha), buffer => "This is a\n"},
        {name => 'format', write_no => 2, fileno => fileno($fha), buffer => "multi-line test\n"},
        {name => 'stdout', write_no => 1, fileno => fileno($fhc), buffer => "After Multiline\n"},
        {name => 'stderr', write_no => 2, fileno => fileno($fhb), buffer => "combo breaker 1\n"},
        {name => 'stdout', write_no => 2, fileno => fileno($fhc), buffer => "combo breaker 2\n"},
        {
            name     => 'format',
            write_no => 5,
            buffer   => "This is a no line-end test 1This is a no line-end test 2\n",
            fileno   => fileno($fha),
            parts    => [
                {name => 'format', write_no => 3, fileno => fileno($fha), buffer => "This is a no line-end test 1"},
                {name => 'format', write_no => 4, fileno => fileno($fha), buffer => "This is a no line-end test 2"},
                {name => 'format', write_no => 5, fileno => fileno($fha), buffer => "\n"},
                DNE(),
            ],
        },
        {name => 'format', write_no => 6, fileno => fileno($fha), buffer => "This is the final test\n"},
    ],
    "Got all expected entries"
);

unlink($namea);
unlink($nameb);
unlink($namec);
unlink($muxed);
done_testing;
