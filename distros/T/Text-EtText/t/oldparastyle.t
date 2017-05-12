#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("oldparastyle");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>This text should give an
<br />example of line breaking.
<br />Hopefully.
</p><p>What about paragraphs that start with a few spaces? They should work fine, if
things are OK. work fine, if things are OK work fine, if things are OK work
fine, if things are OK work fine, if things are OK.
</p><p>This should really be counted as a second paragraph as well. Hmm, well,
let's hope that works.
</p><ul><li>another nasty is lists
</li></ul></p><p>that start at char 0
</p><ul><li>that line should not be part of the list
</li></ul>

 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

