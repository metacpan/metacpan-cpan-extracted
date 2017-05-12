use strict;
use warnings;
package basic;

use Test::More;
use File::Spec;

require_ok("Test::InDistDir");
can_ok( "Test::InDistDir", "import" );

chdir "t" if -d "t";
@INC = grep { !/\bblib\b/ and !/\blib\b/ } @INC;

my $script = ( File::Spec->splitpath( $0 ) )[-1];

ok( !-f "t/$script", "test script not visible" );

Test::InDistDir->import;

ok( -f "t/$script", "we moved up one directory, so test script is visible" );
ok( scalar( grep { /\blib\b/ } @INC ), "lib was added to INC" );

done_testing;
