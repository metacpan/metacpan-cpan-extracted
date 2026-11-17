use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Test::More;
use FindBin qw($Bin);

my $cli = "$Bin/../bin/substitute-letters";

sub run_cli {
    my (@args) = @_;
    my $cmd = join ' ', map { "'$_'" } @args;
    my $out = `$cli $cmd 2>&1`;
    return ($?, $out);
}

subtest '--list' => sub {
    my ($rc, $out) = run_cli('--list');
    is $rc, 0, '--list exits 0';
    unlike $out, qr/Usage:/, '--list does not print usage';
    for my $style (qw( bold italic script monospace fullwidth )) {
        like $out, qr/^\Q$style\E$/m, "--list includes $style";
    }
};

subtest 'substitution via arguments' => sub {
    my ($rc, $out) = run_cli('-s', 'monospace', 'route_id');
    is $rc, 0, 'exits 0';
    chomp $out;
    my $expected = join '', map {
        $_ eq '_' ? '_' : chr(0x1D68A + ord($_) - ord('a'))
    } split //, 'route_id';
    is $out, $expected, 'letters substituted, underscore preserved';
};

subtest 'substitution via stdin' => sub {
    my $out = `echo 'abc' | $cli -s italic`;
    chomp $out;
    is $out, "\x{1D44E}\x{1D44F}\x{1D450}", 'reads stdin';
};

subtest 'help' => sub {
    for my $flag ('-h', '-?', '--help') {
        my ($rc, $out) = run_cli($flag);
        is $rc >> 8, 0, "$flag exits 0";
        like $out, qr/SYNOPSIS/, "$flag prints POD";
    }
};

subtest 'errors' => sub {
    my ($rc, $out) = run_cli('-s', 'bogus', 'x');
    is $rc >> 8, 2, 'unknown style exits 2';
    like $out, qr/Unknown style/, 'reports the bad style';
    like $out, qr/Usage:/, 'prints usage';
};

done_testing;
