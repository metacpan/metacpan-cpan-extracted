#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("menorah");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<a name="OK" id="OK"><h3>OK,</h3></a>
<ul><li>this 
<ol type="A"><li>is
<ol type="1"><li>a
</li></ol></li><li>test
</li></ol></li><li>of
</li></ul><p>yet more listiness
</p>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

