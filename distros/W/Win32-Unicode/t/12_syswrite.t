use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir tempfile);

use Win32::Unicode::File;
use Win32::Unicode::Dir;

my $dir = tempdir() or die $!;
my $write_file = File::Spec->catfile("$dir/森鷗外.txt");

sub newfh {
    Win32::Unicode::File->new(w => $write_file);
}

sub slurp {
    Win32::Unicode::File->new(r => shift)->slurp;
}

sub test_syswrite {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %specs = @_;
    my ($input, $expects, $expects_exception) =
        @specs{qw/input expects expects_exception/};

    my $desc = sprintf 'syswrite(%s)', join ', ', map { !defined $_ ? 'undef' : $_ } @$input;
    subtest $desc => sub {
        my $fh = newfh();
        unless ($expects_exception) {
            is $fh->syswrite(@$input), length $expects;
            ok $fh->close;
            is slurp($write_file), $expects;
        }
        else {
            dies_ok { $fh->syswrite(@$input) };
            like $@, qr/$expects_exception/;
        }
    };
}

test_syswrite(
    input   => ['foobar'],
    expects => 'foobar',
);

test_syswrite(
    input   => ['foobar', 3],
    expects => 'foo',
);

test_syswrite(
    input   => ['foobar', 0],
    expects => '',
);

test_syswrite(
    input   => ['foobar', undef],
    expects => '',
);

test_syswrite(
    input   => ['foobar', 1000],
    expects => 'foobar',
);

test_syswrite(
    input             => ['foobar', -3],
    expects_exception => 'got negative length',
);

test_syswrite(
    input   => ['foobar', 6, 3],
    expects => 'bar',
);

test_syswrite(
    input   => ['foobar', 6, 0],
    expects => 'foobar',
);

test_syswrite(
    input   => ['foobar', 6, 6],
    expects => '',
);

test_syswrite(
    input   => ['foobar', 6, -2],
    expects => 'ar',
);

test_syswrite(
    input   => ['foobar', 2, -3],
    expects => 'ba',
);

test_syswrite(
    input   => ['foobar', 6, -10],
    expects => 'foobar',
);

test_syswrite(
    input   => ['foobar', 0, 0],
    expects => '',
);

test_syswrite(
    input   => ['foobar', undef, 0],
    expects => '',
);

done_testing;
