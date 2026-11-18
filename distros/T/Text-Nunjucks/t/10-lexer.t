#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Perl-side unit tests for Text::Nunjucks::Lexer (port of src/lexer.js). The
# full upstream lexer suite (tests/lexer.js) is ported separately under
# t/upstream/; the oracle-generated token dumps live in t/corpus/lex.json. This
# file drives the Perl API directly -- the tokenizer/token object shape the
# corpus harness relies on, position tracking across newlines, whitespace
# control, comments, trim/lstrip, per-instance tag settings, the regex token
# value shape (k7), and the TOKEN_* export surface. Every token type/value/
# position asserted here was confirmed with maint/oracle.js.

use_ok('Text::Nunjucks::Lexer');
use_ok('Text::Nunjucks::Lexer::Token');
use_ok('Text::Nunjucks::Lexer::Tokenizer');

my $L = 'Text::Nunjucks::Lexer';

# Collect every token as a plain [type, value] pair (undef value stays undef).
sub pairs {
  my ( $tmpl, $opts ) = @_;
  my $t = $L->lex( $tmpl, $opts );
  my @out;
  while ( my $tok = $t->next_token ) {
    push @out, [ $tok->type, $tok->value ];
  }
  return \@out;
}

# The type sequence with whitespace tokens dropped (upstream hasTokens helper).
sub types_no_ws {
  my ( $tmpl, $opts ) = @_;
  return [ map { $_->[0] } grep { $_->[0] ne 'whitespace' } @{ pairs( $tmpl, $opts ) } ];
}

#### tokenizer / token object shape (the corpus harness contract)

subtest 'lex returns a tokenizer yielding token objects' => sub {
  my $t = $L->lex('{{ a }}');
  isa_ok( $t, 'Text::Nunjucks::Lexer::Tokenizer', 'lex()' );
  can_ok( $t, 'next_token' );

  my $tok = $t->next_token;
  isa_ok( $tok, 'Text::Nunjucks::Lexer::Token', 'next_token' );
  can_ok( $tok, qw( type value lineno colno ) );
  is( $tok->type,   'variable-start', 'first token type' );
  is( $tok->value,  '{{',             'first token value' );
  is( $tok->lineno, 0,                'lineno is 0-based' );
  is( $tok->colno,  0,                'colno is 0-based' );
};

subtest 'next_token returns falsy at end of input' => sub {
  my $t = $L->lex('x');
  ok( $t->next_token,   'one data token' );
  ok( !$t->next_token,  'then exhausted (undef/false)' );
  ok( !$t->next_token,  'stays exhausted' );
};

#### plain data / variable / block framing

subtest 'template data is one data token' => sub {
  my $tmpl = 'foo bar bizzle 3 [1,2] !@#$%^&*()<>?:"{}|';
  is_deeply( pairs('3'),    [ [ 'data', '3' ] ],       'single char data' );
  is_deeply( pairs($tmpl),  [ [ 'data', $tmpl ] ],     'raw text is verbatim data' );
};

subtest 'dollar, at-sign and backslash are literal data' => sub {
  is_deeply( pairs('a $b @c \\d'), [ [ 'data', 'a $b @c \\d' ] ],
    'sigils and backslash pass through untouched' );
};

subtest 'variable start and end' => sub {
  is_deeply(
    types_no_ws('data {{ foo }} bar'),
    [qw( data variable-start symbol variable-end data )],
    'framing around a variable'
  );
};

subtest 'block start and end' => sub {
  is_deeply(
    types_no_ws('data {% foo %} bar'),
    [qw( data block-start symbol block-end data )],
    'framing around a block'
  );
};

subtest 'blocks without whitespace' => sub {
  is_deeply(
    types_no_ws('data{{hello}}{%if%}data'),
    [qw( data variable-start symbol variable-end block-start symbol block-end data )],
    'no whitespace needed to break tokens'
  );
};

#### the value kinds inside code

subtest 'basic types' => sub {
  is_deeply(
    types_no_ws(q{{{ 3 4.5 true false none foo "hello" 'boo' r/regex/ }}}),
    [qw( variable-start int float boolean boolean none symbol string string regex variable-end )],
    'int/float/boolean/none/symbol/string/regex'
  );
};

subtest 'null lexes as a none token' => sub {
  is_deeply( types_no_ws('{{ null }}'),
    [qw( variable-start none variable-end )], 'null -> none' );
};

subtest 'integers and floats' => sub {
  is_deeply(
    [ grep { $_->[0] =~ /int|float/ } @{ pairs('{{ 42 }}') } ],
    [ [ 'int', '42' ] ],
    'digits are an int'
  );
  is_deeply(
    [ grep { $_->[0] =~ /int|float/ } @{ pairs('{{ 12.5 }}') } ],
    [ [ 'float', '12.5' ] ],
    'a dot after digits makes a float'
  );
  # A leading minus is never part of a number: '-' is a delimiter, tokenised as
  # its own operator before the int regex ever sees a sign (oracle-confirmed).
  is_deeply(
    types_no_ws('{{ -1 }}'),
    [qw( variable-start operator int variable-end )],
    'a minus in front of a number is a separate operator token'
  );
};

subtest 'string escape sequences' => sub {
  # 'a\tb' -> a<TAB>b ; \n and \r likewise ; an unknown escape keeps the char
  my ($tok) = grep { $_->[0] eq 'string' } @{ pairs(q{{{ 'a\tb\n\r\q' }}}) };
  is( $tok->[1], "a\tb\n\r" . 'q', 'n/t/r decoded, unknown escape passes the char through' );
};

#### operators and delimiters

subtest 'arithmetic operators are operator tokens' => sub {
  is_deeply(
    types_no_ws('{{ 3+3-3*3/3 }}'),
    [qw( variable-start int operator int operator int operator int operator int variable-end )],
    'plus/minus/times/divide'
  );
};

subtest 'complex operators pow and floordiv' => sub {
  is_deeply(
    types_no_ws('{{ 3**4//5 }}'),
    [qw( variable-start int operator int operator int variable-end )],
    '** and // each one operator token'
  );
};

subtest 'strict-comparison operators' => sub {
  my $ops = [ grep { $_->[0] eq 'operator' } @{ pairs('{{ a===b !== c }}') } ];
  is_deeply( [ map { $_->[1] } @$ops ], [ '===', '!==' ],
    'triple === and !== consume all three chars' );
};

subtest 'brackets, braces, comma, colon, tilde, pipe get their own types' => sub {
  is_deeply(
    types_no_ws('{{ (a)[b]{c}~d|e:f,g }}'),
    [qw(
      variable-start left-paren symbol right-paren
      left-bracket symbol right-bracket
      left-curly symbol right-curly
      tilde symbol pipe symbol colon symbol comma symbol variable-end
    )],
    'each delimiter maps to its token type'
  );
};

subtest 'filters use the pipe token' => sub {
  is_deeply(
    pairs('{{ foo|bar }}'),
    [
      [ 'variable-start', '{{' ], [ 'whitespace', ' ' ],
      [ 'symbol', 'foo' ], [ 'pipe', '|' ], [ 'symbol', 'bar' ],
      [ 'whitespace', ' ' ], [ 'variable-end', '}}' ]
    ],
    'foo|bar (pipe between the two symbols)'
  );
};

subtest 'dict literal' => sub {
  is_deeply(
    types_no_ws('{{ {one:1, "two":2} }}'),
    [qw(
      variable-start left-curly symbol colon int comma
      string colon int right-curly variable-end
    )],
    'bare key is a symbol, quoted key is a string'
  );
};

#### whitespace tracking

subtest 'whitespace is tracked as its own tokens' => sub {
  is_deeply(
    pairs("data {% 1 2\n   3  %} data"),
    [
      [ 'data',        'data ' ],
      [ 'block-start', '{%' ],
      [ 'whitespace',  ' ' ],
      [ 'int',         '1' ],
      [ 'whitespace',  ' ' ],
      [ 'int',         '2' ],
      [ 'whitespace',  "\n   " ],
      [ 'int',         '3' ],
      [ 'whitespace',  '  ' ],
      [ 'block-end',   '%}' ],
      [ 'data',        ' data' ]
    ],
    'whitespace runs (including a newline run) are preserved verbatim'
  );
};

subtest 'the non-breaking space counts as whitespace' => sub {
  my $t = $L->lex("{{\x{00A0}foo }}");
  $t->next_token;                # variable-start
  my $ws = $t->next_token;
  is( $ws->type,  'whitespace',  'nbsp is a whitespace token' );
  is( $ws->value, "\x{00A0}",    'its value is the nbsp itself' );
  is( $t->next_token->value, 'foo', 'the symbol follows' );
};

subtest 'token positions across newlines' => sub {
  # {% if something %}\n{{ value }}\n{% else %} ... -- pin the newline-crossing
  # positions the oracle reports (lineno/colno reset to 0-based new line).
  my @toks;
  my $t = $L->lex("{% if something %}\n{{ value }}\n{% endif %}");
  while ( my $tok = $t->next_token ) {
    push @toks, $tok unless $tok->type eq 'whitespace';
  }
  # Non-whitespace stream (data tokens kept): the two "\n" data tokens sit
  # between the tags, so the indices step over them.
  #  0 block-start(0,0)  1 if(0,3)  2 something(0,6)  3 block-end(0,16)
  #  4 data "\n"         5 variable-start(1,0)  6 value(1,3)  7 variable-end(1,9)
  #  8 data "\n"         9 block-start(2,0)  10 endif(2,3)  11 block-end(2,9)
  is( $toks[5]->type,    'variable-start', 'variable-start after first newline' );
  is( $toks[5]->lineno,  1,                '... on line 1' );
  is( $toks[5]->colno,   0,                '... at column 0' );
  is( $toks[6]->value,   'value',          'symbol on line 1' );
  is( $toks[6]->colno,   3,                '... at column 3' );
  is( $toks[10]->value,  'endif',          'endif on line 2' );
  is( $toks[10]->lineno, 2,                '... line 2' );
  is( $toks[10]->colno,  3,                '... column 3' );
};

#### whitespace control

subtest 'whitespace control markers are part of the tag value' => sub {
  my $p = pairs('a {%- if x -%} b {{- y -}} c');
  # find the framing tokens
  my %seen = map { $_->[0] => $_->[1] } @$p;
  is( $seen{'block-start'},    '{%-', 'block-start carries the dash' );
  is( $seen{'block-end'},      '-%}', 'block-end carries the dash' );
  is( $seen{'variable-start'}, '{{-', 'variable-start carries the dash' );
  is( $seen{'variable-end'},   '-}}', 'variable-end carries the dash' );
  is( $p->[0][1], 'a ', 'leading data kept verbatim (dash trimming is the parser step)' );
};

#### comments

subtest 'comments are a single comment token' => sub {
  is_deeply(
    pairs('data {# comment #} data'),
    [
      [ 'data',    'data ' ],
      [ 'comment', '{# comment #}' ],
      [ 'data',    ' data' ]
    ],
    'the comment token includes its delimiters'
  );
};

#### trim / lstrip

subtest 'trimBlocks eats the newline after a block-end' => sub {
  is_deeply(
    pairs( "{% if x %}\ny\n{% endif %}\n", { trimBlocks => 1 } ),
    [
      [ 'block-start', '{%' ], [ 'whitespace', ' ' ], [ 'symbol', 'if' ],
      [ 'whitespace', ' ' ],  [ 'symbol', 'x' ], [ 'whitespace', ' ' ],
      [ 'block-end', '%}' ],
      [ 'data', "y\n" ],
      [ 'block-start', '{%' ], [ 'whitespace', ' ' ], [ 'symbol', 'endif' ],
      [ 'whitespace', ' ' ], [ 'block-end', '%}' ]
    ],
    'the \n right after %} is dropped, the one before endif stays'
  );
};

subtest 'trimBlocks handles a CRLF after a block-end (exercises back())' => sub {
  # The \r without a following \n path is what forces back(); make sure the
  # \r\n after each block is trimmed and a lone-ish sequence stays intact.
  my $data = [ grep { $_->[0] eq 'data' } @{ pairs("  {% if true %}\r\n    foo\r\n  {% endif %}\r\n", { trimBlocks => 1 }) } ];
  is_deeply(
    [ map { $_->[1] } @$data ],
    [ '  ', "    foo\r\n  " ],
    'CRLF right after %} is trimmed; interior CRLF preserved'
  );
};

subtest 'lstripBlocks strips block leading whitespace and can collapse to the next token' => sub {
  is_deeply(
    pairs( '   {% t %} {% t %}', { lstripBlocks => 1 } ),
    [
      [ 'block-start', '{%' ], [ 'whitespace', ' ' ], [ 'symbol', 't' ], [ 'whitespace', ' ' ], [ 'block-end', '%}' ],
      [ 'data', ' ' ],
      [ 'block-start', '{%' ], [ 'whitespace', ' ' ], [ 'symbol', 't' ], [ 'whitespace', ' ' ], [ 'block-end', '%}' ]
    ],
    'the leading three spaces collapse away; the single space between blocks stays'
  );
};

#### regex token (k7 touch point)

subtest 'regex token value is a { body, flags } hashref' => sub {
  my ($tok) = grep { $_->type eq 'regex' } _all('{{ r/^h.l/gi }}');
  is( ref $tok->value, 'HASH', 'value is a hashref' );
  is( $tok->value->{body},  '^h.l', 'body captured without the r/ .. / wrapper' );
  is( $tok->value->{flags}, 'gi',   'flags captured' );
};

subtest 'regex escaped slash does not end the body' => sub {
  my ($tok) = grep { $_->type eq 'regex' } _all('{{ r/a\\/b/ }}');
  is( $tok->value->{body},  'a\\/b', 'the escaped slash stays in the body' );
  is( $tok->value->{flags}, '',      'no flags' );
};

subtest 'regex stops flag scan at the first non-flag char' => sub {
  # r/x$/iv : i is a flag, v is not -> flags 'i', then a symbol 'v'
  my @toks = _all('{{ r/x$/iv }}');
  my ($re) = grep { $_->type eq 'regex' } @toks;
  is( $re->value->{flags}, 'i', 'valid flag i taken' );
  my ($sym) = grep { $_->type eq 'symbol' } @toks;
  is( $sym->value, 'v', 'the invalid flag becomes a symbol token' );
};

#### per-instance tag settings (upstream bug #235)

subtest 'tag settings are per lex() call, not global' => sub {
  is_deeply( types_no_ws( '{=', { tags => { variableStart => '{=' } } ),
    ['variable-start'], 'custom variableStart recognised' );
  is_deeply( types_no_ws('{{'), ['variable-start'],
    'the default {{ still works afterwards' );
  is_deeply( types_no_ws( '{{', { tags => { variableStart => '<<<' } } ),
    ['data'], 'overriding variableStart makes {{ plain data' );
  is_deeply( types_no_ws('{{'), ['variable-start'],
    'and the default is untouched by that other instance' );
};

subtest 'changing the comment delimiters' => sub {
  is_deeply(
    types_no_ws( '<!-- A comment! -->',
      { tags => { commentStart => '<!--', commentEnd => '-->' } } ),
    ['comment'],
    'custom comment tags produce a comment token'
  );
};

#### TOKEN_* export surface (mirrors module.exports)

subtest 'TOKEN_* type strings are exposed as class methods' => sub {
  is( $L->TOKEN_STRING,         'string',         'TOKEN_STRING' );
  is( $L->TOKEN_WHITESPACE,     'whitespace',     'TOKEN_WHITESPACE' );
  is( $L->TOKEN_DATA,           'data',           'TOKEN_DATA' );
  is( $L->TOKEN_BLOCK_START,    'block-start',    'TOKEN_BLOCK_START' );
  is( $L->TOKEN_BLOCK_END,      'block-end',      'TOKEN_BLOCK_END' );
  is( $L->TOKEN_VARIABLE_START, 'variable-start', 'TOKEN_VARIABLE_START' );
  is( $L->TOKEN_VARIABLE_END,   'variable-end',   'TOKEN_VARIABLE_END' );
  is( $L->TOKEN_COMMENT,        'comment',        'TOKEN_COMMENT' );
  is( $L->TOKEN_LEFT_PAREN,     'left-paren',     'TOKEN_LEFT_PAREN' );
  is( $L->TOKEN_RIGHT_PAREN,    'right-paren',    'TOKEN_RIGHT_PAREN' );
  is( $L->TOKEN_LEFT_BRACKET,   'left-bracket',   'TOKEN_LEFT_BRACKET' );
  is( $L->TOKEN_RIGHT_BRACKET,  'right-bracket',  'TOKEN_RIGHT_BRACKET' );
  is( $L->TOKEN_LEFT_CURLY,     'left-curly',     'TOKEN_LEFT_CURLY' );
  is( $L->TOKEN_RIGHT_CURLY,    'right-curly',    'TOKEN_RIGHT_CURLY' );
  is( $L->TOKEN_OPERATOR,       'operator',       'TOKEN_OPERATOR' );
  is( $L->TOKEN_COMMA,          'comma',          'TOKEN_COMMA' );
  is( $L->TOKEN_COLON,          'colon',          'TOKEN_COLON' );
  is( $L->TOKEN_TILDE,          'tilde',          'TOKEN_TILDE' );
  is( $L->TOKEN_PIPE,           'pipe',           'TOKEN_PIPE' );
  is( $L->TOKEN_INT,            'int',            'TOKEN_INT' );
  is( $L->TOKEN_FLOAT,          'float',          'TOKEN_FLOAT' );
  is( $L->TOKEN_BOOLEAN,        'boolean',        'TOKEN_BOOLEAN' );
  is( $L->TOKEN_NONE,           'none',           'TOKEN_NONE' );
  is( $L->TOKEN_SYMBOL,         'symbol',         'TOKEN_SYMBOL' );
  is( $L->TOKEN_SPECIAL,        'special',        'TOKEN_SPECIAL' );
  is( $L->TOKEN_REGEX,          'regex',          'TOKEN_REGEX' );
};

#### ADR 0005 -- JS \s (lstripBlocks /^\s+$/), flag-independent (F1)

subtest 'lstripBlocks strips a non-breaking space regardless of the UTF-8 flag' => sub {
  # The headline F1 bug: Perl default \s matches U+00A0 only on a UTF-8-flagged
  # SV, so a byte/latin-1 template lexed differently from a decoded one. The
  # explicit class under /u must strip NBSP either way. (The corpus harness
  # always feeds a flagged SV, so this SV-flag axis lives here, not there.)
  for my $flag ( 0, 1 ) {
    my $tmpl = "x\n\x{a0}{% t %}";
    if   ($flag) { utf8::upgrade($tmpl) }
    else         { utf8::downgrade($tmpl) }
    my ($data) = grep { $_->[0] eq 'data' } @{ pairs( $tmpl, { lstripBlocks => 1 } ) };
    is( $data->[1], "x\n", 'NBSP stripped with the UTF-8 flag ' . ( $flag ? 'on' : 'off' ) );
  }
};

subtest 'JS whitespace-class membership at the boundary (ADR 0005)' => sub {
  # U+FEFF (BOM / ZWNBSP) IS JS \s but is not matched by Perl \s even on a
  # flagged SV -- this is the case the corpus regression catches.
  my ($feff) = grep { $_->[0] eq 'data' } @{ pairs( "x\n\x{feff}{% t %}", { lstripBlocks => 1 } ) };
  is( $feff->[1], "x\n", 'U+FEFF is stripped (in JS \s)' );

  # U+0085 (NEL) is White_Space to Perl /u but NOT part of JS \s -> kept.
  my ($nel) = grep { $_->[0] eq 'data' } @{ pairs( "x\n\x{85}{% t %}", { lstripBlocks => 1 } ) };
  is( $nel->[1], "x\n\x{85}", 'U+0085 (NEL) is kept (not in JS \s)' );
};

#### float with a trailing dot at end of input (F2)

subtest 'a trailing dot with no fractional digits at EOF stringifies the JS null' => sub {
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my ($f) = grep { $_->type eq 'float' } _all('{{3.');
  is( $f->value, '3.null', 'JS `"3" + "." + null` -> "3.null"' );
  is( scalar(@warns), 0, 'no uninitialized-value warning' );
};

done_testing;

# Collect the full token object list (not just [type,value]) for regex assertions.
sub _all {
  my ( $tmpl, $opts ) = @_;
  my $t = $L->lex( $tmpl, $opts );
  my @out;
  while ( my $tok = $t->next_token ) { push @out, $tok }
  return @out;
}
