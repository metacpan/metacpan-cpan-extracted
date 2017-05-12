use Test::More tests => 14;

BEGIN { use_ok 'Text::Tags::Parser' }

my $parser = Text::Tags::Parser->new;
isa_ok($parser, 'Text::Tags::Parser');

is($parser->join_tags(), q{});
is($parser->join_tags(qw/foo bar baz/), q{foo bar baz});
is($parser->join_tags(qw/foo bar baz bar/), q{foo bar baz});
is($parser->join_tags(qw/foo bar's baz /), q{foo bar's baz});
is($parser->join_tags('foo', 'foo   bar'), q{foo "foo bar"});
is($parser->join_tags('foo', 'fo"o   bar'), q{foo 'fo"o bar'});
is($parser->join_tags('beep', 'fo"r'), q{beep fo"r});
is($parser->join_tags(q{"Foo's"}), q{"'Foo's'"});
is($parser->join_tags(q{Bob "Foo's"}), q{"Bob 'Foo's'"});
is($parser->join_tags(q{a'b"c}, 'bla'), q{"a'b'c" bla});
is($parser->join_tags(q{ab"c  bah}, 'bla'), q{'ab"c bah' bla});
is($parser->join_tags(q{ab'c  bah}, 'bla'), q{"ab'c bah" bla});
