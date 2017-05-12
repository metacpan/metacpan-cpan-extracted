# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Upskirt-Markdown.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 4;
BEGIN { use_ok('Text::Upskirt') };

my $fail = 0;
foreach my $constname (qw(
        MKDEXT_AUTOLINK MKDEXT_FENCED_CODE MKDEXT_LAX_HTML_BLOCKS
        MKDEXT_NO_INTRA_EMPHASIS MKDEXT_SPACE_HEADERS MKDEXT_STRIKETHROUGH
        HTML_SKIP_HTML HTML_SKIP_STYLE HTML_SKIP_IMAGES HTML_SKIP_LINKS
        HTML_EXPAND_TABS HTML_SAFELINK HTML_TOC HTML_HARD_WRAP
        HTML_GITHUB_BLOCKCODE HTML_USE_XHTML
)) {
  next if (eval "use Text::Upskirt qw/".$constname."/; my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Text::Upskirt macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $in = << 'EOF';
Testing
=======

* Foo
* Bar

Call me ... 'Ishmael'.
I have -- three ships named --- "The driver", "The passenger", and "The donkey"
EOF

my $rendered = << 'EOF';
<h1>Testing</h1>

<ul>
<li>Foo</li>
<li>Bar</li>
</ul>

<p>Call me ... 'Ishmael'.
I have -- three ships named --- &quot;The driver&quot;, &quot;The passenger&quot;, and &quot;The donkey&quot;</p>
EOF

my $out = Text::Upskirt::markdown($in);

ok($out eq $rendered, "Simple output");

$out = Text::Upskirt::smartypants($out);

$rendered = << 'EOF';
<h1>Testing</h1>

<ul>
<li>Foo</li>
<li>Bar</li>
</ul>

<p>Call me &hellip; &lsquo;Ishmael&rsquo;.
I have &mdash; three ships named &mdash;&ndash; &ldquo;The driver&rdquo;, &ldquo;The passenger&rdquo;, and &ldquo;The donkey&rdquo;</p>
EOF

ok($out eq $rendered, "Smarty pants");

