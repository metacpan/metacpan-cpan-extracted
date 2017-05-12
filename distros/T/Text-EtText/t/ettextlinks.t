#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("ettextlinks");
use Test; BEGIN { plan tests => 45 };

# ---------------------------------------------------------------------------

%patterns = (

  q{<h1>LINKS TEST</h1>},
  'header',

  q{<p>This is a test of a single-word
  <a href="http://jmason.org/">link</a>},
  '1word',

  q{same with text <a href="http://slashdot.org/">label</a>},
  '1wordtext',

  q{a <a href="http://www.ntk.net/">multi-word link test</a>.},
  'multiword',

  q{multi-word link test</a>. </p> <p>As you can see,},
  'linklistsnoemptypara',

  q{no whitespace is used in
  the link <a href="http://sitescooper.cx/">text</a>.},
  '1wordnows',

  q{a <a href="http://jmason.org/">glossary link</a>?},
  'glossary',

  q{<p>Or a <a href="http://sourceforge.net/">onewordgloslink</a>?},
  'onewordgloslink',

  q{even if they were defined
  far above. Here's a link to <a href="http://www.ntk.net/">NTK</a>},
  'definedabove',			#'

  q{screw up <a href=http://webmake.taint.org>
  traditional a hrefs</a>.},
  'tradhref',

  q{tags with embedded quotes should be OK too, even
  if they too use an EtText link... <a href="http://jmason.org/"><img
  src="http://jmason.org/license_plate.jpg" width="10" height="10"></a>.},
  'linkimg',

  q{both text and a tag in the <a href="http://sitescooper.cx/">link
  text <img src=http://sitescooper.cx/new.gif></a>.},
  'linktextandimg',

  q{hrefs on images should be OK too, like this: <a
  href=http://webmake.taint.org><img
  src="http://jmason.org/license_plate.jpg" width="10" height="10"></a>.},
  'tradhrefimg',

  q{That's it. Oh, one more -- since "test_requires_this_warning" has not be
  defined as a link label, test_requires_this_warning is not a link }, #'
  'notlink1',

  q{<p>This should be a link: <a
  href="http://webmake.taint.org/">http://webmake.taint.org/</a> .},
  'httpurl',

  q{Also <a
  href="http://webmake.taint.org">http://webmake.taint.org</a> ,},
  'httpurlnoslash',

  q{with URL: <a
  href="http://webmake.taint.org/">&lt;URL:http://webmake.taint.org/&gt;</a>
  }, 'URLurl',

  q{<p>Test links containing colons. an EtLink: <a
  href="http://www.masonhq.org/">HTML::Mason</a>,},
  'etlinkwithcolon',
  
  q{a trad link: <a href="http://www.masonhq.org/">HTML::Mason</a>. </p>},
  'tradlinkwithcolon',

  q{link: URL:<a href="http://webmake.taint.org/">http://webmake.taint.org/</a> url:<a href="http://webmake.taint.org/">http://webmake.taint.org/</a>},
  'links_with_url_header',

  q{Links follows by non-link chars:
  <a href="http://webmake.taint.org/">http://webmake.taint.org/</a>,
  <a href="http://webmake.taint.org/">http://webmake.taint.org/</a>.
  (blah blah
  <a href="http://webmake.taint.org/">http://webmake.taint.org/</a>)},
  'links_followed_by_non_link_chars',

  q{a new feature -- link text recogition: this is a <a href="http://ettext.
  taint.org/">test of linktext</a>.},
  'linktext',


);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

