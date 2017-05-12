#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("blockquoteinlist");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<ul><li>Doesn't screw up mail-ish things
</li><li>Spots preformated text sometimes
<blockquote>This should be blockquoted.  It just needs to have
enough whitespace in the line, and have no list marker.
</blockquote></li><li>Blah blah blah
</li></ul>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

