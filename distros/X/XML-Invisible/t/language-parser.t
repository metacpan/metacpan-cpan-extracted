use lib 't/lib';
use JTTest;
use XML::Invisible qw(make_parser ast2xml);

sub run_test {
  my ($grammar_text, $text, $expected_data, $expected_xml, $label) = @_;
  my $transformer = make_parser($grammar_text);
  my $got_data = $transformer->($text);
  is_deeply $got_data, $expected_data, "$label data"
    or diag explain $got_data;
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
  {
    nodename => 'expr',
    type => 'element',
    attributes => { open => '(', sign => '+', close => ')' },
    children => [
      {
        nodename => 'left',
        type => 'element',
        attributes => { name => 'a' },
      },
      { nodename => 'right', type => 'element', children => [ 'b' ] },
    ],
  },
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
  {
    'children' => [
      {
        'children' => [
          { 'children' => [ 'a' ], 'nodename' => 'expr1', 'type' => 'element' }
        ],
        'nodename' => 'expr',
        'type' => 'element'
      },
      {
        'children' => [
          { 'children' => [ 'b' ], 'nodename' => 'expr2', 'type' => 'element' }
        ],
        'nodename' => 'expr',
        'type' => 'element'
      }
    ],
    'nodename' => 'exprs',
    'type' => 'element'
  },
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
  {
    'children' => [
      { 'children' => [ 'a' ], 'nodename' => 'expr1', 'type' => 'element' },
      { 'children' => [ 'b' ], 'nodename' => 'expr2', 'type' => 'element' }
    ],
    'nodename' => 'exprs',
    'type' => 'element'
  },
  '<exprs><expr1>a</expr1><expr2>b</expr2></exprs>',
  'flatten',
);

done_testing;
