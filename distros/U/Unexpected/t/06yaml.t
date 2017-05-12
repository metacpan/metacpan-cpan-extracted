use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING} or plan skip_all => 'YAML test only for developers';
}

use English qw( -no_match_vars );

eval { require Test::YAML::Meta; };

$EVAL_ERROR and plan skip_all => 'Test::YAML::Meta not installed';

Test::YAML::Meta->import();

meta_yaml_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
