#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("etlists");
use Test; BEGIN { plan tests => 17 };

# ---------------------------------------------------------------------------

%patterns = (

  q{
  <p>Checking lists with no start-end tags.
</p><ul><li>list 1
</li><li>l1 i2
</li><li>l1 i3
</li></ul><p>Next!
   },
  'simple_ul',

  q{
Next! I prefer this one I think.
</p><ol type="1"><li>foo
</li><li>bar
</li><li>baz
</li></ol><p>How
   },
  'simple_ol',

  q{
<p>How about definition lists?
</p><dl><dt>Foo</dt><dd>a random term
</dd><dt>Bar</dt><dd>yet another
</dd><dt>Baz</dt><dd>you get the idea.
</dd></dl><p>What
   },
  'defn_list',

  q{
<p>What about indented lists?
</p><ul><li>list 1
</li><li>l1 i2
<ul><li>l2 i1
</li><li>l2 i2
</li></ul></li><li>l1 i3
</li><li>l1 i4
<ol type="1"><li>ol2 i1
</li><li>ol2 i2
</li></ol></li><li>l1 i5
</li></ul><p>Tricky indented list
   },
  '2lists_1',

  q{
Tricky indented list -- it has 3 levels, and the innermost falls ba
ck
to the outermost. Ouch.
</p><ul><li>l1 i2
<ul><li>l2 i1
</li><li>l2 i2
<ul><li>l3 i1
</li><li>l3 i2
</li><li>l3 i3
</li></ul></li></ul></li><li>l1 i3
</li></ul><p>That's the lot
  },
  '3lists_1',

  q{
<p>That's the lot then. Oh, one more -- end on an EOF.
</p><ul><li>foo
</li></ul><p>I lied
},
  'end_on_eof',

  q{Lists where the items are right next to one another...  </p>
   <ul> <li> foo </li> <li> bar </li> <li> baz </li> <li> glorp 
   </li> <li> with a paragraph break </li> <li> and another. 
   </li> </ul>},
  'tight_lists',

  q{</ul><p>And where they look like they do on-screen in HTML:
  </p>

  <ul><li>foo2
  </li>
  <li>bar2
  </li>
  <li>baz2
  </li>
  <li>glorp2
  </li>

  <li>withpara 2
  </li>

  </ul><p>that's it.}, 'tight_lists_2',


);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

