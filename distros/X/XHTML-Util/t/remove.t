#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use Test::Exception;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;
use Encode;

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );

my $src = join "", <DATA>;

ok( my $remove = $xu->remove($src, 'em,p.remove,center'),
    "Remove 'em,p.remove,center' from the test text"
    );

cmp_ok( $src, "ne", $remove,
        "Edited and original differ" );

# $remove =~ tr/ /+/;
# exit;

is($remove, Encode::decode_utf8(_fixed()),
   "enpara doing swimmingly");

sub _fixed {
    q{<p>Did it manually here.</p>

<p>Did it manually again in the third.</p><pre>



“triple spacing in it and an &amp;”
</pre>
<p>Didn't do it here<br/>
in<br/>
the fifth.</p>


<p>Have a <b>bold</b> here that needs a paragraph.</p>



<p>three in a row</p>

<p>and four for  matter</p>

<p>And two in a row <a href="http://localhost/a/12" title="Read&#10;more of " so="So" i="I" kinda="kinda" have="have" a="a" crush="">[read more]</a></p>

<p>
  <b>asd</b> 
</p>

<p>!</p>

<p>?</p>};

}

__DATA__
<p>Did it manually here.</p>
<p class="remove"><b>Didn't</b> <i>do it.</i></p>
<p>Did it manually again in the third.</p><pre>
<em>This is the fourth block and has</em>


“triple spacing in it and an &amp;”
</pre>
<p>Didn't do it here<br/>
in<br/>
the fifth.</p>
<p class="remove">Did it here in
the sixth mashed up against the fifth so we
could not possibly split on whitespace.</p>

<p>Have a <b>bold</b> here that needs a paragraph.</p>

<center>also need</center>

<p>three in a row</p>

<p>and four for <em>that</em> matter</p>
<p class="remove">real para back into the mix</p>
<p>And two in a row <a href="http://localhost/a/12" title="Read&#10;more of " so="So" i="I" kinda="kinda" have="have" a="a" crush="">[read more]</a></p>

<p>
  <b>asd<em>f</em></b> <em>oh noes</em>
</p>

<p>!</p>

<p>?</p>
