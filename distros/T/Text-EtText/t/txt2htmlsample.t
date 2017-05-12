#!/usr/bin/perl -w

use lib '.'; use lib 't';
use EtTest; ettext_t_init("txt2htmlsample");
use Test; BEGIN { plan tests => 3 };

# ---------------------------------------------------------------------------

%patterns = (

 q{

<p>Parts of this text are taken from the sample document provided with
txt2html --  well, if you can't beat 'em, at least nick their documents,
<strong>then</strong> beat 'em ;)
</p><p>Let's see if the new link format works.
</p><ul><li><a href="http://webmake.taint.org/">link</a>
</li><li><a href="http://webmake.taint.org/">this is a link</a>
</li><li><a href="http://jmason.org/contact.html">Justin Mason</a> ... etc
</li><li><p><a href="http://jmason.org/">my homepage</a> ... etc 
</p></li></ul><ul><li>Handles different kinds of lists
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
<blockquote>It just needs to have enough whitespace in the line.
Surrounding blank lines aren't necessary.  If it sees enough
whitespace in a line, it preformats it.  How much is enough?
Set it yourself at command line if you want.
</blockquote></li><li><p>You can append a file automatically to all converted fi
les.  This
is handy for adding signatures to your documents.
</p></li></ul><p>This text should give an
<br />example of line breaking.
<br />Hopefully.
</p><p>What about paragraphs that start with a few spaces? They should work fine
, if
things are OK. work fine, if things are OK work fine, if things are OK work
fine, if things are OK work fine, if things are OK.  
</p><p>This should really be counted as a second paragraph as well. Hmm, well,
let's hope that works.
</p><ul><li>another nasty is lists
</li><li><p>which contain more than one paragraph in a list item.  An
earlier version of
</p><p>EtText had problems with this, instead using BLOCKQUOTE for
the middle paragraph,
</p></li><li>which just wasn't the right thing to do.
</li></ul></p>


 }, 'all',

);

# ---------------------------------------------------------------------------

ok (etrun ("< data/$testname.etx", \&patterns_run_cb));
ok_all_patterns();

