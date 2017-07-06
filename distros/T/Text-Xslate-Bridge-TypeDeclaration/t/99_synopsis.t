use strict;
use warnings;
use lib '.';
use t::helper;

use Test::More;
use Text::Xslate;

my $xslate = Text::Xslate->new(
    path         => path,
    cache_dir    => cache_dir,
    warn_handler => sub {},
    module => [
        'Text::Xslate::Bridge::TypeDeclaration',
    ],
);

like $xslate->render('template.tx', {
    name   => 'Text::Xslate',
    engine => $xslate,
}), qr/Text::Xslate version is/;

is $xslate->render('template.tx', {
    name   => 'Template::Toolkit',
    engine => 'TT',
}), <<EOS;
<pre class="type-declaration-mismatch">
Declaration mismatch for `engine`
  declaration: &#39;Text::Xslate&#39;
        value: &#39;TT&#39;
</pre>
Template::Toolkit version is .
EOS

done_testing;

__DATA__
@@ template.tx
<:- declare(name => 'Str', engine => 'Text::Xslate') -:>
<: $name :> version is <: $engine.VERSION :>.
