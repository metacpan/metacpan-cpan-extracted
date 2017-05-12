#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp 'tempdir';
use Path::Class 'dir';

BEGIN {
    use_ok ( 'meon::Web::Util' ) or exit;
}

exit main();

sub main {
    my $tmp_dir = tempdir( CLEANUP => 1 );
    dir($tmp_dir, 'username')->mkpath;
    dir($tmp_dir, 'username02')->mkpath;
    dir($tmp_dir, 'a000')->mkpath;

    is(
        meon::Web::Util->username_cleanup('username', $tmp_dir),
        'username03',
        'finding username'
    );

    is(
        meon::Web::Util->username_cleanup('Štefan Bučič', $tmp_dir),
        'StefanBucic',
        'finding username'
    );

    is(
        meon::Web::Util->username_cleanup('a', $tmp_dir),
        'axxx',
        'finding username'
    );

    return 0;
}

