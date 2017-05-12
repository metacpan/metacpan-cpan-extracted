use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'Memory leak test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Memory::Cycle";

$EVAL_ERROR
   and plan skip_all => 'Test::Memory::Cycle required but not installed';

$ENV{TEST_MEMORY}
   or  plan skip_all => 'Environment variable TEST_MEMORY not set';

{  package MyError;
   use Moo;
   extends 'Unexpected';
   with 'Unexpected::TraitFor::ErrorLeader';
}

eval { MyError->throw( 'the error' ) }; my $e = $EVAL_ERROR;

$e->previous_exception; $e->stacktrace; $e->message;

memory_cycle_ok( $e, 'Exception has no memory cycles' );

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
