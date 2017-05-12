#!/usr/bin/perl
use strict;
use warnings;
use Test::More "no_plan";
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );

ok( my $fixed = $xu->_sanitize_fragment(join"",<DATA>),
    "Sanitize a messed up piece of \"HTML\""
    );

is($fixed, fixed(),
   "Fixed it" );

sub fixed {
    <<"";
<p class="&quot;monkey&quot; shines" id="googly">
   <b>OH</b> HAI <span>&gt; OH NOES!</span>! <i>&amp;</i>&amp;<br style="clear:both"/>YOU CAN HAS &lt;ANYTHINGS&gt;.
</p>

}

__DATA__
<p class='"monkey" shines' id = googly>
   <b>OH</b> HAI <span>> OH NOES!</span>! <i>&</i>&<br style="clear:both"/>YOU CAN HAS <ANYTHINGS>.
</p>
