#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

use Test::MockFile;

pipe my $fh, my $wfh;
my $fh_str = "$fh";

my $err = dies { open my $fh2, '<', $fh };
like(
    $err,
    qr<\Q$fh_str\E>,
    'open() to read a filehandle fails',
);

ok(
    lives { open my $fh2, '<&', fileno $fh },
    'open() to dup a file descriptor works',
) or note $@;

ok(
    lives { open my $fh2, '<&=', fileno $fh },
    'open() to re-perlify a file descriptor works',
) or note $@;

done_testing;

1;
