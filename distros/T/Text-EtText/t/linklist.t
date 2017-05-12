#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("linklist");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>Let's see if the new link format works.
</p><ul><li><a href="http://webmake.taint.org/">link</a>
</li><li><a href="http://webmake.taint.org/">this is a link</a>
</li><li><a href="http://jmason.org/contact.html">Justin Mason</a> ... etc
</li><li><a href="http://jmason.org/">my homepage</a> ... etc 
</li></ul>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

