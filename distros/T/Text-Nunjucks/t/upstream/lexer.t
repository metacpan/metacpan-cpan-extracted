#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# 1:1 port of upstream/nunjucks/tests/lexer.js (pinned v3.2.4), one subtest
# per it(), same title, same order. The single describe('lexer', ...) wrapper
# becomes the outer subtest below.
#
# lexer.js's own local helpers (_hasTokens / hasTokens / hasTokensWithWS) are
# used by no other upstream suite (tests/util.js is the only shared-helper
# file, per the porting contract), so they stay local to this file rather
# than being promoted to t/lib/.
#
# Every expected value below is transcribed verbatim from the upstream
# assertions (the JS test source is itself the ground truth for a token type/
# value/position sequence); the three "token positions" checks and the ten
# new template shapes surfaced while porting were additionally cross-checked
# against maint/oracle.js (mode=lex) and, where they added coverage the
# existing t/corpus/lex.json lacked, committed there as new cases.

BEGIN {
  eval { require Text::Nunjucks::Lexer; 1 }
    or plan skip_all => "Text::Nunjucks::Lexer not available: $@";
}

my $L = 'Text::Nunjucks::Lexer';

#### helpers -- upstream: function _hasTokens(ws, tokens, types) / hasTokens / hasTokensWithWS

sub _has_tokens {
  my ( $ws, $tokens, @types ) = @_;
  for my $type (@types) {
    my $tok = $tokens->next_token;

    if ( !$ws ) {
      while ( $tok && $tok->type eq $L->TOKEN_WHITESPACE ) {
        $tok = $tokens->next_token;
      }
    }

    if ( ref $type eq 'ARRAY' ) {
      is( $tok->type,  $type->[0] );
      is( $tok->value, $type->[1] );
    }
    elsif ( ref $type eq 'HASH' ) {
      is( $tok->type, $type->{type} );
      is( $tok->value, $type->{value} ) if defined $type->{value};
      is( $tok->lineno, $type->{lineno} ) if defined $type->{lineno};
      is( $tok->colno, $type->{colno} ) if defined $type->{colno};
    }
    else {
      is( $tok->type, $type );
    }
  }
}

sub has_tokens {
  my ( $tokens, @types ) = @_;
  _has_tokens( 0, $tokens, @types );
}

sub has_tokens_with_ws {
  my ( $tokens, @types ) = @_;
  _has_tokens( 1, $tokens, @types );
}

subtest 'lexer' => sub {

  subtest 'should parse template data' => sub {
    my $tok = $L->lex('3')->next_token;
    is( $tok->type,  $L->TOKEN_DATA );
    is( $tok->value, '3' );

    my $tmpl = 'foo bar bizzle 3 [1,2] !@#$%^&*()<>?:"{}|';
    $tok = $L->lex($tmpl)->next_token;
    is( $tok->type,  $L->TOKEN_DATA );
    is( $tok->value, $tmpl );
  };

  subtest 'should keep track of whitespace' => sub {
    my $tokens = $L->lex("data {% 1 2\n   3  %} data");
    has_tokens_with_ws(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_BLOCK_START,
      [ $L->TOKEN_WHITESPACE, ' ' ],
      $L->TOKEN_INT,
      [ $L->TOKEN_WHITESPACE, ' ' ],
      $L->TOKEN_INT,
      [ $L->TOKEN_WHITESPACE, "\n   " ],
      $L->TOKEN_INT,
      [ $L->TOKEN_WHITESPACE, '  ' ],
      $L->TOKEN_BLOCK_END,
      $L->TOKEN_DATA
    );
  };

  subtest 'should trim blocks' => sub {
    my $tokens = $L->lex( "  {% if true %}\n    foo\n  {% endif %}\n", { trimBlocks => 1 } );
    has_tokens(
      $tokens,
      [ $L->TOKEN_DATA, '  ' ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, "    foo\n  " ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END
    );
  };

  subtest 'should trim windows-style CRLF line endings after blocks' => sub {
    my $tokens = $L->lex( "  {% if true %}\r\n    foo\r\n  {% endif %}\r\n", { trimBlocks => 1 } );
    has_tokens(
      $tokens,
      [ $L->TOKEN_DATA, '  ' ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, "    foo\r\n  " ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END
    );
  };

  subtest 'should not trim CR after blocks' => sub {
    my $tokens = $L->lex( "  {% if true %}\r    foo\r\n  {% endif %}\r", { trimBlocks => 1 } );
    has_tokens(
      $tokens,
      [ $L->TOKEN_DATA, '  ' ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, "\r    foo\r\n  " ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, "\r" ]
    );
  };

  subtest 'should lstrip and trim blocks' => sub {
    my $tokens = $L->lex(
      "test\n {% if true %}\n  foo\n {% endif %}\n</div>",
      { lstripBlocks => 1, trimBlocks => 1 }
    );
    has_tokens(
      $tokens,
      [ $L->TOKEN_DATA, "test\n" ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, "  foo\n" ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, '</div>' ]
    );
  };

  subtest 'should lstrip and not collapse whitespace between blocks' => sub {
    my $tokens = $L->lex( '   {% t %} {% t %}', { lstripBlocks => 1 } );
    has_tokens(
      $tokens,
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END,
      [ $L->TOKEN_DATA, ' ' ],
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END
    );
  };

  subtest 'should parse variable start and end' => sub {
    my $tokens = $L->lex('data {{ foo }} bar bizzle');
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_VARIABLE_END,
      $L->TOKEN_DATA
    );
  };

  subtest 'should treat the non-breaking space as valid whitespace' => sub {
    my $tokens = $L->lex("{{\x{00A0}foo }}");
    my $tok = $tokens->next_token;
    $tok = $tokens->next_token;
    $tok = $tokens->next_token;
    is( $tok->type,  $L->TOKEN_SYMBOL );
    is( $tok->value, 'foo' );
  };

  subtest 'should parse block start and end' => sub {
    my $tokens = $L->lex('data {% foo %} bar bizzle');
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_BLOCK_END,
      $L->TOKEN_DATA
    );
  };

  subtest 'should parse basic types' => sub {
    my $tokens = $L->lex(q{{{ 3 4.5 true false none foo "hello" 'boo' r/regex/ }}});
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_INT,
      $L->TOKEN_FLOAT,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_BOOLEAN,
      $L->TOKEN_NONE,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_STRING,
      $L->TOKEN_STRING,
      $L->TOKEN_REGEX,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse function calls' => sub {
    my $tokens = $L->lex('{{ foo(bar) }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      [ $L->TOKEN_SYMBOL, 'foo' ],
      $L->TOKEN_LEFT_PAREN,
      [ $L->TOKEN_SYMBOL, 'bar' ],
      $L->TOKEN_RIGHT_PAREN,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse groups' => sub {
    my $tokens = $L->lex('{{ (1, 2, 3) }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_LEFT_PAREN,
      $L->TOKEN_INT,
      $L->TOKEN_COMMA,
      $L->TOKEN_INT,
      $L->TOKEN_COMMA,
      $L->TOKEN_INT,
      $L->TOKEN_RIGHT_PAREN,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse arrays' => sub {
    my $tokens = $L->lex('{{ [1, 2, 3] }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_LEFT_BRACKET,
      $L->TOKEN_INT,
      $L->TOKEN_COMMA,
      $L->TOKEN_INT,
      $L->TOKEN_COMMA,
      $L->TOKEN_INT,
      $L->TOKEN_RIGHT_BRACKET,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse dicts' => sub {
    my $tokens = $L->lex('{{ {one:1, "two":2} }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_LEFT_CURLY,
      [ $L->TOKEN_SYMBOL, 'one' ],
      $L->TOKEN_COLON,
      [ $L->TOKEN_INT, '1' ],
      $L->TOKEN_COMMA,
      [ $L->TOKEN_STRING, 'two' ],
      $L->TOKEN_COLON,
      [ $L->TOKEN_INT, '2' ],
      $L->TOKEN_RIGHT_CURLY,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse blocks without whitespace' => sub {
    my $tokens = $L->lex('data{{hello}}{%if%}data');
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_VARIABLE_START,
      [ $L->TOKEN_SYMBOL, 'hello' ],
      $L->TOKEN_VARIABLE_END,
      $L->TOKEN_BLOCK_START,
      [ $L->TOKEN_SYMBOL, 'if' ],
      $L->TOKEN_BLOCK_END,
      $L->TOKEN_DATA
    );
  };

  subtest 'should parse filters' => sub {
    has_tokens(
      $L->lex('{{ foo|bar }}'),
      $L->TOKEN_VARIABLE_START,
      [ $L->TOKEN_SYMBOL, 'foo' ],
      $L->TOKEN_PIPE,
      [ $L->TOKEN_SYMBOL, 'bar' ],
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse operators' => sub {
    has_tokens(
      $L->lex('{{ 3+3-3*3/3 }}'),
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_VARIABLE_END
    );

    has_tokens(
      $L->lex('{{ 3**4//5 }}'),
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_VARIABLE_END
    );

    has_tokens(
      $L->lex('{{ 3 != 4 == 5 <= 6 >= 7 < 8 > 9 }}'),
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_OPERATOR,
      $L->TOKEN_INT,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should parse comments' => sub {
    my $tokens = $L->lex('data data {# comment #} data');
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_COMMENT,
      $L->TOKEN_DATA
    );
  };

  subtest 'should allow changing the variable start and end' => sub {
    my $tokens = $L->lex(
      'data {= var =}',
      { tags => { variableStart => '{=', variableEnd => '=}' } }
    );
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should allow changing the block start and end' => sub {
    my $tokens = $L->lex( '{= =}', { tags => { blockStart => '{=', blockEnd => '=}' } } );
    has_tokens(
      $tokens,
      $L->TOKEN_BLOCK_START,
      $L->TOKEN_BLOCK_END
    );
  };

  # Same title as above -- upstream lists this it() twice verbatim (mocha
  # allows duplicate titles); the duplicate is kept to match the ported
  # it()-count 1:1.
  subtest 'should allow changing the variable start and end' => sub {
    my $tokens = $L->lex(
      'data {= var =}',
      { tags => { variableStart => '{=', variableEnd => '=}' } }
    );
    has_tokens(
      $tokens,
      $L->TOKEN_DATA,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should allow changing the comment start and end' => sub {
    my $tokens = $L->lex(
      '<!-- A comment! -->',
      { tags => { commentStart => '<!--', commentEnd => '-->' } }
    );
    has_tokens( $tokens, $L->TOKEN_COMMENT );
  };

  # https://github.com/mozilla/nunjucks/issues/235
  subtest 'should have individual lexer tag settings for each environment' => sub {
    my $tokens = $L->lex( '{=', { tags => { variableStart => '{=' } } );
    has_tokens( $tokens, $L->TOKEN_VARIABLE_START );

    $tokens = $L->lex('{{');
    has_tokens( $tokens, $L->TOKEN_VARIABLE_START );

    $tokens = $L->lex( '{{', { tags => { variableStart => '<<<' } } );
    has_tokens( $tokens, $L->TOKEN_DATA );

    $tokens = $L->lex('{{');
    has_tokens( $tokens, $L->TOKEN_VARIABLE_START );
  };

  subtest 'should parse regular expressions' => sub {
    my $tokens = $L->lex('{{ r/basic regex [a-z]/ }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_REGEX,
      $L->TOKEN_VARIABLE_END
    );

    # A more complex regex with escaped slashes.
    $tokens = $L->lex('{{ r/{a*b} \/regex! [0-9]\// }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_REGEX,
      $L->TOKEN_VARIABLE_END
    );

    # This one has flags.
    $tokens = $L->lex('{{ r/^x/gim }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_REGEX,
      $L->TOKEN_VARIABLE_END
    );

    # This one has a valid flag then an invalid flag.
    $tokens = $L->lex('{{ r/x$/iv }}');
    has_tokens(
      $tokens,
      $L->TOKEN_VARIABLE_START,
      $L->TOKEN_REGEX,
      $L->TOKEN_SYMBOL,
      $L->TOKEN_VARIABLE_END
    );
  };

  subtest 'should keep track of token positions' => sub {
    has_tokens(
      $L->lex('{{ 3 != 4 == 5 <= 6 >= 7 < 8 > 9 }}'),
      { type => $L->TOKEN_VARIABLE_START, lineno => 0, colno => 0 },
      { type => $L->TOKEN_INT, value => '3', lineno => 0, colno => 3 },
      { type => $L->TOKEN_OPERATOR, value => '!=', lineno => 0, colno => 5 },
      { type => $L->TOKEN_INT, value => '4', lineno => 0, colno => 8 },
      { type => $L->TOKEN_OPERATOR, value => '==', lineno => 0, colno => 10 },
      { type => $L->TOKEN_INT, value => '5', lineno => 0, colno => 13 },
      { type => $L->TOKEN_OPERATOR, value => '<=', lineno => 0, colno => 15 },
      { type => $L->TOKEN_INT, value => '6', lineno => 0, colno => 18 },
      { type => $L->TOKEN_OPERATOR, lineno => 0, colno => 20, value => '>=' },
      { type => $L->TOKEN_INT, lineno => 0, colno => 23, value => '7' },
      { type => $L->TOKEN_OPERATOR, value => '<', lineno => 0, colno => 25 },
      { type => $L->TOKEN_INT, value => '8', lineno => 0, colno => 27 },
      { type => $L->TOKEN_OPERATOR, value => '>', lineno => 0, colno => 29 },
      { type => $L->TOKEN_INT, value => '9', lineno => 0, colno => 31 },
      { type => $L->TOKEN_VARIABLE_END, lineno => 0, colno => 33 }
    );

    has_tokens(
      $L->lex('{% if something %}{{ value }}{% else %}{{ otherValue }}{% endif %}'),
      { type => $L->TOKEN_BLOCK_START, lineno => 0, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'if', lineno => 0, colno => 3 },
      { type => $L->TOKEN_SYMBOL, value => 'something', lineno => 0, colno => 6 },
      { type => $L->TOKEN_BLOCK_END, lineno => 0, colno => 16 },
      { type => $L->TOKEN_VARIABLE_START, lineno => 0, colno => 18 },
      { type => $L->TOKEN_SYMBOL, value => 'value', lineno => 0, colno => 21 },
      { type => $L->TOKEN_VARIABLE_END, lineno => 0, colno => 27 },
      { type => $L->TOKEN_BLOCK_START, lineno => 0, colno => 29 },
      { type => $L->TOKEN_SYMBOL, value => 'else', lineno => 0, colno => 32 },
      { type => $L->TOKEN_BLOCK_END, lineno => 0, colno => 37 },
      { type => $L->TOKEN_VARIABLE_START, lineno => 0, colno => 39 },
      { type => $L->TOKEN_SYMBOL, value => 'otherValue', lineno => 0, colno => 42 },
      { type => $L->TOKEN_VARIABLE_END, lineno => 0, colno => 53 },
      { type => $L->TOKEN_BLOCK_START, lineno => 0, colno => 55 },
      { type => $L->TOKEN_SYMBOL, value => 'endif', lineno => 0, colno => 58 },
      { type => $L->TOKEN_BLOCK_END, lineno => 0, colno => 64 }
    );

    has_tokens(
      $L->lex("{% if something %}\n{{ value }}\n{% else %}\n{{ otherValue }}\n{% endif %}"),
      { type => $L->TOKEN_BLOCK_START, lineno => 0, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'if', lineno => 0, colno => 3 },
      { type => $L->TOKEN_SYMBOL, value => 'something', lineno => 0, colno => 6 },
      { type => $L->TOKEN_BLOCK_END, lineno => 0, colno => 16 },
      { type => $L->TOKEN_DATA, value => "\n" },
      { type => $L->TOKEN_VARIABLE_START, lineno => 1, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'value', lineno => 1, colno => 3 },
      { type => $L->TOKEN_VARIABLE_END, lineno => 1, colno => 9 },
      { type => $L->TOKEN_DATA, value => "\n" },
      { type => $L->TOKEN_BLOCK_START, lineno => 2, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'else', lineno => 2, colno => 3 },
      { type => $L->TOKEN_BLOCK_END, lineno => 2, colno => 8 },
      { type => $L->TOKEN_DATA, value => "\n" },
      { type => $L->TOKEN_VARIABLE_START, lineno => 3, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'otherValue', lineno => 3, colno => 3 },
      { type => $L->TOKEN_VARIABLE_END, lineno => 3, colno => 14 },
      { type => $L->TOKEN_DATA, value => "\n" },
      { type => $L->TOKEN_BLOCK_START, lineno => 4, colno => 0 },
      { type => $L->TOKEN_SYMBOL, value => 'endif', lineno => 4, colno => 3 },
      { type => $L->TOKEN_BLOCK_END, lineno => 4, colno => 9 }
    );
  };

};

done_testing;
