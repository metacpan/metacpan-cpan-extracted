use strict;
use warnings;

use Test::More;

use Text::APL::Parser;

my $parser;

$parser = Text::APL::Parser->new;
is_deeply $parser->parse(''), [];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('text'), [{type => 'text', value => 'text'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<%= $foo %>'), [{type => 'expr', value => '$foo'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<%== $foo %>'),
  [{type => 'expr', value => '$foo', as_is => 1}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse("%= \$foo\n"),
  [{type => 'expr', value => '$foo', line => 1}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse("%== \$foo\n"),
  [{type => 'expr', value => '$foo', line => 1, as_is => 1}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<% $foo %>'), [{type => 'exec', value => '$foo'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse("% \$foo\n"),
  [{type => 'exec', value => '$foo', line => 1}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse("text\n% \$foo\ntext"),
  [ {type => 'text', value => "text\n"},
    {type => 'exec', value => '$foo', line => 1},
    {type => 'text', value => 'text'}
  ];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse(<<'EOF'),
And text <%= $foo %> all
<%== $foo %> over
the <% $foo %> place
    %= $foo
one
        %== $foo
two
    % $foo
three
EOF
  [ {type => 'text', value => 'And text '},
    {type => 'expr', value => '$foo'},
    {type => 'text', value => " all\n"},
    {type => 'expr', value => '$foo', as_is => 1},
    {type => 'text', value => " over\nthe "},
    {type => 'exec', value => '$foo'},
    {type => 'text', value => " place\n"},
    {type => 'expr', value => '$foo', line => 1},
    {type => 'text', value => "one\n"},
    {type => 'expr', value => '$foo', line => 1, as_is => 1},
    {type => 'text', value => "two\n"},
    {type => 'exec', value => '$foo', line => 1},
    {type => 'text', value => "three\n"},
  ];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('text <%'), [{type => 'text', value => 'text '}];
is_deeply $parser->parse(),          [{type => 'text', value => '<%'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('< '), [{type => 'text', value => '< '}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<'), [];
is_deeply $parser->parse(' '), [{type => 'text', value => '< '}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<%'), [];
is_deeply $parser->parse(), [{type => 'text', value => '<%'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<% <%'), [{type => 'text', value => '<% '}];
is_deeply $parser->parse(),        [{type => 'text', value => '<%'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse('<% '), [];
is_deeply $parser->parse('$foo %>'), [{type => 'exec', value => '$foo'}];

$parser = Text::APL::Parser->new;
is_deeply $parser->parse("text\n %"), [{type => 'text', value => "text\n"}];
is_deeply $parser->parse(), [{type => 'exec', value => '', line => 1}];

done_testing;
