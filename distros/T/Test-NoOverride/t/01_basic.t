use strict;
use warnings;
use Test::More;

use Test::NoOverride;

no_override('t::TestNoOverrideChild');

no_override(
    't::TestNoOverrideBrat',
    exclude => ['parent'],
);

no_override('t::TestNoOverrideNew');

no_override(
    't::TestNoOverrideCommon',
    exclude_overridden => ['t::TestNoOverrideParent::parent'],
);

if ($ENV{AUTHOR_TEST}) {
    no_override('t::TestNoOverrideBrat'); # will fail
}

done_testing;
