#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use XHTML::Util;

ok( my $xu = XHTML::Util->new,
    "XHTML::Util->new " );

# my $src = encode_utf8(join "", <DATA>);
# binmode DATA;
my $src = join "", <DATA>;

ok( my $paras = $xu->enpara($src, "div#whatever,blockquote.enpara,pre"),
    "enpara the test text"
    );

cmp_ok($paras, "ne", $src,
   "Conversion differs from source (as it should)");

is($paras, _fixed(),
   "enpara doing swimmingly");

sub _fixed {
    q{<div>
One.
</div><div id="whatever">
<p>Two.</p>

<p>Three.</p>
</div><blockquote>
None.
</blockquote><blockquote class="enpara">
<p>One.</p>

<p>Two.</p>
</blockquote><pre>
say "oh hai!";
</pre>};
}

__DATA__
<div>
One.
</div>

<div id="whatever">
Two.

Three.
</div>

<blockquote>
None.
</blockquote>

<blockquote class="enpara">
One.

Two.
</blockquote>

<pre>
say "oh hai!";
</pre>
