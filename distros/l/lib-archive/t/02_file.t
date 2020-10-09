#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use version;

use lib::archive "arclib/*.tgz", "./arclib/VMod4-7.0.tar.gz";

use_ok('VMod');
is( version->parse($VMod::VERSION), version->parse(1.0), 'version ok' );
like( $INC{'VMod.pm'}, qr(t/arclib/VMod.tgz/VMod.pm), 'INC path without lib' );

use_ok('VMod2');
is( version->parse($VMod2::VERSION), version->parse(2.0), 'version ok' );

use_ok('VMod3');
is( version->parse($VMod3::VERSION), version->parse(3.0), 'version ok' );
like( $INC{'VMod3.pm'}, qr(t/arclib/VMod3.tgz/lib/VMod3.pm), 'INC path with lib' );

use_ok('VMod4');
is( version->parse($VMod4::VERSION), version->parse(6.0), 'version ok' );

use_ok('VTest::VMod6');
is( version->parse($VTest::VMod6::VERSION), version->parse(7.0), 'version ok' );

done_testing();
