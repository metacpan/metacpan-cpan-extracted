#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("basiclist");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>This is
</p><ul><li>a test,
</li></ul><p>really simple.
</p>


 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

