#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("snakenest");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>Testing!
</p><ul><li>Handles different kinds of lists
<ol type="1"><li>Bulleted
</li><li>Numbered
<ul><li>You can nest them as far as you want.
</li><li>It's pretty decent about figuring out which level of list it
is supposed to be on.
<ul><li>You don't need to change bullet markers to start a new list.
</li></ul></li></ul></li><li>Lettered
<ol type="A"><li>Finally handles lettered lists
</li><li>Upper and lower case both work
<ol type="a"><li>Here's an example
</li><li>I've been meaning to add this for some time.
</li></ol></li><li>Of course, HTML can't specify how ordered lists should be
indicated, so it may be a numbered list in some
<br />browsers. (Ok, most browsers)
</li></ol></li></ol></li><li>Doesn't screw up mail-ish things
</li><li>Spots preformated text sometimes
</li></ul><p>Testing!
</p>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

