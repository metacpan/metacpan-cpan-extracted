use lib 't/lib';
use JTTest;
use XML::Invisible qw(make_parser);

sub run_test {
  my ($grammar_text, $text, $expected, $label) = @_;
  my $transformer = make_parser($grammar_text);
  is $transformer->($text)->toStringC14N(1), $expected, $label;
}

run_test(
  <<'EOF',
expr: +open -arith +close
open: /( LPAREN )/
close: /( RPAREN )/
arith: left -op right
left: +name
right: -name
name: /(a)/ | /(b)/
op: +sign
sign: /( PLUS )/
EOF
  '(a+b)',
  '<expr close=")" open="(" sign="+"><left name="a"></left><right>b</right></expr>',
  'arithmetic',
);

run_test(
  <<'EOF',
exprs: expr+
expr: expr1 | expr2
expr1: /(a)/
expr2: /(b)/
EOF
  'ab',
  '<exprs><expr><expr1>a</expr1></expr><expr><expr2>b</expr2></expr></exprs>',
  'pre-flatten',
);

run_test(
  <<'EOF',
exprs: -expr+
expr: expr1 | expr2
expr1: /(a)/
expr2: /(b)/
EOF
  'ab',
  '<exprs><expr1>a</expr1><expr2>b</expr2></exprs>',
  'flatten',
);

done_testing;
