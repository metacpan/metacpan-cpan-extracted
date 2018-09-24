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

done_testing;
