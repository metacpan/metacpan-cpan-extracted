#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use version;
use File::Path qw(remove_tree);

my $exp_dir;

BEGIN {
    $ENV{PERL_LIB_ARCHIVE_HOME} = $Bin;
    remove_tree( $exp_dir = "$Bin/.lib_archive_extract" );
}

my $under_debugger = defined($DB::single);

use lib::archive "arclib/*.tgz", "./arclib/VMod4-7.0.tar.gz";

use_ok('VMod');
is( version->parse($VMod::VERSION), version->parse(1.0), 'version ok' );
my $expect = $under_debugger ? 't/.lib_archive_extract/VMod.pm' : 't/arclib/VMod.tgz/VMod.pm';
like( my $mod_fn = $INC{'VMod.pm'}, qr($expect), 'INC path without lib' );
ok( -e $mod_fn, 'file expanded' ) if $under_debugger;

use_ok('VMod2');
is( version->parse($VMod2::VERSION), version->parse(2.0), 'version ok' );

use_ok('VMod3');
is( version->parse($VMod3::VERSION), version->parse(3.0), 'version ok' );
$expect = $under_debugger ? 't/.lib_archive_extract/VMod3.pm' : 't/arclib/VMod3.tgz/lib/VMod3.pm';
like( $mod_fn = $INC{'VMod3.pm'}, qr($expect), 'INC path with lib' );
ok( -e $mod_fn, 'file expanded' ) if $under_debugger;

use_ok('VMod4');
is( version->parse($VMod4::VERSION), version->parse(6.0), 'version ok' );

use_ok('VTest::VMod6');
is( version->parse($VTest::VMod6::VERSION), version->parse(7.0), 'version ok' );

remove_tree($exp_dir);

done_testing();
