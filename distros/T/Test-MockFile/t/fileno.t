#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile qw< strict >;

my $file = Test::MockFile->file( '/foo', '' );

my $fh;
ok( lives( sub { open $fh, '<', '/foo' } ), 'Opened file' );

like(
    dies( sub { fileno $fh } ),
    qr/\Qfileno is purposefully unsupported\E/xms,
    'Refuse to support fileno',
);

ok( lives( sub { close $fh } ), 'Opened file' );

done_testing();
exit;
