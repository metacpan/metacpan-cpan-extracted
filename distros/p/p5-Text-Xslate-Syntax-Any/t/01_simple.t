use strict;
use warnings;

use Test::More;
use Text::Xslate;

my $tx = Text::Xslate->new(syntax => 'Any', cache => 0, path => [ qw{ t/template } ]);

is($tx->render('index.tx',  { foo => 'Kolon' }),     q{Hello Kolon},     'Kolon');
is($tx->render('index.mtx', { foo => 'Metakolon' }), q{Hello Metakolon}, 'Metakolon');
is($tx->render('index.tt',  { foo => 'TTerse' }),    q{Hello TTerse},    'TTerse');

is($tx->render_string(q{Default syntax is <: $foo :> / [% $foo %]}, { foo => 'Kolon' }), q{Default syntax is Kolon / [% $foo %]}, 'Default syntax is Kolon');

local $Text::Xslate::Syntax::Any::DEFAULT_SYNTAX = 'TTerse';
is($tx->render_string(q{Default syntax is <: $foo :> / [% $foo %]}, { foo => 'TTerse' }), q{Default syntax is <: $foo :> / TTerse}, 'Change default syntax');

done_testing;

