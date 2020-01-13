use lib 't/lib';
use JTTest;
use XML::Invisible qw(make_parser ast2xml);

sub run_test {
  my ($grammar_text, $text, $expected_xml, $label) = @_;
  my $transformer = make_parser($grammar_text);
  my $got_data = $transformer->($text);
  is_deeply_snapshot $got_data, $label;
  eval {
    my $got_xml = ast2xml($got_data)->toStringC14N(1);
    is $got_xml, $expected_xml, "$label xml";
  };
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
