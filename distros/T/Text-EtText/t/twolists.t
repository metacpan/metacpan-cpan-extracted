#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("twolists");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>this
</p><ul><li>is a
</li></ul><ul><li>test, for sure
</li></ul><p>should not be pre
</p>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

