#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("etmore");
use Test; BEGIN { plan tests => 17 };

# ---------------------------------------------------------------------------

%patterns = (

  q{<blockquote>&lt;type attribute=val ...&gt;
<br />&lt;/type&gt;
   </blockquote>},
  'no_format_bug',

  q{<blockquote> [<em>label</em>]:
   <em><a href="http://url">http://url</a>...</em> </blockquote>},
  'no_ettext_link_bug',

  q{
<p>Test of lists right beside one another.
</p><ul><li>a list item
</li><li>another
</li><li>and another. This one's a bit longer though... blah blah blah
foo blah etc blah
<ul><li>nest 'em!
</li><li>again
</li></ul></li><li>and back.
</li></ul><hr />

  },
  'ettext_sardine_lists',

  q{<h2>Title right at top of page</h2>},
  'h2_title_at_top',
 
  q{<h1>Smaller title at top of page</h1>},
  'h1_title_at_top',

  q{ <hr /> <p> That was a HR. so is this: </p> <hr /> },
  'hrs_at_top',

  q{Another PRE test:
</p><p><pre>
        Bar
        [foo]
        Baz
</pre>
</p><p>Could you see the square brackets},
  'pre_sq_brackets',

  q{Balanced tags: <b>test</b>. <span class="green">foo</span>. <i
  class="green">green italics</i>},
  'balanced_tags',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

