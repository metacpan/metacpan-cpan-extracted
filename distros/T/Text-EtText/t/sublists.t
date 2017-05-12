#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("sublists");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<ul><li>this
<ul><li>is
<ul><li>a
<ul><li>test
</li></ul></li></ul></li></ul></li></ul>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

