# -*- perl -*-
use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
    use_ok('Text::Smart::HTML');
};


my $proc = Text::Smart::HTML->new();

my $input = <<EOF;
This is some =text= and this is *some*
more text in the same paragraph

We can have /some/ emphasised text and 1/2
or 3/4 or 1/4 or (C) and (R) or (TM)

* a list of stuff
* more items
* yet more

Or another para

----

+ one numbered list
+ here

&title(main heading)

&subtitle(sub heading)

&section(in here)

&subsection(or here)

&subsection(yes here)

&paragraph(final)

Thats all folks apart from \@this link to(nowhere) for a
final text
EOF

my $output = $proc->process($input);

my $expected = <<EOF;
<p>This is some <code>text</code> and this is <strong>some</strong>
more text in the same paragraph</p>



<p>We can have <em>some</em> emphasised text and &frac12;
or &frac34; or &frac14; or &copy; and &reg; or <sup>TM</sup></p>



<ul>
<li>a list of stuff
</li>

<li>more items
</li>

<li>yet more</li>
</ul>



<p>Or another para</p>



<hr>



<ol>
<li>one numbered list
</li>

<li>here</li>
</ol>



<h1>main heading</h1>



<h2>sub heading</h2>



<h3>in here</h3>



<h4>or here</h4>



<h4>yes here</h4>



<h6>final</h6>



<p>Thats all folks apart from <a href="nowhere">this link to</a> for a
final text
</p>
EOF

is($output, $expected, "output matches");


