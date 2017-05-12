use strict;
use warnings;
use Test::More tests => 57;

BEGIN { use_ok 'Text::Tags::Parser' }

my $parser = Text::Tags::Parser->new;
isa_ok($parser, 'Text::Tags::Parser');

sub p {
    my $string = shift;
    is_deeply( [ $parser->parse_tags($string) ], [ @_ ] );
} 

p('' => );
p('foo' => 'foo');
p(' foo' => 'foo');
p('   foo' => 'foo');
p("\t foo" => 'foo');
p('foo   ' => 'foo');
p('  foo   ' => 'foo');
p('  foo   bar  ' => 'foo', 'bar');
p('  foo bar  ' => 'foo', 'bar');
p('  foo       bar     baz ' => 'foo', 'bar', 'baz');
p('  "foo"       bar     baz ' => 'foo', 'bar', 'baz');
p(q{  "foo"       bar     'baz' } => 'foo', 'bar', 'baz');
p(q{  "foo"       bar     'baz} => 'foo', 'bar', 'baz');
p(q{  "foo"       bar     "baz} => 'foo', 'bar', 'baz');
p(q{  "f\\"oo"       bar     "baz} => q(f\\), q(oo"), q(bar), q(baz));
p(q{  "f'oo"       bar     "baz} => q(f'oo), q(bar), q(baz));
p(q{I've       bar     "baz} => q(I've), q(bar), q(baz));
p(q{"eep"bap} =>  qw/eep bap/ );
p(q{"eep"'bap'} =>  qw/eep bap/ );
p(q{"eep""bap"} =>  qw/eep bap/ );
p(q{ a'b"c   } =>  q/a'b"c/ );
p(q{ a' bla  } =>  q/a'/, q/bla/ );
p(q{ a" bla  } =>  q/a"/, q/bla/ );
p(q{ "'a" bla  } =>  q/'a/, q/bla/ );
p(q{ '"a' bla  } =>  q/"a/, q/bla/ );
p(q{ "a bla  } =>  q/a bla/ );
p(q{ "" bla  } =>  q/bla/ );
p(q{ '' bla  } =>  q/bla/ );
p(q{ ""'' bla  } =>  q/bla/ );
p(q{ """" bla  } =>  q/bla/ );
p(q{ bla """" } =>  q/bla/ );
p(q{ bla '' } =>  q/bla/ );
p(q{ bla '' '' baz "" } =>  q/bla/, q/baz/ );
p(q{  "foo bar"  } => 'foo bar');
p(q{  "foo     bar"  } => 'foo bar');
p(q{  "foo bar  "  } => 'foo bar');
p(q{  "   foo bar  "  } => 'foo bar');
p(q{  'foo bar'  } => 'foo bar');
p(q{  'foo     bar'  } => 'foo bar');
p(q{  'foo bar  '  } => 'foo bar');
p(q{  '   foo bar  '  } => 'foo bar');
p(qq{  ' \t  foo bar  '  } => 'foo bar');
p(qq{  '   foo  \n bar  '  } => 'foo bar');
p(qq{  '   foo bar \n  '  } => 'foo bar');
p(qq{  '   foo  \t  \n\n \r  bar  '  } => 'foo bar');
p(qq{ foo bar foo   } => qw[foo bar]);
p(qq{ foo foo foo    bar foo   } => qw[foo bar]);
p(qq{ "foo bar" "   foo  bar    " 'foo  bar   ' baz   } => "foo bar", "baz");

p(q{a,b} => qw/a b/);
p(q{ a , b } => qw/a b/);
p(q{ a, b } => qw/a b/);
p(q{ a ,b } => qw/a b/);
p(q{ " a, b"} => 'a, b');
p(qq{ "   a   ,    \tb" c}, "a , b", "c");

ok((not defined $parser->parse_tags(undef)), "parsing undef should return undef");
