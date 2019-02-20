package #
    Test::Differences::TestUtils::Capture;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT = qw(capture_error);

use Capture::Tiny qw(capture);

sub capture_error(&) {
    my $sub = shift;
    my($stdout, $stderr) = capture { $sub->() };
    $stderr =~ s/^\s+//; # see https://github.com/Ovid/Test-Differences/issues/15
    return $stderr;
}

1;
