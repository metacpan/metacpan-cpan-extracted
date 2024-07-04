use Kelp::Base -strict;
use Test::More;

################################################################################
# Resource role can't have any required subs because those are added at runtime
# in Kelp by modules. Because of this, the role could not be applied if the
# package was built eagerly.
################################################################################

use_ok 'Whelk::Resource';

done_testing;

