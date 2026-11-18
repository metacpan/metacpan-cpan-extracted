package Text::Nunjucks::Parser::Parser;
# ABSTRACT: The recursive-descent parser (parser.js class Parser)

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( blessed );
use builtin qw( true false );
use Text::Nunjucks::Lexer;
use Text::Nunjucks::Nodes;
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::TemplateError;
use Text::Nunjucks::Lib::Error;
use namespace::autoclean;

no warnings 'experimental::builtin';

# upstream: class Parser extends Obj in parser.js (ADR 0002: a Moo class).

# init(tokens): this.tokens / this.peeked = null / this.breakOnBlocks = null /
# this.dropLeadingWhitespace = false / this.extensions = []. Field spelling
# follows upstream (breakOnBlocks, dropLeadingWhitespace) as Lexer keeps
# trimBlocks; the mutated state is rw.
has tokens                => ( is => 'rw' );
has peeked                => ( is => 'rw' );
has breakOnBlocks         => ( is => 'rw' );
has dropLeadingWhitespace => ( is => 'rw', default => sub { 0 } );
has extensions            => ( is => 'rw', default => sub { [] } );

# new Parser(tokens): positional constructor.
around BUILDARGS => sub {
  my ( $orig, $class, $tokens ) = @_;
  return $class->$orig( tokens => $tokens );
};

# Collaborators named once (house rule); mirror parser.js's `lexer`, `nodes`
# and `lib` module references and the two error constructors.
sub lexer                { 'Text::Nunjucks::Lexer' }
sub lib                  { 'Text::Nunjucks::Lib' }
sub nodes_module         { 'Text::Nunjucks::Nodes' }
sub template_error_class { 'Text::Nunjucks::Lib::TemplateError' }
sub error_class          { 'Text::Nunjucks::Lib::Error' }

# nodes.X -> the concrete node class; one resolver so a subclass can redirect.
sub node {
  my ( $self, $name ) = @_;
  return 'Text::Nunjucks::Nodes::' . $name;
}

# JS String.prototype.charAt: '' outside [0, length). Used by the block-end /
# variable-end / whitespace-control checks below, where Perl's substr differs
# (negative offsets wrap). Same helper the Tokenizer keeps.
sub _char_at {
  my ( $self, $str, $i ) = @_;
  return '' if $i < 0 || $i >= length($str);
  return substr( $str, $i, 1 );
}

sub next_token {
  my ( $self, $with_whitespace ) = @_;
  my $tok;

  if ( $self->peeked ) {
    if ( !$with_whitespace && $self->peeked->type eq $self->lexer->TOKEN_WHITESPACE ) {
      $self->peeked(undef);
    }
    else {
      $tok = $self->peeked;
      $self->peeked(undef);
      return $tok;
    }
  }

  $tok = $self->tokens->next_token;

  if ( !$with_whitespace ) {
    while ( $tok && $tok->type eq $self->lexer->TOKEN_WHITESPACE ) {
      $tok = $self->tokens->next_token;
    }
  }

  return $tok;
}

sub peek_token {
  my ($self) = @_;
  $self->peeked( $self->peeked || $self->next_token );
  return $self->peeked;
}

sub push_token {
  my ( $self, $tok ) = @_;
  if ( $self->peeked ) {
    die $self->error_class->new('pushToken: can only push one token on between reads');
  }
  $self->peeked($tok);
}

sub error {
  my ( $self, $msg, $lineno, $colno ) = @_;
  if ( !defined $lineno || !defined $colno ) {
    my $tok = $self->peek_token;    # JS: this.peekToken() || {}
    $lineno = $tok ? $tok->lineno : undef;
    $colno  = $tok ? $tok->colno  : undef;
  }
  $lineno += 1 if defined $lineno;
  $colno  += 1 if defined $colno;
  return $self->template_error_class->new( $msg, $lineno, $colno );
}

sub fail {
  my ( $self, $msg, $lineno, $colno ) = @_;
  die $self->error( $msg, $lineno, $colno );
}

sub skip {
  my ( $self, $type ) = @_;
  my $tok = $self->next_token;
  if ( !$tok || $tok->type ne $type ) {
    $self->push_token($tok);
    return 0;
  }
  return 1;
}

sub expect {
  my ( $self, $type ) = @_;
  my $tok = $self->next_token;
  if ( $tok->type ne $type ) {
    $self->fail( 'expected ' . $type . ', got ' . $tok->type,
      $tok->lineno, $tok->colno );
  }
  return $tok;
}

sub skip_value {
  my ( $self, $type, $val ) = @_;
  my $tok = $self->next_token;
  if ( !$tok || $tok->type ne $type || $tok->value ne $val ) {
    $self->push_token($tok);
    return 0;
  }
  return 1;
}

sub skip_symbol {
  my ( $self, $val ) = @_;
  return $self->skip_value( $self->lexer->TOKEN_SYMBOL, $val );
}

sub advance_after_block_end {
  my ( $self, $name ) = @_;
  my $tok;
  if ( !defined $name ) {
    $tok = $self->peek_token;

    if ( !$tok ) {
      $self->fail('unexpected end of file');
    }

    if ( $tok->type ne $self->lexer->TOKEN_SYMBOL ) {
      $self->fail( 'advanceAfterBlockEnd: expected symbol token or '
          . 'explicit name to be passed' );
    }

    $name = $self->next_token->value;
  }

  $tok = $self->next_token;

  if ( $tok && $tok->type eq $self->lexer->TOKEN_BLOCK_END ) {
    if ( $self->_char_at( $tok->value, 0 ) eq '-' ) {
      $self->dropLeadingWhitespace(1);
    }
  }
  else {
    $self->fail( 'expected block end in ' . $name . ' statement' );
  }

  return $tok;
}

sub advance_after_variable_end {
  my ($self) = @_;
  my $tok = $self->next_token;

  if ( $tok && $tok->type eq $self->lexer->TOKEN_VARIABLE_END ) {
    $self->dropLeadingWhitespace(
      $self->_char_at(
        $tok->value,
        length( $tok->value ) - length( $self->tokens->tags->{VARIABLE_END} ) - 1
      ) eq '-' ? 1 : 0
    );
  }
  else {
    $self->push_token($tok);
    $self->fail('expected variable end');
  }
}

sub parse_for {
  my ($self) = @_;
  my $for_tok = $self->peek_token;
  my $node;
  my $end_block;

  if ( $self->skip_symbol('for') ) {
    $node      = $self->node('For')->new( $for_tok->lineno, $for_tok->colno );
    $end_block = 'endfor';
  }
  elsif ( $self->skip_symbol('asyncEach') ) {
    $node      = $self->node('AsyncEach')->new( $for_tok->lineno, $for_tok->colno );
    $end_block = 'endeach';
  }
  elsif ( $self->skip_symbol('asyncAll') ) {
    $node      = $self->node('AsyncAll')->new( $for_tok->lineno, $for_tok->colno );
    $end_block = 'endall';
  }
  else {
    $self->fail( 'parseFor: expected for{Async}', $for_tok->lineno, $for_tok->colno );
  }

  $node->name( $self->parse_primary );

  if ( !$node->name->isa( $self->node('Symbol') ) ) {
    $self->fail('parseFor: variable name expected for loop');
  }

  my $type = $self->peek_token->type;
  if ( $type eq $self->lexer->TOKEN_COMMA ) {
    # key/value iteration
    my $key = $node->name;
    $node->name( $self->node('Array')->new( $key->lineno, $key->colno ) );
    $node->name->add_child($key);

    while ( $self->skip( $self->lexer->TOKEN_COMMA ) ) {
      my $prim = $self->parse_primary;
      $node->name->add_child($prim);
    }
  }

  if ( !$self->skip_symbol('in') ) {
    $self->fail( 'parseFor: expected "in" keyword for loop',
      $for_tok->lineno, $for_tok->colno );
  }

  $node->arr( $self->parse_expression );
  $self->advance_after_block_end( $for_tok->value );

  $node->body( $self->parse_until_blocks( $end_block, 'else' ) );

  if ( $self->skip_symbol('else') ) {
    $self->advance_after_block_end('else');
    $node->else_( $self->parse_until_blocks($end_block) );
  }

  $self->advance_after_block_end;

  return $node;
}

sub parse_macro {
  my ($self) = @_;
  my $macro_tok = $self->peek_token;
  if ( !$self->skip_symbol('macro') ) {
    $self->fail('expected macro');
  }

  my $name = $self->parse_primary(1);
  my $args = $self->parse_signature;
  my $node = $self->node('Macro')->new( $macro_tok->lineno, $macro_tok->colno, $name, $args );

  $self->advance_after_block_end( $macro_tok->value );
  $node->body( $self->parse_until_blocks('endmacro') );
  $self->advance_after_block_end;

  return $node;
}

sub parse_call {
  my ($self) = @_;
  # a call block is parsed as a normal FunCall, but with an added
  # 'caller' kwarg which is a Caller node.
  my $call_tok = $self->peek_token;
  if ( !$self->skip_symbol('call') ) {
    $self->fail('expected call');
  }

  my $caller_args = $self->parse_signature(1) || $self->node('NodeList')->new;
  my $macro_call  = $self->parse_primary;

  $self->advance_after_block_end( $call_tok->value );
  my $body = $self->parse_until_blocks('endcall');
  $self->advance_after_block_end;

  my $caller_name = $self->node('Symbol')->new( $call_tok->lineno, $call_tok->colno, 'caller' );
  my $caller_node = $self->node('Caller')->new(
    $call_tok->lineno, $call_tok->colno,
    $caller_name, $caller_args, $body
  );

  # add the additional caller kwarg, adding kwargs if necessary
  my $args = $macro_call->args->children;
  if ( !( @$args && blessed( $args->[-1] ) && $args->[-1]->isa( $self->node('KeywordArgs') ) ) ) {
    push @$args, $self->node('KeywordArgs')->new;
  }
  my $kwargs = $args->[-1];
  $kwargs->add_child(
    $self->node('Pair')->new( $call_tok->lineno, $call_tok->colno, $caller_name, $caller_node )
  );

  return $self->node('Output')->new( $call_tok->lineno, $call_tok->colno, [$macro_call] );
}

sub parse_with_context {
  my ($self) = @_;
  my $tok = $self->peek_token;

  my $with_context = undef;

  if ( $self->skip_symbol('with') ) {
    $with_context = true;
  }
  elsif ( $self->skip_symbol('without') ) {
    $with_context = false;
  }

  if ( defined $with_context ) {    # JS: withContext !== null
    if ( !$self->skip_symbol('context') ) {
      $self->fail( 'parseFrom: expected context after with/without',
        $tok->lineno, $tok->colno );
    }
  }

  return $with_context;
}

sub parse_import {
  my ($self) = @_;
  my $import_tok = $self->peek_token;
  if ( !$self->skip_symbol('import') ) {
    $self->fail( 'parseImport: expected import', $import_tok->lineno, $import_tok->colno );
  }

  my $template = $self->parse_expression;

  if ( !$self->skip_symbol('as') ) {
    $self->fail( 'parseImport: expected "as" keyword', $import_tok->lineno, $import_tok->colno );
  }

  my $target       = $self->parse_expression;
  my $with_context = $self->parse_with_context;
  my $node         = $self->node('Import')->new(
    $import_tok->lineno, $import_tok->colno,
    $template, $target, $with_context
  );

  $self->advance_after_block_end( $import_tok->value );

  return $node;
}

sub parse_from {
  my ($self) = @_;
  my $from_tok = $self->peek_token;
  if ( !$self->skip_symbol('from') ) {
    $self->fail('parseFrom: expected from');
  }

  my $template = $self->parse_expression;

  if ( !$self->skip_symbol('import') ) {
    $self->fail( 'parseFrom: expected import', $from_tok->lineno, $from_tok->colno );
  }

  my $names = $self->node('NodeList')->new;
  my $with_context;

  while (1) {
    my $next_tok = $self->peek_token;
    if ( $next_tok->type eq $self->lexer->TOKEN_BLOCK_END ) {
      if ( !@{ $names->children } ) {
        $self->fail( 'parseFrom: Expected at least one import name',
          $from_tok->lineno, $from_tok->colno );
      }

      # Since we are manually advancing past the block end,
      # need to keep track of whitespace control (normally
      # this is done in `advanceAfterBlockEnd`
      if ( $self->_char_at( $next_tok->value, 0 ) eq '-' ) {
        $self->dropLeadingWhitespace(1);
      }

      $self->next_token;
      last;
    }

    if ( @{ $names->children } > 0 && !$self->skip( $self->lexer->TOKEN_COMMA ) ) {
      $self->fail( 'parseFrom: expected comma', $from_tok->lineno, $from_tok->colno );
    }

    my $name = $self->parse_primary;
    if ( $self->_char_at( $name->value, 0 ) eq '_' ) {
      $self->fail( 'parseFrom: names starting with an underscore cannot be imported',
        $name->lineno, $name->colno );
    }

    if ( $self->skip_symbol('as') ) {
      my $alias = $self->parse_primary;
      $names->add_child(
        $self->node('Pair')->new( $name->lineno, $name->colno, $name, $alias )
      );
    }
    else {
      $names->add_child($name);
    }

    $with_context = $self->parse_with_context;
  }

  return $self->node('FromImport')->new(
    $from_tok->lineno, $from_tok->colno,
    $template, $names, $with_context
  );
}

sub parse_block {
  my ($self) = @_;
  my $tag = $self->peek_token;
  if ( !$self->skip_symbol('block') ) {
    $self->fail( 'parseBlock: expected block', $tag->lineno, $tag->colno );
  }

  my $node = $self->node('Block')->new( $tag->lineno, $tag->colno );

  $node->name( $self->parse_primary );
  if ( !$node->name->isa( $self->node('Symbol') ) ) {
    $self->fail( 'parseBlock: variable name expected', $tag->lineno, $tag->colno );
  }

  $self->advance_after_block_end( $tag->value );

  $node->body( $self->parse_until_blocks('endblock') );
  $self->skip_symbol('endblock');
  $self->skip_symbol( $node->name->value );

  my $tok = $self->peek_token;
  if ( !$tok ) {
    $self->fail('parseBlock: expected endblock, got end of file');
  }

  $self->advance_after_block_end( $tok->value );

  return $node;
}

sub parse_extends {
  my ($self) = @_;
  my $tag_name = 'extends';
  my $tag      = $self->peek_token;
  if ( !$self->skip_symbol($tag_name) ) {
    $self->fail( 'parseTemplateRef: expected ' . $tag_name );
  }

  my $node = $self->node('Extends')->new( $tag->lineno, $tag->colno );
  $node->template( $self->parse_expression );

  $self->advance_after_block_end( $tag->value );
  return $node;
}

sub parse_include {
  my ($self) = @_;
  my $tag_name = 'include';
  my $tag      = $self->peek_token;
  if ( !$self->skip_symbol($tag_name) ) {
    $self->fail( 'parseInclude: expected ' . $tag_name );
  }

  my $node = $self->node('Include')->new( $tag->lineno, $tag->colno );
  $node->template( $self->parse_expression );

  if ( $self->skip_symbol('ignore') && $self->skip_symbol('missing') ) {
    $node->ignoreMissing(true);
  }

  $self->advance_after_block_end( $tag->value );
  return $node;
}

sub parse_if {
  my ($self) = @_;
  my $tag = $self->peek_token;
  my $node;

  if ( $self->skip_symbol('if') || $self->skip_symbol('elif') || $self->skip_symbol('elseif') ) {
    $node = $self->node('If')->new( $tag->lineno, $tag->colno );
  }
  elsif ( $self->skip_symbol('ifAsync') ) {
    $node = $self->node('IfAsync')->new( $tag->lineno, $tag->colno );
  }
  else {
    $self->fail( 'parseIf: expected if, elif, or elseif', $tag->lineno, $tag->colno );
  }

  $node->cond( $self->parse_expression );
  $self->advance_after_block_end( $tag->value );

  $node->body( $self->parse_until_blocks( 'elif', 'elseif', 'else', 'endif' ) );
  my $tok = $self->peek_token;

  my $val = $tok && $tok->value;
  if ( defined $val && ( $val eq 'elseif' || $val eq 'elif' ) ) {
    $node->else_( $self->parse_if );
  }
  elsif ( defined $val && $val eq 'else' ) {
    $self->advance_after_block_end;
    $node->else_( $self->parse_until_blocks('endif') );
    $self->advance_after_block_end;
  }
  elsif ( defined $val && $val eq 'endif' ) {
    $node->else_(undef);
    $self->advance_after_block_end;
  }
  else {
    $self->fail('parseIf: expected elif, else, or endif, got end of file');
  }

  return $node;
}

sub parse_set {
  my ($self) = @_;
  my $tag = $self->peek_token;
  if ( !$self->skip_symbol('set') ) {
    $self->fail( 'parseSet: expected set', $tag->lineno, $tag->colno );
  }

  my $node = $self->node('Set')->new( $tag->lineno, $tag->colno, [] );

  my $target;
  while ( $target = $self->parse_primary ) {
    push @{ $node->targets }, $target;

    if ( !$self->skip( $self->lexer->TOKEN_COMMA ) ) {
      last;
    }
  }

  if ( !$self->skip_value( $self->lexer->TOKEN_OPERATOR, '=' ) ) {
    if ( !$self->skip( $self->lexer->TOKEN_BLOCK_END ) ) {
      $self->fail( 'parseSet: expected = or block end in set tag',
        $tag->lineno, $tag->colno );
    }
    else {
      $node->body(
        $self->node('Capture')->new(
          $tag->lineno, $tag->colno,
          $self->parse_until_blocks('endset')
        )
      );
      $node->value(undef);
      $self->advance_after_block_end;
    }
  }
  else {
    $node->value( $self->parse_expression );
    $self->advance_after_block_end( $tag->value );
  }

  return $node;
}

sub parse_switch {
  my ($self) = @_;
  #
  # Store the tag names in variables in case someone ever wants to
  # customize this.
  #
  my $switch_start = 'switch';
  my $switch_end   = 'endswitch';
  my $case_start   = 'case';
  my $case_default = 'default';

  # Get the switch tag.
  my $tag = $self->peek_token;

  # fail early if we get some unexpected tag.
  if (  !$self->skip_symbol($switch_start)
    && !$self->skip_symbol($case_start)
    && !$self->skip_symbol($case_default) )
  {
    $self->fail( 'parseSwitch: expected "switch," "case" or "default"',
      $tag->lineno, $tag->colno );
  }

  # parse the switch expression
  my $expr = $self->parse_expression;

  # advance until a start of a case, a default case or an endswitch.
  $self->advance_after_block_end($switch_start);
  $self->parse_until_blocks( $case_start, $case_default, $switch_end );

  # this is the first case. it could also be an endswitch, we'll check.
  my $tok = $self->peek_token;

  # create new variables for our cases and default case.
  my @cases;
  my $default_case;

  # while we're dealing with new cases nodes...
  do {
    # skip the start symbol and get the case expression
    $self->skip_symbol($case_start);
    my $cond = $self->parse_expression;
    $self->advance_after_block_end($switch_start);
    # get the body of the case node and add it to the array of cases.
    my $body = $self->parse_until_blocks( $case_start, $case_default, $switch_end );
    # NOTE: upstream typo -- Case gets tok.line / tok.col, but Token only has
    # lineno / colno, so both are undefined and JSON.stringify (the oracle)
    # omits them on the Case node. Preserved 1:1 by reading the same
    # nonexistent hash slots ($tok->{line}/{col} -> undef), the way Lexer.pm
    # preserves its this.src typo.
    push @cases, $self->node('Case')->new( $tok->{line}, $tok->{col}, $cond, $body );
    # get our next case
    $tok = $self->peek_token;
  } while ( $tok && $tok->value eq $case_start );

  # we either have a default case or a switch end.
  if ( $tok->value eq $case_default ) {
    $self->advance_after_block_end;
    $default_case = $self->parse_until_blocks($switch_end);
    $self->advance_after_block_end;
  }
  elsif ( $tok->value eq $switch_end ) {
    $self->advance_after_block_end;
  }
  else {
    # otherwise bail because EOF
    $self->fail('parseSwitch: expected "case," "default" or "endswitch," got EOF.');
  }

  # and return the switch node.
  return $self->node('Switch')->new( $tag->lineno, $tag->colno, $expr, \@cases, $default_case );
}

sub parse_statement {
  my ($self) = @_;
  my $tok = $self->peek_token;
  my $node;

  if ( $tok->type ne $self->lexer->TOKEN_SYMBOL ) {
    $self->fail( 'tag name expected', $tok->lineno, $tok->colno );
  }

  if ( $self->breakOnBlocks
    && $self->lib->index_of( $self->breakOnBlocks, $tok->value ) != -1 )
  {
    return undef;
  }

  my $val = $tok->value;
  if    ( $val eq 'raw' )                             { return $self->parse_raw; }
  elsif ( $val eq 'verbatim' )                        { return $self->parse_raw('verbatim'); }
  elsif ( $val eq 'if' || $val eq 'ifAsync' )         { return $self->parse_if; }
  elsif ( $val eq 'for' || $val eq 'asyncEach' || $val eq 'asyncAll' ) { return $self->parse_for; }
  elsif ( $val eq 'block' )                           { return $self->parse_block; }
  elsif ( $val eq 'extends' )                         { return $self->parse_extends; }
  elsif ( $val eq 'include' )                         { return $self->parse_include; }
  elsif ( $val eq 'set' )                             { return $self->parse_set; }
  elsif ( $val eq 'macro' )                           { return $self->parse_macro; }
  elsif ( $val eq 'call' )                            { return $self->parse_call; }
  elsif ( $val eq 'import' )                          { return $self->parse_import; }
  elsif ( $val eq 'from' )                            { return $self->parse_from; }
  elsif ( $val eq 'filter' )                          { return $self->parse_filter_statement; }
  elsif ( $val eq 'switch' )                          { return $self->parse_switch; }
  else {
    if ( @{ $self->extensions } ) {
      for my $ext ( @{ $self->extensions } ) {
        # ext.tags -- extension representation is k8 (undecided); read `tags`
        # off a blessed object or a hashref, mirroring how the parser calls
        # ext.parse below.
        my $tags =
            ( blessed($ext) && $ext->can('tags') ) ? $ext->tags
          : ( ref($ext) eq 'HASH' )                ? $ext->{tags}
          :                                          undef;
        if ( $self->lib->index_of( $tags || [], $tok->value ) != -1 ) {
          return $ext->parse( $self, $self->nodes_module, $self->lexer );
        }
      }
    }
    $self->fail( 'unknown block tag: ' . $tok->value, $tok->lineno, $tok->colno );
  }

  return $node;
}

sub parse_raw {
  my ( $self, $tag_name ) = @_;
  $tag_name = $tag_name || 'raw';
  my $end_tag_name = 'end' . $tag_name;
  # Look for upcoming raw blocks (ignore all other kinds of blocks). JS \s in
  # the regex maps to the ECMAScript whitespace class (ADR 0005); [\s\S] means
  # "any char" so its \s definition does not matter. `^`/`$` are not used here.
  my $ws = $self->lib->js_whitespace_class;
  my $raw_block_regex =
    qr/([\s\S]*?)\{%${ws}*(${tag_name}|${end_tag_name})${ws}*(?=%\})%\}/;
  my $raw_level = 1;
  my $str       = '';
  my $matches   = undef;

  # Skip opening raw token
  # Keep this token to track line and column numbers
  my $begun = $self->advance_after_block_end;

  # Exit when there's nothing to match
  # or when we've found the matching "endraw" block
  while ( ( $matches = $self->tokens->_extract_regex($raw_block_regex) ) && $raw_level > 0 ) {
    my $all        = $matches->[0];
    my $pre        = $matches->[1];
    my $block_name = $matches->[2];

    # Adjust rawlevel
    if ( $block_name eq $tag_name ) {
      $raw_level += 1;
    }
    elsif ( $block_name eq $end_tag_name ) {
      $raw_level -= 1;
    }

    # Add to str
    if ( $raw_level == 0 ) {
      # We want to exclude the last "endraw"
      $str .= $pre;
      # Move tokenizer to beginning of endraw block
      $self->tokens->back_n( length($all) - length($pre) );
    }
    else {
      $str .= $all;
    }
  }

  return $self->node('Output')->new(
    $begun->lineno, $begun->colno,
    [ $self->node('TemplateData')->new( $begun->lineno, $begun->colno, $str ) ]
  );
}

sub parse_postfix {
  my ( $self, $node ) = @_;
  my $lookup;
  my $tok = $self->peek_token;

  while ($tok) {
    if ( $tok->type eq $self->lexer->TOKEN_LEFT_PAREN ) {
      # Function call
      $node = $self->node('FunCall')->new(
        $tok->lineno, $tok->colno,
        $node, $self->parse_signature
      );
    }
    elsif ( $tok->type eq $self->lexer->TOKEN_LEFT_BRACKET ) {
      # Reference
      $lookup = $self->parse_aggregate;
      if ( @{ $lookup->children } > 1 ) {
        $self->fail('invalid index');
      }

      $node = $self->node('LookupVal')->new(
        $tok->lineno, $tok->colno,
        $node, $lookup->children->[0]
      );
    }
    elsif ( $tok->type eq $self->lexer->TOKEN_OPERATOR && $tok->value eq '.' ) {
      # Reference
      $self->next_token;
      my $val = $self->next_token;

      if ( $val->type ne $self->lexer->TOKEN_SYMBOL ) {
        $self->fail( 'expected name as lookup value, got ' . $val->value,
          $val->lineno, $val->colno );
      }

      # Make a literal string because it's not a variable
      # reference
      $lookup = $self->node('Literal')->new( $val->lineno, $val->colno, $val->value );

      $node = $self->node('LookupVal')->new(
        $tok->lineno, $tok->colno,
        $node, $lookup
      );
    }
    else {
      last;
    }

    $tok = $self->peek_token;
  }

  return $node;
}

sub parse_expression {
  my ($self) = @_;
  my $node = $self->parse_inline_if;
  return $node;
}

sub parse_inline_if {
  my ($self) = @_;
  my $node = $self->parse_or;
  if ( $self->skip_symbol('if') ) {
    my $cond_node = $self->parse_or;
    my $body_node = $node;
    $node = $self->node('InlineIf')->new( $node->lineno, $node->colno );
    $node->body($body_node);
    $node->cond($cond_node);
    if ( $self->skip_symbol('else') ) {
      $node->else_( $self->parse_or );
    }
    else {
      $node->else_(undef);
    }
  }

  return $node;
}

sub parse_or {
  my ($self) = @_;
  my $node = $self->parse_and;
  while ( $self->skip_symbol('or') ) {
    my $node2 = $self->parse_and;
    $node = $self->node('Or')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_and {
  my ($self) = @_;
  my $node = $self->parse_not;
  while ( $self->skip_symbol('and') ) {
    my $node2 = $self->parse_not;
    $node = $self->node('And')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_not {
  my ($self) = @_;
  my $tok = $self->peek_token;
  if ( $self->skip_symbol('not') ) {
    return $self->node('Not')->new( $tok->lineno, $tok->colno, $self->parse_not );
  }
  return $self->parse_in;
}

sub parse_in {
  my ($self) = @_;
  my $node = $self->parse_is;
  while (1) {
    # check if the next token is 'not'
    my $tok = $self->next_token;
    if ( !$tok ) {
      last;
    }
    my $invert = $tok->type eq $self->lexer->TOKEN_SYMBOL && $tok->value eq 'not';
    # if it wasn't 'not', put it back
    if ( !$invert ) {
      $self->push_token($tok);
    }
    if ( $self->skip_symbol('in') ) {
      my $node2 = $self->parse_is;
      $node = $self->node('In')->new( $node->lineno, $node->colno, $node, $node2 );
      if ($invert) {
        $node = $self->node('Not')->new( $node->lineno, $node->colno, $node );
      }
    }
    else {
      # if we'd found a 'not' but this wasn't an 'in', put back the 'not'
      if ($invert) {
        $self->push_token($tok);
      }
      last;
    }
  }
  return $node;
}

# I put this right after "in" in the operator precedence stack. That can
# obviously be changed to be closer to Jinja.
sub parse_is {
  my ($self) = @_;
  my $node = $self->parse_compare;
  # look for an is
  if ( $self->skip_symbol('is') ) {
    # look for a not
    my $not = $self->skip_symbol('not');
    # get the next node
    my $node2 = $self->parse_compare;
    # create an Is node using the next node and the info from our Is node.
    $node = $self->node('Is')->new( $node->lineno, $node->colno, $node, $node2 );
    # if we have a Not, create a Not node from our Is node.
    if ($not) {
      $node = $self->node('Not')->new( $node->lineno, $node->colno, $node );
    }
  }
  # return the node.
  return $node;
}

sub parse_compare {
  my ($self) = @_;
  my @compare_ops = ( '==', '===', '!=', '!==', '<', '>', '<=', '>=' );
  my $expr = $self->parse_concat;
  my @ops;

  while (1) {
    my $tok = $self->next_token;

    if ( !$tok ) {
      last;
    }
    elsif ( $self->lib->index_of( \@compare_ops, $tok->value ) != -1 ) {
      push @ops,
        $self->node('CompareOperand')->new(
        $tok->lineno, $tok->colno,
        $self->parse_concat, $tok->value
        );
    }
    else {
      $self->push_token($tok);
      last;
    }
  }

  if (@ops) {
    return $self->node('Compare')->new( $ops[0]->lineno, $ops[0]->colno, $expr, \@ops );
  }
  else {
    return $expr;
  }
}

# finds the '~' for string concatenation
sub parse_concat {
  my ($self) = @_;
  my $node = $self->parse_add;
  while ( $self->skip_value( $self->lexer->TOKEN_TILDE, '~' ) ) {
    my $node2 = $self->parse_add;
    $node = $self->node('Concat')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_add {
  my ($self) = @_;
  my $node = $self->parse_sub;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '+' ) ) {
    my $node2 = $self->parse_sub;
    $node = $self->node('Add')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_sub {
  my ($self) = @_;
  my $node = $self->parse_mul;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '-' ) ) {
    my $node2 = $self->parse_mul;
    $node = $self->node('Sub')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_mul {
  my ($self) = @_;
  my $node = $self->parse_div;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '*' ) ) {
    my $node2 = $self->parse_div;
    $node = $self->node('Mul')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_div {
  my ($self) = @_;
  my $node = $self->parse_floor_div;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '/' ) ) {
    my $node2 = $self->parse_floor_div;
    $node = $self->node('Div')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_floor_div {
  my ($self) = @_;
  my $node = $self->parse_mod;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '//' ) ) {
    my $node2 = $self->parse_mod;
    $node = $self->node('FloorDiv')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_mod {
  my ($self) = @_;
  my $node = $self->parse_pow;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '%' ) ) {
    my $node2 = $self->parse_pow;
    $node = $self->node('Mod')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_pow {
  my ($self) = @_;
  my $node = $self->parse_unary;
  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '**' ) ) {
    my $node2 = $self->parse_unary;
    $node = $self->node('Pow')->new( $node->lineno, $node->colno, $node, $node2 );
  }
  return $node;
}

sub parse_unary {
  my ( $self, $no_filters ) = @_;
  my $tok = $self->peek_token;
  my $node;

  if ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '-' ) ) {
    $node = $self->node('Neg')->new( $tok->lineno, $tok->colno, $self->parse_unary(1) );
  }
  elsif ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '+' ) ) {
    $node = $self->node('Pos')->new( $tok->lineno, $tok->colno, $self->parse_unary(1) );
  }
  else {
    $node = $self->parse_primary;
  }

  if ( !$no_filters ) {
    $node = $self->parse_filter($node);
  }

  return $node;
}

sub parse_primary {
  my ( $self, $no_postfix ) = @_;
  my $tok = $self->next_token;
  my $val;
  my $has_val = 0;    # JS distinguishes "val was set" (incl. null/false/0/'')
                      # from "still undefined"; a Perl flag stands in for that.
  my $node = undef;

  if ( !$tok ) {
    $self->fail('expected expression, got end of file');
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_STRING ) {
    $val     = $tok->value;
    $has_val = 1;
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_INT ) {
    # parseInt(tok.value, 10) -- number-literal parsing rides on k4; the lexer
    # already guarantees tok.value is pure digits, so 0 + value suffices.
    $val     = 0 + $tok->value;
    $has_val = 1;
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_FLOAT ) {
    # parseFloat(tok.value) -- see k4 note above.
    $val     = 0 + $tok->value;
    $has_val = 1;
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_BOOLEAN ) {
    if ( $tok->value eq 'true' ) {
      $val     = true;
      $has_val = 1;
    }
    elsif ( $tok->value eq 'false' ) {
      $val     = false;
      $has_val = 1;
    }
    else {
      $self->fail( 'invalid boolean: ' . $tok->value, $tok->lineno, $tok->colno );
    }
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_NONE ) {
    $val     = undef;    # JS null
    $has_val = 1;
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_REGEX ) {
    # new RegExp(tok.value.body, tok.value.flags). k7 (regex literals) is open:
    # the runtime representation (qr// vs object) is undecided. The parser only
    # needs a Literal whose AST dump matches the oracle's { regex, flags }
    # shape, so it carries the lexer's regex token through as that hashref.
    # When k7 lands, this seam and t/corpus.t's Regexp branch take the decided
    # representation.
    $val     = { regex => $tok->value->{body}, flags => $tok->value->{flags} };
    $has_val = 1;
  }

  if ($has_val) {
    $node = $self->node('Literal')->new( $tok->lineno, $tok->colno, $val );
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_SYMBOL ) {
    $node = $self->node('Symbol')->new( $tok->lineno, $tok->colno, $tok->value );
  }
  else {
    # See if it's an aggregate type, we need to push the
    # current delimiter token back on
    $self->push_token($tok);
    $node = $self->parse_aggregate;
  }

  if ( !$no_postfix ) {
    $node = $self->parse_postfix($node);
  }

  if ($node) {
    return $node;
  }
  else {
    die $self->error( 'unexpected token: ' . $tok->value, $tok->lineno, $tok->colno );
  }
}

sub parse_filter_name {
  my ($self) = @_;
  my $tok  = $self->expect( $self->lexer->TOKEN_SYMBOL );
  my $name = $tok->value;

  while ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '.' ) ) {
    $name .= '.' . $self->expect( $self->lexer->TOKEN_SYMBOL )->value;
  }

  return $self->node('Symbol')->new( $tok->lineno, $tok->colno, $name );
}

sub parse_filter_args {
  my ( $self, $node ) = @_;
  if ( $self->peek_token->type eq $self->lexer->TOKEN_LEFT_PAREN ) {
    # Get a FunCall node and add the parameters to the
    # filter
    my $call = $self->parse_postfix($node);
    return $call->args->children;
  }
  return [];
}

sub parse_filter {
  my ( $self, $node ) = @_;
  while ( $self->skip( $self->lexer->TOKEN_PIPE ) ) {
    my $name = $self->parse_filter_name;

    $node = $self->node('Filter')->new(
      $name->lineno, $name->colno,
      $name,
      $self->node('NodeList')->new(
        $name->lineno, $name->colno,
        [ $node, @{ $self->parse_filter_args($node) } ]
      )
    );
  }

  return $node;
}

sub parse_filter_statement {
  my ($self) = @_;
  my $filter_tok = $self->peek_token;
  if ( !$self->skip_symbol('filter') ) {
    $self->fail('parseFilterStatement: expected filter');
  }

  my $name = $self->parse_filter_name;
  my $args = $self->parse_filter_args($name);

  $self->advance_after_block_end( $filter_tok->value );
  my $body = $self->node('Capture')->new(
    $name->lineno, $name->colno,
    $self->parse_until_blocks('endfilter')
  );
  $self->advance_after_block_end;

  my $node = $self->node('Filter')->new(
    $name->lineno, $name->colno,
    $name,
    $self->node('NodeList')->new(
      $name->lineno, $name->colno,
      [ $body, @$args ]
    )
  );

  return $self->node('Output')->new( $name->lineno, $name->colno, [$node] );
}

sub parse_aggregate {
  my ($self) = @_;
  my $tok = $self->next_token;
  my $node;

  if ( $tok->type eq $self->lexer->TOKEN_LEFT_PAREN ) {
    $node = $self->node('Group')->new( $tok->lineno, $tok->colno );
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_LEFT_BRACKET ) {
    $node = $self->node('Array')->new( $tok->lineno, $tok->colno );
  }
  elsif ( $tok->type eq $self->lexer->TOKEN_LEFT_CURLY ) {
    $node = $self->node('Dict')->new( $tok->lineno, $tok->colno );
  }
  else {
    return undef;
  }

  while (1) {
    my $type = $self->peek_token->type;
    if ( $type eq $self->lexer->TOKEN_RIGHT_PAREN
      || $type eq $self->lexer->TOKEN_RIGHT_BRACKET
      || $type eq $self->lexer->TOKEN_RIGHT_CURLY )
    {
      $self->next_token;
      last;
    }

    if ( @{ $node->children } > 0 ) {
      if ( !$self->skip( $self->lexer->TOKEN_COMMA ) ) {
        $self->fail( 'parseAggregate: expected comma after expression',
          $tok->lineno, $tok->colno );
      }
    }

    if ( $node->isa( $self->node('Dict') ) ) {
      # TODO: check for errors
      my $key = $self->parse_primary;

      # We expect a key/value pair for dicts, separated by a
      # colon
      if ( !$self->skip( $self->lexer->TOKEN_COLON ) ) {
        $self->fail( 'parseAggregate: expected colon after dict key',
          $tok->lineno, $tok->colno );
      }

      # TODO: check for errors
      my $value = $self->parse_expression;
      $node->add_child(
        $self->node('Pair')->new( $key->lineno, $key->colno, $key, $value )
      );
    }
    else {
      # TODO: check for errors
      my $expr = $self->parse_expression;
      $node->add_child($expr);
    }
  }

  return $node;
}

sub parse_signature {
  my ( $self, $tolerant, $no_parens ) = @_;
  my $tok = $self->peek_token;
  if ( !$no_parens && $tok->type ne $self->lexer->TOKEN_LEFT_PAREN ) {
    if ($tolerant) {
      return undef;
    }
    else {
      $self->fail( 'expected arguments', $tok->lineno, $tok->colno );
    }
  }

  if ( $tok->type eq $self->lexer->TOKEN_LEFT_PAREN ) {
    $tok = $self->next_token;
  }

  my $args        = $self->node('NodeList')->new( $tok->lineno, $tok->colno );
  my $kwargs      = $self->node('KeywordArgs')->new( $tok->lineno, $tok->colno );
  my $check_comma = 0;

  while (1) {
    $tok = $self->peek_token;
    if ( !$no_parens && $tok->type eq $self->lexer->TOKEN_RIGHT_PAREN ) {
      $self->next_token;
      last;
    }
    elsif ( $no_parens && $tok->type eq $self->lexer->TOKEN_BLOCK_END ) {
      last;
    }

    if ( $check_comma && !$self->skip( $self->lexer->TOKEN_COMMA ) ) {
      $self->fail( 'parseSignature: expected comma after expression',
        $tok->lineno, $tok->colno );
    }
    else {
      my $arg = $self->parse_expression;

      if ( $self->skip_value( $self->lexer->TOKEN_OPERATOR, '=' ) ) {
        $kwargs->add_child(
          $self->node('Pair')->new( $arg->lineno, $arg->colno, $arg, $self->parse_expression )
        );
      }
      else {
        $args->add_child($arg);
      }
    }

    $check_comma = 1;
  }

  if ( @{ $kwargs->children } ) {
    $args->add_child($kwargs);
  }

  return $args;
}

sub parse_until_blocks {
  my ( $self, @block_names ) = @_;
  my $prev = $self->breakOnBlocks;
  $self->breakOnBlocks( \@block_names );

  my $ret = $self->parse;

  $self->breakOnBlocks($prev);
  return $ret;
}

sub parse_nodes {
  my ($self) = @_;
  my $tok;
  my @buf;

  while ( $tok = $self->next_token ) {
    if ( $tok->type eq $self->lexer->TOKEN_DATA ) {
      my $data       = $tok->value;
      my $next_token = $self->peek_token;
      my $next_val   = $next_token && $next_token->value;

      # If the last token has "-" we need to trim the
      # leading whitespace of the data. This is marked with
      # the `dropLeadingWhitespace` variable.
      if ( $self->dropLeadingWhitespace ) {
        # TODO: this could be optimized (don't use regex). JS \s -> the
        # ECMAScript whitespace class (ADR 0005); ^ is start of string here.
        my $ws = $self->lib->js_whitespace_class;
        $data =~ s/^${ws}*//;
        $self->dropLeadingWhitespace(0);
      }

      # Same for the succeeding block start token
      if (
        $next_token
        && ( ( $next_token->type eq $self->lexer->TOKEN_BLOCK_START
            && $self->_char_at( $next_val, length($next_val) - 1 ) eq '-' )
          || ( $next_token->type eq $self->lexer->TOKEN_VARIABLE_START
            && $self->_char_at( $next_val, length( $self->tokens->tags->{VARIABLE_START} ) ) eq '-' )
          || ( $next_token->type eq $self->lexer->TOKEN_COMMENT
            && $self->_char_at( $next_val, length( $self->tokens->tags->{COMMENT_START} ) ) eq '-' ) )
        )
      {
        # TODO: this could be optimized (don't use regex). JS \s -> the
        # ECMAScript whitespace class (ADR 0005); $ is end of string here.
        my $ws = $self->lib->js_whitespace_class;
        $data =~ s/${ws}*$//;
      }

      push @buf,
        $self->node('Output')->new(
        $tok->lineno, $tok->colno,
        [ $self->node('TemplateData')->new( $tok->lineno, $tok->colno, $data ) ]
        );
    }
    elsif ( $tok->type eq $self->lexer->TOKEN_BLOCK_START ) {
      $self->dropLeadingWhitespace(0);
      my $n = $self->parse_statement;
      if ( !$n ) {
        last;
      }
      push @buf, $n;
    }
    elsif ( $tok->type eq $self->lexer->TOKEN_VARIABLE_START ) {
      my $e = $self->parse_expression;
      $self->dropLeadingWhitespace(0);
      $self->advance_after_variable_end;
      push @buf, $self->node('Output')->new( $tok->lineno, $tok->colno, [$e] );
    }
    elsif ( $tok->type eq $self->lexer->TOKEN_COMMENT ) {
      $self->dropLeadingWhitespace(
        $self->_char_at(
          $tok->value,
          length( $tok->value ) - length( $self->tokens->tags->{COMMENT_END} ) - 1
        ) eq '-' ? 1 : 0
      );
    }
    else {
      # Ignore comments, otherwise this should be an error
      $self->fail( 'Unexpected token at top-level: ' . $tok->type,
        $tok->lineno, $tok->colno );
    }
  }

  return \@buf;
}

sub parse {
  my ($self) = @_;
  return $self->node('NodeList')->new( 0, 0, $self->parse_nodes );
}

sub parse_as_root {
  my ($self) = @_;
  return $self->node('Root')->new( 0, 0, $self->parse_nodes );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Parser::Parser - The recursive-descent parser (parser.js class Parser)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: upstream's exported C<Parser> class, reachable as
C<< Text::Nunjucks::Parser->parser_class >>. Construct it on a
L<Text::Nunjucks::Lexer::Tokenizer> and call C<parse_as_root> for the C<Root>
node; L<Text::Nunjucks::Parser>'s C<parse> does exactly that. See
L<Text::Nunjucks::Parser>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
