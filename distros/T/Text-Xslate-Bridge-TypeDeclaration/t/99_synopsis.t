use strict;
use warnings;
use lib '.';
use t::helper;

use Test::More;
use Text::Xslate;

{
    package Some::Model::User;
    sub new  { my $class = shift; bless +{ @_ }, $class }
    sub name { $_[0]->{name} }
}


my $xslate = Text::Xslate->new(
    path         => path,
    cache_dir    => cache_dir,
    warn_handler => sub {},
    module => [
        'Text::Xslate::Bridge::TypeDeclaration',
    ],
);

is $xslate->render('template.tx', +{
    user  => Some::Model::User->new(name => 'pokutuna'),
    drink => 'Cocoa',
}), <<EOS;
pokutuna is drinking a cup of Cocoa.
EOS

is $xslate->render('template.tx', +{
    user  => Some::Model::User->new(name => 'pokutuna'),
    drink => 'Oil',
}), <<EOS;
<pre class="type-declaration-mismatch">
Declaration mismatch for `drink`
  Value &quot;Oil&quot; did not pass type constraint &quot;Enum[&quot;Cocoa&quot;,&quot;Cappuchino&quot;,&quot;Tea&quot;]&quot;
</pre>
pokutuna is drinking a cup of Oil.
EOS

done_testing;

__DATA__
@@ template.tx
<:- declare(
  user  => 'Some::Model::User',
  drink => 'Enum["Cocoa", "Cappuchino", "Tea"]'
) -:>
<: $user.name :> is drinking a cup of <: $drink :>.
