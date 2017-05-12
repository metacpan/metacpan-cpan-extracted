use strict;
use Test::Usage;
use IO::Capture::Stdout;
use FindBin qw($Bin);

my $capture_stdout = IO::Capture::Stdout->new();
$capture_stdout->start();
files(
    d   => $Bin,
    i   => "$Bin/../lib",
    i2  => $Bin,
        # No colors for these tests; on Windows, Win32::Console output
        # is not captured by IO::Capture (may be possible, but FIXME
        # later).
    c => 0,
    t => {c => 0, v => 0},
);
$capture_stdout->stop();
my $got_summary = join '', $capture_stdout->read();
my $exp_summary = qr/Total \+7 -3 1d 1w \(00h:00m:0.s\) in 4 modules/;
if ($got_summary =~ /$exp_summary/) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
    print "  # Expected summary to match '$exp_summary'\n";
    print "  # But got '$got_summary'";
}
printf "1..1\n";

