package Text::Nunjucks::Runtime;
# ABSTRACT: 1:1 port of Nunjucks src/runtime.js -- frames, macros, member lookup

our $VERSION = '0.001';

use strict;
use warnings;
use builtin qw( is_bool created_as_number true false );
use Scalar::Util qw( blessed refaddr weaken );
use POSIX qw( floor fmod );
use Carp qw( croak );
use Hash::Ordered;
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Lib::TemplateError;
use Text::Nunjucks::Runtime::None;
use Text::Nunjucks::Runtime::KwArgs;
use Text::Nunjucks::Runtime::Regex;
use Text::Nunjucks::Runtime::SafeString;
use Text::Nunjucks::Runtime::Frame;

no warnings 'experimental::builtin';

# runtime.js does `require('./lib')` and re-exports several lib functions; the
# port mirrors that. runtime.js is class-method-only here (getty-perl-core
# "dispatch through the invocant", like Lib): every ported function is a method
# taking $self, the compiler-emitted code calls $runtime->member_lookup(...) &c,
# and cross-calls go through $self. No instances of Runtime itself.
#
# runtime.js declares two real classes (Frame, SafeString); each is a class in
# its own file (Text::Nunjucks::Runtime::Frame, a Moo class, and
# Text::Nunjucks::Runtime::SafeString, a plain package; ADR 0020), loaded
# above and named once by the resolvers below. Three port additions live at
# their ADR-designated home, here or beside it, and are marked as such:
#   * None sentinel   -- JS null (ADR 0006), Text::Nunjucks::Runtime::None
#   * KwArgs marker   -- __keywords trailing hashref (ADR 0009),
#     Text::Nunjucks::Runtime::KwArgs
#   * the JS operators + JS ToNumber/ToPrimitive/ToString + truthiness (ADR
#     0007 / value model): Perl's native +,*,==,... do NOT have JS semantics,
#     so the compiler (k15) emits calls to op_add/op_mul/op_eq/... here.
# The template regex literal (ADR 0013) is Text::Nunjucks::Runtime::Regex.
# The Number->String routine itself is in Lib (ADR 0007); this module feeds it.

# JS special doubles, reused by the operators and division/mod guards.
my $POS_INF = 9**9**9;
my $NEG_INF = -$POS_INF;
my $NAN     = $POS_INF - $POS_INF;

#### resolvers -- the runtime "exports" that name a class once (getty-perl-core)

sub None       { return Text::Nunjucks::Runtime::None->instance }
sub Frame      { 'Text::Nunjucks::Runtime::Frame' }
sub SafeString { 'Text::Nunjucks::Runtime::SafeString' }
sub KwArgs     { 'Text::Nunjucks::Runtime::KwArgs' }
sub Regex      { 'Text::Nunjucks::Runtime::Regex' }

sub _error_class          { 'Text::Nunjucks::Lib::Error' }
sub _template_error_class { 'Text::Nunjucks::Lib::TemplateError' }

#### sentinel predicates

sub _is_none        { my ( $self, $v ) = @_; ( blessed($v) && $v->isa('Text::Nunjucks::Runtime::None') )       ? 1 : 0 }
sub _is_safe_string { my ( $self, $v ) = @_; ( blessed($v) && $v->isa('Text::Nunjucks::Runtime::SafeString') ) ? 1 : 0 }
sub _is_kwargs      { my ( $self, $v ) = @_; ( blessed($v) && $v->isa('Text::Nunjucks::Runtime::KwArgs') )     ? 1 : 0 }
sub _is_regex       { my ( $self, $v ) = @_; ( blessed($v) && $v->isa('Text::Nunjucks::Runtime::Regex') )      ? 1 : 0 }

#### makeMacro

sub make_macro {
  my ( $self, $arg_names, $kwarg_names, $func ) = @_;

  return sub {
    my @macro_args = @_;
    my $arg_count  = $self->num_args( \@macro_args );
    my @args;
    my $kwargs = $self->get_keyword_args( \@macro_args );

    if ( $arg_count > scalar @$arg_names ) {
      @args = @macro_args[ 0 .. $#$arg_names ];

      # Positional arguments that should be passed in as keyword arguments
      # (essentially default values).
      my @overflow = @macro_args[ scalar(@args) .. $arg_count - 1 ];
      for my $i ( 0 .. $#overflow ) {
        if ( $i < scalar @$kwarg_names ) {
          $kwargs->{ $kwarg_names->[$i] } = $overflow[$i];
        }
      }
      push @args, $kwargs;
    } elsif ( $arg_count < scalar @$arg_names ) {
      @args = $arg_count > 0 ? @macro_args[ 0 .. $arg_count - 1 ] : ();

      for ( my $i = $arg_count; $i < scalar @$arg_names; $i++ ) {
        my $arg = $arg_names->[$i];

        # Keyword arguments the caller passed by the name of a positional arg.
        push @args, $kwargs->{$arg};
        delete $kwargs->{$arg};
      }
      push @args, $kwargs;
    } else {
      @args = @macro_args;
    }

    # Port-only (k83): a macro that calls itself N deep enters its body N
    # calls deep, as upstream nests one JS call per level. Perl warns at the
    # 100th nested call of a sub, at the call site, and a template cannot
    # switch a Perl warning off; the depth is bounded by memory, not by Perl
    # (see Lib async_iter).
    no warnings 'recursion';
    return $func->(@args);
  };
}

#### render scope -- port-only, no upstream counterpart (ADR 0021)
#
# In upstream every function a compiled template is made of closes over
# `context`, and the Context holds the macros among them
# (context.setVariable): a tracing GC collects those cycles, a reference count
# never does. Two things make it more than the macros that read a name from
# outside: Perl keeps the enclosing sub of a closure alive, so a macro defined
# after an `import` or `include` holds the continuation it was made in and
# with it everything that continuation captured; and a macro whose body
# contains an async construct captures the `$cb` of its sub, behind which the
# continuations of the calling template wait.
#
# So no compiled sub holds its Context. The first statement of every root and
# block sub (Compiler _emit_func_begin) calls this with references to the
# sub's `$context` and `$frame` variables: the `$context` variable -- the one
# all nested subs of that call capture -- becomes a weak reference, and the
# Context remembers both variables (Context _track_scope) to put something
# harmless into them when it is freed.
#
# What holds a Context is what is still going to run in it: the call that
# started the render (Template render, _get_exported) for as long as it is on
# the stack, and every continuation from the moment the compiled code hands it
# out until it is called (_continuation). What already ran holds nothing.
sub _render_scope {
  my ( $self, $context_ref, $frame_ref ) = @_;
  my $context = $$context_ref;
  return unless blessed($context) && $context->can('_track_scope');
  $context->_track_scope( $context_ref, $frame_ref );
  weaken($$context_ref);
  return;
}

# Every callback the compiled code hands out to be called when something is
# done -- upstream's `function(err, res) { ... }` after an async filter, a
# getTemplate, a block -- is made through this (Compiler _continuation_open).
# The wrapper holds the Context until it is called, and for as long as that
# call runs; after that it holds nothing, so a macro made inside the
# continuation, which Perl makes keep the continuation, keeps no Context.
sub _continuation {
  my ( $self, $context, $continuation ) = @_;
  return sub {
    my $held = $context;
    undef $context;
    return $continuation->(@_);
  };
}

#### makeKeywordArgs

sub make_keyword_args {
  my ( $self, $obj ) = @_;
  bless $obj, $self->KwArgs;    # JS: obj.__keywords = true
  return $obj;
}

#### makeDict -- ordered object for template dict literals (ADR 0011)
#
# Port addition (no upstream counterpart): the compiler (k15) emits
# $runtime->make_dict(k1, v1, ...) for every template `{...}` literal so that
# JS insertion order survives (a plain Perl hash does not preserve it). The
# representation is Hash::Ordered; member_lookup / keys / in_operator below read
# it. Most of the engine's other objects come from here too (Lib group_by's
# result, the list filter's {key, value}, a regex match's groups). Their key
# order -- JS's, array indices first -- is Lib keys' (ADR 0011, k51), not this
# constructor's. Two engine-built objects do not come from here and are plain
# hashes, so they iterate key-sorted: the object Frame set creates for a dotted
# name such as `loop` (upstream runtime.js Frame.set, `obj[id] = {}`) and the
# import namespace (Environment get_exported, upstream environment.js:403) --
# open, k80.
sub make_dict {
  my ( $self, @kv ) = @_;
  return Hash::Ordered->new(@kv);
}

#### makeRegex -- compile a template regex literal into a Regex object (ADR 0013)
#
# JS RegExp flags (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp):
#   g  -- global (stateful, lastIndex; tracked on the Regex object, NOT a qr// flag)
#   i  -- case-insensitive
#   m  -- ^/$ match per line
#   s  -- . matches newlines
#   u  -- Unicode mode (in JS: \u{...} escapes, surrogate-pair merging)
#   y  -- sticky (stateful match at lastIndex; not portable to a stateless qr//)
# JS RegExp is constructed in upstream parser.js:1043 as `new RegExp(body, flags)`
# and then read through `memberLookup`. JS's RegExp.prototype.toString yields
# `/body/flags`, which is what `{{ r/x/i }}` renders (oracle: '{{ r/x/gi }}'
# -> '/x/gi').
#
# ADR 0013 home is here (k43): one seam that owns pattern translation and the
# Regex object. ADR 0005 says engine-internal regexes use explicit ECMAScript
# character-class sets; for user-facing regex literals the path of least
# surprise today is to compile the JS body verbatim under Perl's /a flag
# (ASCII-only `\d`/`\s`/`\w`, matching JS defaults), and croak loudly when
# the body does not compile (the "fail loud" rule).
sub make_regex {
  my ( $self, $source, $flags ) = @_;
  $flags //= '';

  # Validate every flag -- an unrecognised JS flag is a typo we should not
  # silently absorb.
  my %known = map { $_ => 1 } qw( g i m s u y );
  for my $f ( split //, $flags ) {
    croak __PACKAGE__ . '->make_regex: unsupported JS flag ' . $f
      unless $known{$f};
  }

  # Map JS flags onto a Perl inline modifier group. g and y do not become
  # qr// flags -- global state is carried on the Regex object itself
  # (source/flags/global/test/exec), and a sticky match (y) is out of scope
  # for a stateless qr// (k43 grow-on-demand: a corpus case for /y would
  # motivate lastIndex tracking).
  my $perl_mods = '';
  $perl_mods .= 'i' if index( $flags, 'i' ) >= 0;
  $perl_mods .= 'm' if index( $flags, 'm' ) >= 0;
  $perl_mods .= 's' if index( $flags, 's' ) >= 0;
  # JS `u` (unicode mode): no Perl analogue is exactly right; JS `\d`/`\s`/`\w`
  # are ASCII-only by default, so /a (ASCII-restricted) is the closest 1:1.
  # A future corpus case with non-ASCII JS `\p{...}` will motivate either a
  # tailored translator or a documented divergence (k43 ADR-grown).
  $perl_mods .= 'a' if index( $flags, 'u' ) >= 0;

  my $qr;
  {
    local $@;
    my $compiled = eval { qr/(?$perl_mods:$source)/ };
    croak __PACKAGE__ . '->make_regex: cannot compile pattern '
      . $source . ': ' . ( $@ // 'unknown error' )
      unless defined $compiled;
    $qr = $compiled;
  }

  # k46: the sticky qr// is the same pattern with a leading \G. ADR 0013 maps
  # JS /y to a pos-anchored Perl match (the only portable 1:1).
  my $qr_anchored;
  {
    local $@;
    my $compiled = eval { qr/(?$perl_mods:\G(?:$source))/ };
    croak __PACKAGE__ . '->make_regex: cannot compile sticky pattern '
      . $source . ': ' . ( $@ // 'unknown error' )
      unless defined $compiled;
    $qr_anchored = $compiled;
  }

  my $groups = $self->Regex->_capture_groups($source);
  my %seen;
  return $self->Regex->new(
    source          => $source,
    flags           => $flags,
    _qr             => $qr,
    _qr_anchored    => $qr_anchored,
    _captures_count => scalar @$groups,
    _group_names    => [ grep { defined($_) && !$seen{$_}++ } @$groups ],
  );
}

sub _is_ordered_hash {
  my ( $self, $v ) = @_;
  return ( blessed($v) && $v->isa('Hash::Ordered') ) ? 1 : 0;
}

#### isKeywordArgs

sub is_keyword_args {
  my ( $self, $obj ) = @_;
  return $self->_is_kwargs($obj);
}

#### getKeywordArgs

sub get_keyword_args {
  my ( $self, $args ) = @_;
  my $len = scalar @$args;
  if ($len) {
    my $last_arg = $args->[ $len - 1 ];
    return $last_arg if $self->is_keyword_args($last_arg);
  }
  return {};
}

#### numArgs

sub num_args {
  my ( $self, $args ) = @_;
  my $len = scalar @$args;
  return 0 if $len == 0;

  my $last_arg = $args->[ $len - 1 ];
  return $self->is_keyword_args($last_arg) ? $len - 1 : $len;
}

#### copySafeness

sub copy_safeness {
  my ( $self, $dest, $target ) = @_;
  return $self->SafeString->new($target) if $self->_is_safe_string($dest);
  # target.toString(): reading toString off undefined / null throws V8's
  # TypeError (oracle: undefined|string -> "Cannot read properties of undefined
  # (reading 'toString')"); any other value's toString() is its JS ToString --
  # an own toString member and a null prototype are k44
  die $self->_js_read_error( $target, 'toString' ) if !defined($target) || $self->_is_none($target);
  return $self->_js_to_string($target);
}

#### markSafe

sub mark_safe {
  my ( $self, $val ) = @_;

  if ( Text::Nunjucks::Lib->is_string($val) ) {
    return $self->SafeString->new($val);
  } elsif ( !Text::Nunjucks::Lib->is_function($val) ) {
    return $val;
  } else {
    return sub {
      my $ret = $val->(@_);        # val.apply(this, arguments) -- no `this` (ADR 0009)
      return $self->SafeString->new($ret) if Text::Nunjucks::Lib->is_string($ret);
      return $ret;
    };
  }
}

#### suppressValue

sub suppress_value {
  my ( $self, $val, $autoescape ) = @_;

  # JS: val = (val !== undefined && val !== null) ? val : '';
  $val = '' if !defined($val) || $self->_is_none($val);

  if ( $autoescape && !$self->_is_safe_string($val) ) {
    $val = Text::Nunjucks::Lib->escape( $self->_js_to_string($val) );
  }

  return $val;
}

#### ensureDefined

sub ensure_defined {
  my ( $self, $val, $lineno, $colno ) = @_;
  if ( !defined($val) || $self->_is_none($val) ) {
    die $self->_template_error_class->new(
      'attempted to output null or undefined value',
      $lineno + 1,
      $colno + 1
    );
  }
  return $val;
}

#### memberLookup
#
# Upstream is a raw `obj[val]` (any property/method reachable, functions come
# back as a closure bound to the owner). Perl scalars/arrays have no such
# members, so ADR 0008 makes this a curated, in-place emulated String / Array /
# Number surface -- grown on demand, each entry oracle-verified. String
# indexing, .length and the string methods reckon in UTF-16 code units through
# the Lib seams of ADR 0012; ToNumber / ToString of their arguments stay here.
#
# ADR 0016 split: this function is the PROPERTY-ACCESS seam
# (`member_lookup($obj, $key)` returns the value the template would see at
# `{{ obj.key }}`); the METHOD-CALL seam `member_lookup_method` returns a bound
# coderef for `{{ obj.key() }}`. The compiler picks at the AST site
# (compile_lookup_val vs compile_fun_call -> the latter on a LookupVal name).

my %STRING_METHODS = (
  # JS case mapping (Final_Sigma, ß -> SS, lone surrogates unchanged) is the
  # one Lib seam the lower / upper / capitalize filters use as well
  toUpperCase => sub { my ( $self, $s ) = @_; Text::Nunjucks::Lib->js_to_upper_case($s) },
  toLowerCase => sub { my ( $self, $s ) = @_; Text::Nunjucks::Lib->js_to_lower_case($s) },
  trim => sub {
    my ( $self, $s ) = @_;
    my $ws = Text::Nunjucks::Lib->js_whitespace_class;    # ADR 0005 seam
    $s =~ s/\A(?:$ws)+//;
    $s =~ s/(?:$ws)+\z//;
    return $s;
  },
  replace => sub {
    # String.prototype.replace(searchValue, replaceValue): a regex pattern runs
    # RegExp.prototype[Symbol.replace] (ADR 0013); a string pattern replaces its
    # FIRST occurrence, with a coderef's result (called with matched, position,
    # string) or the replacement string's $ patterns (GetSubstitution). Oracle:
    # 'abc'.replace('b', '$&$&') -> abbc, 'a1b'.replace(r/\d/, '-') -> a-b.
    my ( $self, $s, $pattern, $repl ) = @_;
    return $pattern->symbol_replace( $s, $repl ) if $self->_is_regex($pattern);
    my $functional = Text::Nunjucks::Lib->is_function($repl);
    $pattern = $self->_js_to_string($pattern);
    $repl    = $self->_js_to_string($repl) unless $functional;
    my $idx = Text::Nunjucks::Lib->js_string_index_of( $s, $pattern );
    return $s if $idx < 0;
    my $replacement = $functional
      ? $self->_js_to_string( $repl->( $pattern, $idx, $s ) )
      : Text::Nunjucks::Lib->js_get_substitution( $pattern, $s, $idx, [], undef, $repl );
    # preceding + replacement + following, joined in code units (ADR 0012)
    my $out = Text::Nunjucks::Lib->js_substring( $s, 0, $idx );
    Text::Nunjucks::Lib->js_string_append( $out, $replacement );
    Text::Nunjucks::Lib->js_string_append( $out,
      Text::Nunjucks::Lib->js_substring( $s, $idx + Text::Nunjucks::Lib->js_string_length($pattern) ) );
    return $out;
  },
  slice => sub {
    my ( $self, $s, $start, $end ) = @_;
    return Text::Nunjucks::Lib->js_string_slice( $s,
      $self->_to_number_or_undef($start), $self->_to_number_or_undef($end) );
  },
  substring => sub {
    my ( $self, $s, $start, $end ) = @_;
    return Text::Nunjucks::Lib->js_substring( $s,
      $self->_to_number_or_undef($start), $self->_to_number_or_undef($end) );
  },
  substr => sub {
    my ( $self, $s, $start, $length ) = @_;
    return Text::Nunjucks::Lib->js_substr( $s,
      $self->_to_number_or_undef($start), $self->_to_number_or_undef($length) );
  },
  split => sub {
    my ( $self, $s, $sep, $limit ) = @_;
    # ToString(separator) unless undefined (split() -> [whole string]); a null
    # separator is the string 'null'
    return Text::Nunjucks::Lib->js_split( $s,
      defined($sep) ? $self->_js_to_string($sep) : undef, $self->_to_number_or_undef($limit) );
  },
  indexOf => sub {
    my ( $self, $s, $search, $from ) = @_;
    return Text::Nunjucks::Lib->js_string_index_of( $s,
      $self->_js_to_string($search), $self->_to_number_or_undef($from) );
  },
  lastIndexOf => sub {
    my ( $self, $s, $search, $from ) = @_;
    return Text::Nunjucks::Lib->js_string_last_index_of( $s,
      $self->_js_to_string($search), $self->_to_number_or_undef($from) );
  },
  charAt => sub {
    my ( $self, $s, $i ) = @_;
    return Text::Nunjucks::Lib->js_char_at( $s, $self->_to_number_or_undef($i) );
  },
  concat => sub {
    my ( $self, $s, @args ) = @_;
    Text::Nunjucks::Lib->js_string_append( $s, $self->_js_to_string($_) ) for @args;    # ADR 0012
    return $s;
  },
);

my %ARRAY_METHODS = (
  join => sub {
    my ( $self, $arr, $sep ) = @_;
    $sep = defined($sep) ? $self->_js_to_string($sep) : ',';
    return $self->_array_join( $arr, $sep );
  },
  indexOf => sub {
    my ( $self, $arr, $search, $from ) = @_;
    return Text::Nunjucks::Lib->index_of( $arr, $search, $from );
  },
  lastIndexOf => sub {
    # Array.prototype.lastIndexOf(searchElement[, fromIndex]): strict equality,
    # scanning back from fromIndex -- length - 1 when absent, counted from the
    # end when negative. Oracle: [1,2,1].lastIndexOf(1) 2, (1, 1) 0, (1, -1) 2,
    # (1, -2) 0, (1, -9) -1, (1, 9) 2, (1, 'x') 0. The truncate filter reaches
    # it on an array input (input.lastIndexOf(' ', length)).
    my ( $self, $arr, $search, @from ) = @_;
    my $len = scalar @$arr;
    return -1 if $len == 0;
    my $n = @from ? Text::Nunjucks::Lib->_js_to_integer_or_infinity( $self->_to_number( $from[0] ) ) : $len - 1;
    return -1 if $n == $NEG_INF;
    my $k = $n >= 0 ? ( $n < $len - 1 ? $n : $len - 1 ) : $len + $n;
    for ( my $i = $k; $i >= 0; $i-- ) {
      return $i if Text::Nunjucks::Lib->_strict_eq( $arr->[$i], $search );
    }
    return -1;
  },
  slice => sub {
    my ( $self, $arr, $start, $end ) = @_;
    my $len = scalar @$arr;
    ( $start, $end ) = $self->_slice_bounds( $len, $start, $end );
    return [] if $start >= $end;
    return [ @{$arr}[ $start .. $end - 1 ] ];
  },
  concat => sub {
    my ( $self, $arr, @args ) = @_;
    my @new = @$arr;
    for my $a (@args) {
      if ( Text::Nunjucks::Lib->is_array($a) ) { push @new, @$a }
      else                                     { push @new, $a }
    }
    return \@new;
  },
  filter => sub {
    # Array.prototype.filter(callbackfn[, thisArg]): the length is read once,
    # callbackfn gets (element, index, array) and no this (ADR 0009), an index
    # the callback removed is skipped, an element is kept when the result is
    # truthy. Oracle: [1, 0, '', 2].filter(m) with a macro m printing its
    # argument keeps 1,0,,2 (its output is a SafeString, an object); a
    # callbackfn that is not callable -> "TypeError: number 5 is not a
    # function", none -> "TypeError: object null is not a function", no
    # argument -> "TypeError: undefined is not a function". The select /
    # reject / selectattr / rejectattr filters' .filter reaches it.
    my ( $self, $arr, $callbackfn ) = @_;
    die $self->_error_class->new( $self->_js_not_callable_text($callbackfn) . ' is not a function', name => 'TypeError' )
      unless Text::Nunjucks::Lib->is_function($callbackfn);
    my $len = scalar @$arr;
    my @a;
    for ( my $k = 0; $k < $len; $k++ ) {
      next if $k >= scalar @$arr;    # HasProperty(O, k)
      my $k_value = $arr->[$k];
      push @a, $k_value if $self->_truthy( $callbackfn->( $k_value, $k, $arr ) );
    }
    return \@a;
  },
  reduce => sub {
    # Array.prototype.reduce(callbackfn[, initialValue]): the length is read
    # once, callbackfn gets (accumulator, element, index, array), an index the
    # callback removed is skipped. Oracle: [1,2,3].reduce(f, 0) with f(a, b)
    # returning a + b -> 123 (macro output is a string), f(a, b, i, arr) sees
    # x:1:0:2 then :2:1:2. [].reduce(f) -> "TypeError: Reduce of empty array
    # with no initial value"; a callbackfn that is not callable is checked
    # first -> "TypeError: number 5 is not a function". The sum filter's
    # arr.reduce reaches it.
    my ( $self, $arr, $callbackfn, @initial_value ) = @_;
    die $self->_error_class->new( $self->_js_not_callable_text($callbackfn) . ' is not a function', name => 'TypeError' )
      unless Text::Nunjucks::Lib->is_function($callbackfn);
    my $len = scalar @$arr;
    my $k   = 0;
    my $accumulator;
    if (@initial_value) {
      $accumulator = $initial_value[0];
    } else {
      die $self->_error_class->new( 'Reduce of empty array with no initial value', name => 'TypeError' )
        if $len == 0;
      $accumulator = $arr->[ $k++ ];
    }
    for ( ; $k < $len; $k++ ) {
      next if $k >= scalar @$arr;    # HasProperty(O, k)
      $accumulator = $callbackfn->( $accumulator, $arr->[$k], $k, $arr );
    }
    return $accumulator;
  },
  # mutators -- change the underlying Perl structure in place (ADR 0008)
  push => sub {
    my ( $self, $arr, @args ) = @_;
    push @$arr, @args;
    return scalar @$arr;             # Array.push returns the new length
  },
  pop => sub {
    my ( $self, $arr ) = @_;
    return undef unless @$arr;       # JS pop() on [] -> undefined
    return pop @$arr;
  },
  shift => sub {
    my ( $self, $arr ) = @_;
    return undef unless @$arr;
    return shift @$arr;
  },
  unshift => sub {
    my ( $self, $arr, @args ) = @_;
    unshift @$arr, @args;
    return scalar @$arr;
  },
  sort => sub {
    # Array.prototype.sort([comparefn]): V8's TimSort, the one Lib seam
    # (decision B, k17) -- undefined last and never compared, ToStrings in
    # UTF-16 code-unit order without a comparefn, a comparefn's result through
    # ToNumber. Oracle: [u, 'z', 'a'].sort() -> a,z,undefined; a macro m(a, b)
    # giving a - b sorts [3, 1, 10, 2] to 1,2,3,10; sort(5) -> "TypeError: The
    # comparison function must be either a function or undefined: 5".
    my ( $self, $arr, $comparefn ) = @_;
    return Text::Nunjucks::Lib->js_array_sort( $arr, $comparefn );
  },
  reverse => sub {
    my ( $self, $arr ) = @_;
    @$arr = reverse @$arr;
    return $arr;
  },
);

my %NUMBER_METHODS = (
  toFixed => sub {
    my ( $self, $n, $digits ) = @_;
    $digits = defined($digits) ? int( $self->_to_number($digits) ) : 0;
    return sprintf( '%.*f', $digits, $n );
  },
);

sub member_lookup {
  my ( $self, $obj, $val ) = @_;

  # if (obj === undefined || obj === null) return undefined;
  return undef if !defined($obj) || $self->_is_none($obj);

  # SafeString extends String in JS: member access works off its value.
  my $str_target = $self->_is_safe_string($obj) ? $obj->val : undef;

  my $key = $self->_member_key($val);           # JS ToString of the lookup key

  # Regex surface (ADR 0013): source / flags / global / lastIndex are property
  # reads, not method calls. `test` and `exec` are method-shaped and go through
  # member_lookup_method (FunCall path). lastIndex is template-visible
  # ({{ r.lastIndex }}) and reflects the JS RegExp match position; it advances
  # after a g/y match and resets to 0 on no-match.
  if ( $self->_is_regex($obj) ) {
    return $obj->source    if $key eq 'source';
    return $obj->flags     if $key eq 'flags';
    return $obj->global    if $key eq 'global';
    return $obj->lastIndex if $key eq 'lastIndex';
    return undef;
  }

  # Array surface
  if ( Text::Nunjucks::Lib->is_array($obj) ) {
    if ( $self->_is_index_key($key) ) {
      my $i = 0 + $key;
      return undef if $i >= scalar @$obj;
      return $obj->[$i];
    }
    return scalar @$obj if $key eq 'length';
    if ( $ARRAY_METHODS{$key} ) {                 # ADR 0016: method on FunCall seam
      return sub { $ARRAY_METHODS{$key}->( $self, $obj, @_ ) };
    }
    return undef;
  }

  # String surface (plain string or SafeString value)
  if ( defined($str_target) || Text::Nunjucks::Lib->is_string($obj) ) {
    my $s = defined($str_target) ? $str_target : $obj;
    # A primitive string has JS exotic index access (s[0]); a SafeString is a
    # String OBJECT -- length + methods but NO index access (oracle: on a
    # SafeString `s[0]` and `s['0']` render ''). So gate indexing to plain
    # strings only, never $str_target (the SafeString case).
    # Index and length count UTF-16 code units (ADR 0012): s[i] past an astral
    # character lands one further, and inside one yields a lone surrogate. One
    # charAt call measures the string once; its '' (a code unit is never empty)
    # is the index past the end, where s[i] is undefined.
    if ( !defined($str_target) && $self->_is_index_key($key) ) {
      my $unit = Text::Nunjucks::Lib->js_char_at( $s, 0 + $key );
      return $unit eq '' ? undef : $unit;
    }
    return Text::Nunjucks::Lib->js_string_length($s) if $key eq 'length';
    if ( $STRING_METHODS{$key} ) {               # ADR 0016: method on FunCall seam
      return sub { $STRING_METHODS{$key}->( $self, $s, @_ ) };
    }
    return undef;
  }

  # Number surface
  if ( created_as_number($obj) ) {
    if ( $NUMBER_METHODS{$key} ) {
      return sub { $NUMBER_METHODS{$key}->( $self, $obj, @_ ) };
    }
    return undef;
  }

  # Ordered hash (template dict literal / engine-built object, ADR 0011): read
  # it like a plain object before the generic blessed-object branch below.
  if ( $self->_is_ordered_hash($obj) ) {
    return $obj->exists($key) ? $obj->get($key) : undef;
  }

  # Plain hashref: property access (a coderef value is returned as-is and
  # called with no `this` per ADR 0009).
  if ( ref($obj) eq 'HASH' ) {
    return exists( $obj->{$key} ) ? $obj->{$key} : undef;
  }

  # Blessed user object (ADR 0016: this seam returns the VALUE -- an accessor
  # call or a Moo attribute read -- not a bound coderef. The coderef comes from
  # member_lookup_method, which the compiler emits at FunCall sites).
  if ( blessed($obj) ) {
    return $obj->$key if $obj->can($key);
    return undef;
  }

  return undef;
}

# ADR 0016: the second half of the split. Where member_lookup returns the value
# of a property, member_lookup_method returns a bound coderef for the method at
# $key, ready to be passed to call_wrap. The two branches land on different
# emitted symbols in the compiled Perl; FunCall -> member_lookup_method, every
# other property read -> member_lookup.
sub member_lookup_method {
  my ( $self, $obj, $val ) = @_;

  return undef if !defined($obj) || $self->_is_none($obj);

  my $key = $self->_member_key($val);

  # Regex: test/exec are method-shaped; source/flags/global are properties
  # (FunCall would be `{{ r.test("...") }} }`).
  if ( $self->_is_regex($obj) ) {
    return sub { $obj->test(@_) } if $key eq 'test';
    return sub { $obj->exec(@_) } if $key eq 'exec';
    return undef;
  }

  # String surface -- emulated methods come back bound to the string value.
  if ( Text::Nunjucks::Lib->is_string($obj) || $self->_is_safe_string($obj) ) {
    my $s = $self->_is_safe_string($obj) ? $obj->val : $obj;
    return sub { $STRING_METHODS{$key}->( $self, $s, @_ ) } if $STRING_METHODS{$key};
    return undef;
  }

  # Array surface
  if ( Text::Nunjucks::Lib->is_array($obj) ) {
    return sub { $ARRAY_METHODS{$key}->( $self, $obj, @_ ) } if $ARRAY_METHODS{$key};
    return undef;
  }

  # Number surface
  if ( created_as_number($obj) ) {
    return sub { $NUMBER_METHODS{$key}->( $self, $obj, @_ ) } if $NUMBER_METHODS{$key};
    return undef;
  }

  # Hashref (plain or ordered): the FunCall site must produce a coderef, so
  # we only return one if the value is callable. Upstream: calling a
  # non-function member on a plain object is a TypeError ("not a function")
  # -- we mirror that by returning undef and letting call_wrap produce the
  # exact upstream text.
  if ( ref($obj) eq 'HASH' || $self->_is_ordered_hash($obj) ) {
    # a Hash::Ordered is a blessed array, never dereferenced as a hash
    my $fn = $self->_is_ordered_hash($obj)
      ? ( $obj->exists($key) ? $obj->get($key) : undef )
      : ( exists( $obj->{$key} ) ? $obj->{$key} : undef );
    return Text::Nunjucks::Lib->is_function($fn) ? $fn : undef;
  }

  # Blessed user object: `{{ obj.foo() }} }` needs a bound coderef.
  if ( blessed($obj) ) {
    return sub { $obj->$key(@_) } if $obj->can($key);
    return undef;
  }

  return undef;
}

# Port addition, ADR 0016 / ADR 0010: a native method call the engine's own
# JavaScript makes on a value it never checked -- filters.js runs
# str.toLowerCase(), str.split('\n'), input.lastIndexOf(' ', length) on whatever
# the template piped in. JS reads the member and calls it: on undefined / null
# the read throws, on a value without that method the call does, both as a
# TypeError whose text V8 builds from the source expression, so the caller
# names the upstream variable ($src). Oracle: 5|lower -> "TypeError:
# str.toLowerCase is not a function", undefined|trim -> "TypeError: Cannot read
# properties of undefined (reading 'replace')".
sub js_method_call {
  my ( $self, $obj, $src, $name, @args ) = @_;
  my $method = $self->member_lookup_method( $obj, $name );
  die $self->_js_method_error( $obj, $src, $name ) unless Text::Nunjucks::Lib->is_function($method);
  return $method->(@args);
}

# Port addition, same seam: the string a String.prototype method the engine
# calls with one of its own regexes (str.replace(/\r\n|\n/g, ...),
# str.match(/\w+/g)) works on -- the value itself, a SafeString's value (a
# String object), else the TypeError js_method_call throws for the member
# ($name) upstream calls.
sub js_string_this {
  my ( $self, $obj, $src, $name ) = @_;
  return $obj->val if $self->_is_safe_string($obj);
  return $obj      if Text::Nunjucks::Lib->is_string($obj);
  die $self->_js_method_error( $obj, $src, $name );
}

sub _js_method_error {
  my ( $self, $obj, $src, $name ) = @_;
  return $self->_js_read_error( $obj, $name ) if !defined($obj) || $self->_is_none($obj);
  return $self->_error_class->new( $src . '.' . $name . ' is not a function', name => 'TypeError' );
}

# Port addition, same seam: a plain property read obj[key] the engine's own
# JavaScript makes on a value it never checked -- filters.js reads arr[0],
# arr.length, v[attr] off whatever the template piped in. On undefined / null
# the read throws V8's TypeError (oracle: undefined|first -> "TypeError: Cannot
# read properties of undefined (reading '0')", null|last -> "... of null
# (reading 'length')"); on anything else it is member_lookup, the JS property
# read of the ADR 0008 surface. The key is used as given -- v[attr] with attr
# 'a.b' reads the key 'a.b', no path.
sub js_member_read {
  my ( $self, $obj, $key ) = @_;
  die $self->_js_read_error( $obj, $key ) if !defined($obj) || $self->_is_none($obj);
  return $self->member_lookup( $obj, $key );
}

# V8's text for a property read on undefined / null. It names the key as V8
# prints it without side effects, Object::NoSideEffectsToMaybeString (oracle,
# with v undefined in [v]|join(',', k)): a string as is, a number or boolean as
# its ToString ('1.5', 'true'), a plain object as '#<Object>' or its
# constructor's name; a key with no such form drops the "(reading ...)" clause
# -- an array, a SafeString, a regex, a plain object with an own toString
# ({'toString': 1}) or an own constructor that is no named function
# ({'constructor': 1}).
sub _js_read_error {
  my ( $self, $obj, $key ) = @_;
  my $name = $self->_js_no_side_effects_to_maybe_string($key);
  return $self->_error_class->new(
    'Cannot read properties of ' . $self->_js_type($obj) . ( defined($name) ? " (reading '" . $name . "')" : '' ),
    name => 'TypeError'
  );
}

# V8's rendering of a value in a message it formats itself, where it may also
# have none (Object::NoSideEffectsToMaybeString, V8 13.6.233.17
# src/objects/objects.cc): undefined, null, a boolean, a number and a string
# as their ToString -- a string as is, not cut. An object is looked at without
# running anything: GetDataProperty(o, 'toString'), an own key first, else the
# prototype's. Only an object whose toString is Object.prototype's has a form,
# and only through GetDataProperty(o, 'constructor'): a function with a
# non-empty name shows as '#<name>'. For the plain objects the port models --
# a dict literal, a caller hash, keyword arguments, all with Object.prototype
# as their prototype -- that is (oracle, [2, 1].sort(x) and [v]|join(',', x)):
#   * an own toString key, whatever it holds ({'toString': 1}, {'toString':
#     u}, toString=1): no form;
#   * else an own constructor key: '#<name>' when it is a function with a name
#     ({'constructor': m}, a macro m -> '#<macro>'; in node a function with an
#     empty name gives no form), else no form ({'constructor': 1}, '', u, none,
#     [] and a SafeString all have none);
#   * else Object.prototype.constructor, Object: '#<Object>'.
# An array, a regex and a SafeString have a toString of their own: no form. A
# function would show its JS source, which has no Perl form; it has none here,
# and neither does any other blessed object. Returns undef for no form.
sub _js_no_side_effects_to_maybe_string {
  my ( $self, $v ) = @_;
  return $self->_js_to_string($v) if !ref($v) || $self->_is_none($v);
  return undef unless ref($v) eq 'HASH' || $self->_is_ordered_hash($v) || $self->_is_kwargs($v);
  my $own = $self->_is_ordered_hash($v)
    ? sub { $v->exists( $_[0] ) }
    : sub { exists $v->{ $_[0] } };
  return undef if $own->('toString');
  return '#<Object>' unless $own->('constructor');
  my $ctor = Text::Nunjucks::Lib->_own_value( $v, 'constructor' );
  my $name = Text::Nunjucks::Lib->is_function($ctor) ? $self->_js_function_name($ctor) : '';
  return $name ne '' ? '#<' . $name . '>' : undef;
}

# V8's rendering of a value in a message it formats itself
# (Object::NoSideEffectsToString; oracle with [2, 1].sort(x), Array sort's
# comparison-function TypeError): its NoSideEffectsToMaybeString form, else
# '[object ' . its class name . ']' -- a dict literal, caller hash or keyword
# arguments with an own toString or a constructor that is no named function
# ({'toString': 1}, {'constructor': 1}) as '[object Object]', an array as
# '[object Array]', a regex as '[object RegExp]' and a SafeString as '[object
# Object]'. No Symbol.toStringTag is reachable from a template. A function
# would show its JS source; the one caller never hands it one. Any other
# blessed object shows as '#<Object>', a plain object's form (the port's
# choice, no JS counterpart to measure).
sub _js_no_side_effects_to_string {
  my ( $self, $v ) = @_;
  my $shown = $self->_js_no_side_effects_to_maybe_string($v);
  return $shown if defined $shown;
  return '[object Array]'  if ref($v) eq 'ARRAY';
  return '[object RegExp]' if $self->_is_regex($v);
  return '[object Object]'
    if ref($v) eq 'HASH' || $self->_is_ordered_hash($v) || $self->_is_kwargs($v) || $self->_is_safe_string($v);
  return '#<Object>';
}

# JSFunction::GetName, the name V8 shows for a function in its own messages.
# A template cannot rename a function, so it is the function's name property
# as a template reads it: a macro's is 'macro' upstream (makeMacro returns
# `function macro(...)`), a caller's function has the name JS gave it. A Perl
# coderef owns no name property yet (k88), so this is '' -- V8's "no name" --
# until member_lookup gives functions their own properties.
sub _js_function_name {
  my ( $self, $fn ) = @_;
  my $name = $self->member_lookup( $fn, 'name' );
  return Text::Nunjucks::Lib->is_string($name) ? $name : '';
}

# V8's rendering of a value a builtin was handed to call that is not callable
# (Array reduce's callbackfn; oracle with [1].reduce(x)): undefined ->
# 'undefined', null -> 'object null', a boolean or number -> its type and
# ToString ('boolean true', 'number 1.5', 'number NaN'), a string -> 'string
# "x"', cut to its first 100 code units and '<...>' when longer, a function ->
# 'function', any other object -> 'object'. V8 renders a value it cannot iterate
# the same way (js_array_destructure; oracle: [m]|urlencode with a macro m ->
# "function is not iterable ...").
sub _js_not_callable_text {
  my ( $self, $v ) = @_;
  return 'undefined'   if !defined($v);
  return 'object null' if $self->_is_none($v);
  my $type = $self->_js_type($v);
  return $type . ' ' . $self->_js_to_string($v) if $type eq 'boolean' || $type eq 'number';
  return 'function' if Text::Nunjucks::Lib->is_function($v);
  return 'object' unless $type eq 'string';
  my $shown = Text::Nunjucks::Lib->js_string_length($v) > 100
    ? Text::Nunjucks::Lib->js_substring( $v, 0, 100 ) . '<...>'
    : $v;
  return 'string "' . $shown . '"';
}

# Port addition, same seam: the array destructuring pattern the engine's own
# JavaScript binds -- urlencode's keyvals.map(([k, v]) => ...) -- over whatever
# the template handed it. ES runs the iteration protocol: an array yields its
# elements, a string -- primitive, or a SafeString's value (a String object) --
# its code points, a lone surrogate on its own (oracle: ['\u{1F600}b']|urlencode
# -> %F0%9F%98%80=b). The first $count come back, undefined past the end. Any
# other value has no Symbol.iterator and throws V8's TypeError, the value
# rendered as for a call (oracle: [5]|urlencode -> "number 5 is not iterable
# (cannot read property Symbol(Symbol.iterator))", [{}] -> "object is not
# iterable ...").
sub js_array_destructure {
  my ( $self, $value, $count ) = @_;
  my $items;
  if ( Text::Nunjucks::Lib->is_array($value) ) {
    $items = $value;
  } elsif ( Text::Nunjucks::Lib->is_string($value) || $self->_is_safe_string($value) ) {
    my $s = $self->_is_safe_string($value) ? $value->val : $value;
    $items = [ split //, Text::Nunjucks::Lib->_js_from_units($s) ];
  } else {
    die $self->_js_not_iterable_error($value);
  }
  return CORE::map { $items->[$_] } 0 .. $count - 1;
}

# Port addition, same seam: value[Symbol.iterator] read for its truth value --
# the iterable test's !!value[Symbol.iterator]. Of the values the port models,
# an array, a string and a SafeString (a String object, String.prototype's
# iterator) have one; a number, a boolean, a plain or ordered object, keyword
# arguments, a regex and a function do not. On undefined / null V8 throws its
# not-iterable TypeError for the read (oracle: {{ null is iterable }} ->
# "TypeError: object null is not iterable (cannot read property
# Symbol(Symbol.iterator))"). A Map, a Set and a generator have no Perl image
# (k44).
sub js_has_symbol_iterator {
  my ( $self, $value ) = @_;
  die $self->_js_not_iterable_error($value) if !defined($value) || $self->_is_none($value);
  return (
         Text::Nunjucks::Lib->is_array($value)
      || Text::Nunjucks::Lib->is_string($value)
      || $self->_is_safe_string($value)
  ) ? 1 : 0;
}

sub _js_not_iterable_error {
  my ( $self, $value ) = @_;
  return $self->_error_class->new(
    $self->_js_not_callable_text($value) . ' is not iterable (cannot read property Symbol(Symbol.iterator))',
    name => 'TypeError'
  );
}

#### callWrap

sub call_wrap {
  my ( $self, $obj, $name, $context, $args ) = @_;

  if ( $self->_falsy($obj) ) {                     # JS: if (!obj)
    die $self->_error_class->new(
      'Unable to call `' . $name . '`, which is undefined or falsey' );
  } elsif ( !Text::Nunjucks::Lib->is_function($obj) ) {    # typeof obj !== 'function'
    die $self->_error_class->new(
      'Unable to call `' . $name . '`, which is not a function' );
  }

  # JS: obj.apply(context, args). The compiler binds member-call owners inside
  # member_lookup; a bare context coderef gets no `this` (ADR 0009), so the
  # Context passed as $context is not used as an invocant here.
  # A macro that calls itself N deep comes through here N calls deep, as in
  # make_macro (k83).
  no warnings 'recursion';
  return $obj->( @$args );
}

#### contextOrFrameLookup

sub context_or_frame_lookup {
  my ( $self, $context, $frame, $name ) = @_;
  my $val = $frame->lookup($name);
  return defined($val) ? $val : $context->lookup($name);    # val !== undefined
}

#### handleError

sub handle_error {
  my ( $self, $error, $lineno, $colno ) = @_;
  # JS: if (error.lineno) return error; -- an already-positioned TemplateError.
  if ( blessed($error) && $error->can('lineno') && $error->lineno ) {
    return $error;
  }
  return $self->_template_error_class->new( $error, $lineno, $colno );
}

#### asyncEach

sub async_each {
  my ( $self, $arr, $dimen, $iter, $cb ) = @_;

  # Port-only (k83): the loop body $iter is entered once per item before the
  # previous item's call has returned, as upstream nests one JS call per item
  # (ADR 0003); an asyncEach inside a template that includes itself enters
  # async_iter / async_for once per level. Perl warns at the 100th nested call
  # of a sub, at the call site; the depth is bounded by memory, not by Perl,
  # so that warning is off for the calls below (see Lib async_iter).
  no warnings 'recursion';

  if ( Text::Nunjucks::Lib->is_array($arr) ) {
    my $len = scalar @$arr;

    Text::Nunjucks::Lib->async_iter(
      $arr,
      sub {
        my ( $item, $i, $next ) = @_;
        if ( $dimen == 1 ) {
          $iter->( $item, $i, $len, $next );
        } elsif ( $dimen == 2 ) {
          $iter->( $item->[0], $item->[1], $i, $len, $next );
        } elsif ( $dimen == 3 ) {
          $iter->( $item->[0], $item->[1], $item->[2], $i, $len, $next );
        } else {
          push @$item, $i, $len, $next;
          $iter->(@$item);
        }
      },
      $cb
    );
  } else {
    # JS lib.asyncFor does keys(arr || {}); that guard must recognise None (JS
    # null), whose home is Runtime (ADR 0006), so normalise the falsy iterable
    # here before delegating to Lib (which is None-agnostic by design).
    Text::Nunjucks::Lib->async_for(
      $self->_falsy($arr) ? {} : $arr,
      sub {
        my ( $key, $val, $i, $len, $next ) = @_;
        $iter->( $key, $val, $i, $len, $next );
      },
      $cb
    );
  }
}

#### asyncAll

sub async_all {
  my ( $self, $arr, $dimen, $func, $cb ) = @_;

  my $finished = 0;
  my $len;
  my @output_arr;

  my $done = sub {
    my ( $i, $output ) = @_;
    $finished++;
    $output_arr[$i] = $output;

    if ( $finished == $len ) {
      # outputArr.join(''), joined in code units (ADR 0012)
      my $joined = '';
      Text::Nunjucks::Lib->js_string_append( $joined, defined($_) ? $_ : '' ) for @output_arr;
      $cb->( undef, $joined );
    }
  };

  if ( Text::Nunjucks::Lib->is_array($arr) ) {
    $len = scalar @$arr;

    if ( $len == 0 ) {
      $cb->( undef, '' );
    } else {
      for ( my $i = 0; $i < scalar @$arr; $i++ ) {
        my $item = $arr->[$i];
        if ( $dimen == 1 ) {
          $func->( $item, $i, $len, $done );
        } elsif ( $dimen == 2 ) {
          $func->( $item->[0], $item->[1], $i, $len, $done );
        } elsif ( $dimen == 3 ) {
          $func->( $item->[0], $item->[1], $item->[2], $i, $len, $done );
        } else {
          push @$item, $i, $len, $done;
          $func->(@$item);
        }
      }
    }
  } else {
    # JS keys(arr || {}) -- JS-falsiness, None-aware (ADR 0006), not just `// {}`
    # (which would let a None through and crash Lib->keys on the deref).
    my $keys = Text::Nunjucks::Lib->keys( $self->_falsy($arr) ? {} : $arr );
    $len = scalar @$keys;

    if ( $len == 0 ) {
      $cb->( undef, '' );
    } else {
      # JS: func(k, arr[k], i, len, done) -- property access. The same lookup
      # seam the runtime uses for member access (member_lookup) handles
      # Hash::Ordered (template dict literal / engine-built object, ADR 0011)
      # and plain hashrefs, matching arr[k] on a JS plain object; calling it
      # here keeps Runtime::async_all on one seam instead of duplicating the
      # Hash::Ordered branch that Lib::async_for already has.
      for ( my $i = 0; $i < scalar @$keys; $i++ ) {
        my $k = $keys->[$i];
        $func->( $k, $self->member_lookup( $arr, $k ), $i, $len, $done );
      }
    }
  }
}

#### fromIterator

sub from_iterator {
  my ( $self, $arr ) = @_;
  # JS returns arr unless it is a non-null, non-array object with Symbol.iterator
  # (then Array.from). Perl core has no iterator protocol, so the conversion
  # branch is inert and every value passes through unchanged; a future blessed
  # iterable would hook in here.
  return $arr if !defined($arr) || !ref($arr) || $self->_is_none($arr);
  return $arr if Text::Nunjucks::Lib->is_array($arr);
  return $arr;
}

#### re-exported lib helpers (module.exports: isArray, keys, inOperator)

sub is_array   { my ( $self, $obj ) = @_; Text::Nunjucks::Lib->is_array($obj) }
sub keys       { my ( $self, $obj ) = @_; Text::Nunjucks::Lib->keys($obj) }
sub in_operator {
  my ( $self, $key, $val ) = @_;
  return Text::Nunjucks::Lib->in_operator( $key, $val );
}

#### string seams the compiled code calls (ADR 0012) -- port additions

# The output buffer: every `buffer += value` the compiler emits is this call, so
# two halves of a pair written one after the other come out as the one astral
# character, as they do in JS's buffer. The buffer is passed on aliased ($_[1]
# after the shift), so Lib appends to the template's variable in place.
sub js_string_append { shift; Text::Nunjucks::Lib->js_string_append(@_) }

# The single-name {% for %} reads arr.length once and arr[i] per element. On a
# primitive string both are code-unit operations that measure the whole string,
# so per element they would make the loop O(n^2); the loop indexes the string's
# split('') array instead -- the same length and the same arr[i] for every i, as
# a string cannot change under the loop. Anything else passes through, a
# SafeString included (a String object: its arr[i] is undefined, not a unit).
sub _for_code_units {
  my ( $self, $arr ) = @_;
  return Text::Nunjucks::Lib->is_string($arr) ? Text::Nunjucks::Lib->js_split( $arr, '' ) : $arr;
}

#### ------------------------------------------------------------------------
#### JS value model: ToNumber / ToPrimitive / ToString, truthiness (ADR 0007,
#### 0006, 0001). Port additions -- Perl's native operators lack JS semantics.
#### ------------------------------------------------------------------------

sub _dbl { return unpack( 'd', pack( 'd', $_[1] ) ) }   # force to an IEEE double

# JS typeof-ish classifier over the value kinds the port models.
sub _js_type {
  my ( $self, $v ) = @_;
  return 'undefined' if !defined($v);
  return 'null'      if $self->_is_none($v);
  return 'boolean'   if is_bool($v);
  return 'number'    if created_as_number($v);
  return 'string'    if !ref($v);
  return 'object';                        # array / hash / SafeString / blessed
}

# JS truthiness. null (a ref) is falsy, so it is handled before delegating the
# kind-based part to Lib->_falsy (which keeps '0' and empty refs truthy).
sub _falsy {
  my ( $self, $v ) = @_;
  return 1 if $self->_is_none($v);
  return Text::Nunjucks::Lib->_falsy($v);
}

sub _truthy {
  my ( $self, $v ) = @_;
  return $self->_falsy($v) ? 0 : 1;
}

# ECMAScript ToString. null -> "null", undefined -> "undefined" (Array.join and
# suppress_value remap those to '' themselves). Container stringification lives
# here (js-semantics: "mechanism in Runtime") and is order-independent, so it
# does not touch the open k3 object-key-order decision.
sub _js_to_string {
  my ( $self, $v ) = @_;
  return 'undefined' if !defined($v);
  return 'null'      if $self->_is_none($v);
  return ( $v ? 'true' : 'false' ) if is_bool($v);
  return Text::Nunjucks::Lib->number_to_string($v) if created_as_number($v);
  return $v unless ref($v);                                   # string
  return $v->val if $self->_is_safe_string($v);              # SafeString -> value
  return $self->_array_join( $v, ',' ) if ref($v) eq 'ARRAY';# Array.toString => join(',')
  return "$v" if $self->_is_regex($v);                       # Regex.toString -> /source/flags
  return '[object Object]';    # object / other ref (overloaded objects: k8)
}

# Array.prototype.join: null/undefined elements become '' (not "null"); the
# pieces are joined in code units (ADR 0012), so split('').join('') restores
# a string whose astral characters split() cut into halves.
sub _array_join {
  my ( $self, $arr, $sep ) = @_;
  my $out = '';
  for my $i ( 0 .. $#$arr ) {
    my $v = $arr->[$i];
    Text::Nunjucks::Lib->js_string_append( $out, $sep ) if $i > 0;
    Text::Nunjucks::Lib->js_string_append( $out,
      ( !defined($v) || $self->_is_none($v) ) ? '' : $self->_js_to_string($v) );
  }
  return $out;
}

sub _to_primitive {
  my ( $self, $v ) = @_;
  return $v if !defined($v) || $self->_is_none($v) || !ref($v);   # already primitive
  return $v->val if $self->_is_safe_string($v);
  return $self->_js_to_string($v);                                # array/object -> ToString
}

# ECMAScript Number(string): trim JS whitespace, '' -> 0, Infinity spellings,
# 0x/0o/0b radixes, else a valid decimal literal or NaN.
sub _string_to_number {
  my ( $self, $s ) = @_;
  my $ws = Text::Nunjucks::Lib->js_whitespace_class;
  ( my $t = $s ) =~ s/\A(?:$ws)+//;
  $t =~ s/(?:$ws)+\z//;

  return 0 if $t eq '';
  return $POS_INF if $t eq 'Infinity' || $t eq '+Infinity';
  return $NEG_INF if $t eq '-Infinity';
  if ( $t =~ /\A0[xX][0-9a-fA-F]+\z/
    || $t =~ /\A0[oO][0-7]+\z/
    || $t =~ /\A0[bB][01]+\z/ )
  {
    return oct($t) + 0.0;
  }
  if ( $t =~ /\A[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\z/ ) {
    return 0 + $t;
  }
  return $NAN;
}

# ECMAScript ToNumber, always returning a real IEEE double so the operators run
# in JS double arithmetic (Perl would otherwise keep exact 64-bit integers).
sub _to_number {
  my ( $self, $v ) = @_;
  my $n;
  if    ( !defined($v) )         { $n = $NAN }                       # undefined -> NaN
  elsif ( $self->_is_none($v) )  { $n = 0 }                          # null -> 0
  elsif ( is_bool($v) )          { $n = $v ? 1 : 0 }
  elsif ( created_as_number($v) ){ $n = $v }
  elsif ( $self->_is_safe_string($v) ) { $n = $self->_string_to_number( $v->val ) }
  elsif ( !ref($v) )             { $n = $self->_string_to_number($v) }
  else                           { $n = $self->_to_number( $self->_to_primitive($v) ) }
  return $self->_dbl($n);
}

#### JS operators the compiler emits (compiler.js compileAdd/Sub/.../Compare)

sub op_add {
  my ( $self, $a, $b ) = @_;
  my $pa = $self->_to_primitive($a);
  my $pb = $self->_to_primitive($b);
  # JS +: string concat if either primitive is a string, else numeric add.
  if ( Text::Nunjucks::Lib->is_string($pa) || Text::Nunjucks::Lib->is_string($pb) ) {
    my $s = $self->_js_to_string($pa);
    Text::Nunjucks::Lib->js_string_append( $s, $self->_js_to_string($pb) );    # ADR 0012
    return $s;
  }
  return $self->_dbl( $self->_to_number($pa) + $self->_to_number($pb) );
}

# `~` operator -- compiler emits `a + "" + b`, i.e. String(a) . String(b),
# joined in code units (ADR 0012).
sub op_concat {
  my ( $self, $a, $b ) = @_;
  my $s = $self->_js_to_string($a);
  Text::Nunjucks::Lib->js_string_append( $s, $self->_js_to_string($b) );
  return $s;
}

sub op_sub { my ( $self, $a, $b ) = @_; $self->_dbl( $self->_to_number($a) - $self->_to_number($b) ) }

sub op_mul {
  my ( $self, $a, $b ) = @_;
  my $na = $self->_to_number($a);
  my $nb = $self->_to_number($b);
  my $r  = $na * $nb;
  # IEEE keeps a zero product's sign as sign(a) xor sign(b) (so 0 * -1 == -0),
  # but Perl collapses it to +0; a later `1 / (0 * -1)` then needs the -0 (F3).
  # Restore the sign via copysign when the product is zero.
  $r = POSIX::copysign( 0, POSIX::copysign( 1, $na ) * POSIX::copysign( 1, $nb ) )
    if $r == 0;
  return $self->_dbl($r);
}

sub op_div {
  my ( $self, $a, $b ) = @_;
  my $na = $self->_to_number($a);
  my $nb = $self->_to_number($b);
  return $NAN if $na != $na || $nb != $nb;
  if ( $nb == 0 ) {
    return $NAN if $na == 0;    # 0 / 0 (any signs) -> NaN
    # x / +-0 -> +-Infinity with sign = sign(x) xor sign(0); copysign reads the
    # -0 divisor too, so 1/-0 -> -Infinity and -1/-0 -> Infinity (F3).
    my $sign = POSIX::copysign( 1, $na ) * POSIX::copysign( 1, $nb );
    return $sign < 0 ? $NEG_INF : $POS_INF;
  }
  return $self->_dbl( $na / $nb );
}

sub op_mod {
  my ( $self, $a, $b ) = @_;
  my $na = $self->_to_number($a);
  my $nb = $self->_to_number($b);
  return $NAN if $na != $na || $nb != $nb || $nb == 0;    # JS n % 0 -> NaN
  return $self->_dbl( POSIX::fmod( $na, $nb ) );          # JS % keeps sign of dividend
}

sub op_pow {
  my ( $self, $a, $b ) = @_;
  # compiler.js emits Math.pow(a, b): the one Lib seam (1 ** Infinity is NaN)
  return $self->_dbl( Text::Nunjucks::Lib->js_math_pow( $self->_to_number($a), $self->_to_number($b) ) );
}

sub op_floordiv {
  my ( $self, $a, $b ) = @_;
  my $na = $self->_to_number($a);
  my $nb = $self->_to_number($b);
  my $q;
  if ( $nb == 0 ) {
    return $NAN if $na != $na || $na == 0;
    $q = ( $na < 0 ) ? $NEG_INF : $POS_INF;
  } else {
    $q = $na / $nb;
  }
  return $q if $q != $q;                             # NaN
  return $q if $q == $POS_INF || $q == $NEG_INF;     # Math.floor(+-Infinity)
  return $self->_dbl( POSIX::floor($q) );            # Math.floor(a / b)
}

sub op_neg { my ( $self, $a ) = @_; $self->_dbl( -$self->_to_number($a) ) }
sub op_pos { my ( $self, $a ) = @_; $self->_dbl( $self->_to_number($a) ) }

# and / or return the operand (not a boolean); not returns a boolean.
sub op_or  { my ( $self, $a, $b ) = @_; $self->_falsy($a) ? $b : $a }
sub op_and { my ( $self, $a, $b ) = @_; $self->_falsy($a) ? $a : $b }
sub op_not { my ( $self, $a )     = @_; $self->_falsy($a) ? true : false }

sub op_eq  { my ( $self, $a, $b ) = @_; $self->_loose_eq( $a, $b )              ? true : false }
sub op_ne  { my ( $self, $a, $b ) = @_; $self->_loose_eq( $a, $b )              ? false : true }
sub op_seq { my ( $self, $a, $b ) = @_; Text::Nunjucks::Lib->_strict_eq( $a, $b ) ? true : false }
sub op_sne { my ( $self, $a, $b ) = @_; Text::Nunjucks::Lib->_strict_eq( $a, $b ) ? false : true }

sub op_lt { my ( $self, $a, $b ) = @_; my $r = $self->_less_than( $a, $b ); ( defined($r) && $r )  ? true : false }
sub op_gt { my ( $self, $a, $b ) = @_; my $r = $self->_less_than( $b, $a ); ( defined($r) && $r )  ? true : false }
sub op_le { my ( $self, $a, $b ) = @_; my $r = $self->_less_than( $b, $a ); ( defined($r) && !$r ) ? true : false }
sub op_ge { my ( $self, $a, $b ) = @_; my $r = $self->_less_than( $a, $b ); ( defined($r) && !$r ) ? true : false }

# ECMAScript Abstract Equality (==).
sub _loose_eq {
  my ( $self, $a, $b ) = @_;
  my $ta = $self->_js_type($a);
  my $tb = $self->_js_type($b);

  return Text::Nunjucks::Lib->_strict_eq( $a, $b ) ? 1 : 0 if $ta eq $tb;

  return 1
    if ( $ta eq 'null' && $tb eq 'undefined' )
    || ( $ta eq 'undefined' && $tb eq 'null' );
  return 0
    if $ta eq 'null' || $ta eq 'undefined' || $tb eq 'null' || $tb eq 'undefined';

  return $self->_loose_eq( $self->_to_number($a), $b ) if $ta eq 'boolean';
  return $self->_loose_eq( $a, $self->_to_number($b) ) if $tb eq 'boolean';

  return $self->_loose_eq( $a, $self->_to_number($b) ) if $ta eq 'number' && $tb eq 'string';
  return $self->_loose_eq( $self->_to_number($a), $b ) if $ta eq 'string' && $tb eq 'number';

  return $self->_loose_eq( $self->_to_primitive($a), $b )
    if $ta eq 'object' && ( $tb eq 'number' || $tb eq 'string' );
  return $self->_loose_eq( $a, $self->_to_primitive($b) )
    if $tb eq 'object' && ( $ta eq 'number' || $ta eq 'string' );

  return 0;
}

# ECMAScript Abstract Relational Comparison; returns 1, 0, or undef (a NaN
# operand, which every comparison operator turns into false).
sub _less_than {
  my ( $self, $x, $y ) = @_;
  my $px = $self->_to_primitive($x);
  my $py = $self->_to_primitive($y);

  if ( $self->_js_type($px) eq 'string' && $self->_js_type($py) eq 'string' ) {
    return Text::Nunjucks::Lib->js_string_compare( $px, $py ) < 0 ? 1 : 0;   # code units (ADR 0012)
  }

  my $nx = $self->_to_number($px);
  my $ny = $self->_to_number($py);
  return undef if $nx != $nx || $ny != $ny;    # NaN
  return ( $nx < $ny ) ? 1 : 0;
}

#### helpers for the emulated member surface

# JS uses ToInteger on slice bounds; this clamps like Array slice (negatives
# count from the end). Strings slice through the Lib seams (ADR 0012).
sub _slice_bounds {
  my ( $self, $len, $start, $end ) = @_;
  # ToIntegerOrInfinity: NaN is 0, so [1,2,3].slice(0, 'x') is [] (oracle, k55)
  $start = defined($start) ? Text::Nunjucks::Lib->_js_to_integer_or_infinity( $self->_to_number($start) ) : 0;
  $end   = defined($end)   ? Text::Nunjucks::Lib->_js_to_integer_or_infinity( $self->_to_number($end) )   : $len;
  $start = $start < 0 ? ( $len + $start > 0 ? $len + $start : 0 ) : ( $start > $len ? $len : $start );
  $end   = $end < 0   ? ( $len + $end > 0   ? $len + $end   : 0 ) : ( $end > $len   ? $len : $end );
  return ( $start, $end );
}

# ToNumber of an optional numeric method argument, keeping JS `undefined` as
# undef: the Lib string seams (ADR 0012) give undefined its per-parameter
# meaning (slice's end -> length, lastIndexOf's position -> +Infinity, ...).
sub _to_number_or_undef {
  my ( $self, $v ) = @_;
  return defined($v) ? $self->_to_number($v) : undef;
}

# The JS string key that `obj[val]` uses to look a member up.
sub _member_key {
  my ( $self, $val ) = @_;
  return 'undefined' if !defined($val);
  return 'null'      if $self->_is_none($val);
  return ( $val ? 'true' : 'false' )                if is_bool($val);
  return Text::Nunjucks::Lib->number_to_string($val) if created_as_number($val);
  return $val unless ref($val);
  return $self->_js_to_string($val);
}

sub _is_index_key {
  my ( $self, $key ) = @_;
  return ( $key =~ /\A(?:0|[1-9][0-9]*)\z/ ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime - 1:1 port of Nunjucks src/runtime.js -- frames, macros, member lookup

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A 1:1 port of Nunjucks C<src/runtime.js>: the C<Frame> scope chain, macros and keyword
arguments, member and call lookup, output suppression and C<SafeString>, and the
JavaScript operators the compiled templates call (ADR 0001, 0006, 0007, 0009).
The classes it works with each have their own file (ADR 0020):
L<Text::Nunjucks::Runtime::Frame>, L<Text::Nunjucks::Runtime::SafeString>,
L<Text::Nunjucks::Runtime::None> (the object that stands for JavaScript's C<null>,
ADR 0006), L<Text::Nunjucks::Runtime::KwArgs> and L<Text::Nunjucks::Runtime::Regex>.
This module loads them and hands them out by name. Everything is called as a class
method; C<$runtime> in the compiled code is this class's name.

Engine-internal: used by L<Text::Nunjucks::Environment> and the code the compiler emits, and
not an interface for applications, with two exceptions: C<< Text::Nunjucks::Runtime->None >>
returns the null object for template contexts, and filters receive keyword arguments as a
C<Text::Nunjucks::Runtime::KwArgs> object.

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
