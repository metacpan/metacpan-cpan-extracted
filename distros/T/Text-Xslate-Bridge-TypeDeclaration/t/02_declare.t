use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate;

my $xslate = Text::Xslate->new(
    path         => path,
    cache_dir    => cache_dir,
    module       => [ 'Text::Xslate::Bridge::TypeDeclaration' ],
    warn_handler => sub {}, # supress error to stderr
);

is $xslate->render('one.tx', { name => 'cocoa', age => 15 }), "cocoa(15)\n";

is $xslate->render('one.tx', { name => 'chino', age => 'tippy' }), <<EOS;
<pre class="type-declaration-mismatch">
Declaration mismatch for `age`
  Value &quot;tippy&quot; did not pass type constraint &quot;Int&quot;
</pre>
chino(tippy)
EOS

is $xslate->render('two.tx', { i => 123, h => { s => 'hoge' }}),
    "i:123, h.s:hoge\n";

is $xslate->render('two.tx', { h => { s => 'hoge' } }),
    "i:, h.s:hoge\n";

is $xslate->render('two.tx', { h => { s => undef } }),
    "i:, h.s:\n";

is $xslate->render('two.tx', {}), <<EOS;
<pre class="type-declaration-mismatch">
Declaration mismatch for `h`
  Undef did not pass type constraint &quot;Dict[s=&gt;Maybe[Str],slurpy Any]&quot;
</pre>
i:, h.s:
EOS

done_testing;

__DATA__
@@ one.tx
<: declare(name => 'Str', age => 'Int') -:>
<: $name :>(<: $age :>)
@@ two.tx
<: declare(i => 'Maybe[Int]', h => { s => 'Maybe[Str]' }) -:>
i:<: $i :>, h.s:<: $h.s :>
