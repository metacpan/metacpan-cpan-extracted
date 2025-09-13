#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use version;
use File::Path qw(remove_tree);

require lib::archive;
$ENV{PERL_LIB_ARCHIVE_IGNORE} = 'VTest/';
lib::archive->import('./arclib/VMod4-7.0.tar.gz');

use_ok('VMod4');
is( version->parse($VMod4::VERSION), version->parse(6.0), 'version ok' );

my $ret = eval { require VTest::VMod6; };
like( $@, qr'Can\'t locate VTest/VMod6.pm in @INC', 'ignored' );

$ENV{PERL_LIB_ARCHIVE_IGNORE} = '!VTest/';
lib::archive->import('./arclib/VMod5.2.4-7.0.tar.gz');

use_ok('VTest::VMod6');
is( version->parse($VTest::VMod6::VERSION), version->parse(7.0), 'version ok' );

$ret = eval { require VMod5; };
like( $@, qr'Can\'t locate VMod5.pm in @INC', 'ignored inverted' );

done_testing();
