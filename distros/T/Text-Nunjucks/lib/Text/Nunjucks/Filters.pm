package Text::Nunjucks::Filters;
# ABSTRACT: 1:1 port of Nunjucks src/filters.js -- the built-in filters

our $VERSION = '0.001';

use strict;
use warnings;
use builtin qw( is_bool true false );
use Scalar::Util qw( weaken );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Lib::TemplateError;
use Text::Nunjucks::Runtime;

no warnings 'experimental::builtin';

# filters.js is a bag of `exports.<name> = fn` filter functions. The port keeps
# upstream's order and names (snake_case); each filter is a class method
# dispatched through $self, like Lib and Runtime, so a filter that calls another
# one (title -> capitalize, striptags -> trim) goes through the invocant, and a
# filter named like a Perl builtin (abs, dump, truncate, join, reverse, sort)
# never resolves to the builtin. The two filters upstream builds with
# r.makeMacro (sort and int) are their inner function as a method (sort_filter,
# do_int), wrapped by Runtime make_macro in exports. A filter receives what the
# template passed (ADR 0009): the value, the arguments, keyword arguments as a
# trailing KwArgs hashref.
#
# `exports($env)` builds the { name => coderef } bag that Environment.init
# registers with add_filter, once per Environment. Upstream calls a filter with
# `this` set to the render Context, which the port does not hand a filter (ADR
# 0009). The filters that read `this.env` -- groupby, sort, select and reject,
# for env.opts.throwOnUndefined and env.getTest -- take the Environment as
# their first argument instead, from the closure exports builds; every other
# closure captures only the class name. That closure holds a weakened copy of
# $env: the Environment holds the bag, so Environment -> filters -> closure ->
# Environment would be a reference cycle otherwise. A filter not ported yet is
# absent from the bag, so it is "filter not found" like any unknown name.
#
# JS operators go through Runtime (ADR 0001 / 0006 / 0007); a native method
# upstream calls on a value it never checked goes through Runtime
# js_method_call / js_string_this, which throw V8's TypeError (ADR 0010);
# lengths, positions and joins go through the Lib UTF-16 seams (ADR 0012); the
# engine's own regexes use the explicit ECMAScript classes of ADR 0005.

sub _lib                  { 'Text::Nunjucks::Lib' }
sub _runtime              { 'Text::Nunjucks::Runtime' }
sub _error_class          { 'Text::Nunjucks::Lib::Error' }
sub _template_error_class { 'Text::Nunjucks::Lib::TemplateError' }

#### normalize

sub normalize {
  my ( $self, $value, $default_value ) = @_;
  if ( !defined($value) || $self->_runtime->_is_none($value) || ( is_bool($value) && !$value ) ) {
    return $default_value;
  }
  return $value;
}

#### abs -- exports.abs = Math.abs

# Math.abs itself is the filter, called as (value, ...args): ToNumber on the
# value, every other argument ignored (oracle: 'abc'|abs is NaN, none|abs is 0,
# 1 / ((-0)|abs) is Infinity -- the result is +0).
sub abs {
  my ( $self, $x ) = @_;
  return $self->_lib->js_math_abs( $self->_runtime->_to_number($x) );
}

#### isNaN

# The module-local isNaN, not the global one: num !== num, no coercion (oracle:
# 'www.x.com'|urlize('abc') gives an empty link text -- 'abc' is not NaN here).
sub is_nan {
  my ( $self, $num ) = @_;
  return $self->_runtime->op_sne( $num, $num );
}

#### batch

sub batch {
  my ( $self, $arr, $linecount, $fill_with ) = @_;
  my $rt = $self->_runtime;
  my $i;
  my $res = [];
  my $tmp = [];

  # arr.length and arr[i] are read on every pass; a primitive string is read
  # through its code units, the same length and arr[i] (ADR 0012)
  $arr = $rt->_for_code_units($arr);
  for ( $i = 0; $rt->op_lt( $i, $rt->js_member_read( $arr, 'length' ) ); $i++ ) {
    if ( $rt->op_seq( $rt->op_mod( $i, $linecount ), 0 ) && @$tmp ) {
      push @$res, $tmp;
      $tmp = [];
    }

    push @$tmp, $rt->js_member_read( $arr, $i );
  }

  if (@$tmp) {
    if ( $rt->_truthy($fill_with) ) {
      for ( $i = scalar @$tmp; $rt->op_lt( $i, $linecount ); $i++ ) {
        push @$tmp, $fill_with;
      }
    }

    push @$res, $tmp;
  }

  return $res;
}

#### capitalize

sub capitalize {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  $str = $self->normalize( $str, '' );
  my $ret = $rt->js_method_call( $str, 'str', 'toLowerCase' );
  return $rt->copy_safeness(
    $str,
    $rt->op_add(
      $rt->js_method_call( $rt->js_method_call( $ret, 'ret', 'charAt', 0 ), 'ret.charAt(...)', 'toUpperCase' ),
      $rt->js_method_call( $ret, 'ret', 'slice', 1 )
    )
  );
}

#### center

sub center {
  my ( $self, $str, $width ) = @_;
  my $rt = $self->_runtime;
  $str   = $self->normalize( $str, '' );
  $width = $rt->op_or( $width, 80 );

  if ( $rt->op_ge( $rt->member_lookup( $str, 'length' ), $width ) ) {
    return $str;
  }

  my $spaces = $rt->op_sub( $width, $rt->member_lookup( $str, 'length' ) );
  my $pre    = $self->_lib->repeat( ' ', $rt->op_sub( $rt->op_div( $spaces, 2 ), $rt->op_mod( $spaces, 2 ) ) );
  my $post   = $self->_lib->repeat( ' ', $rt->op_div( $spaces, 2 ) );
  return $rt->copy_safeness( $str, $rt->op_add( $rt->op_add( $pre, $str ), $post ) );
}

#### default_

sub default_ {
  my ( $self, $val, $def, $bool ) = @_;
  my $rt = $self->_runtime;
  if ( $rt->_truthy($bool) ) {
    return $rt->op_or( $val, $def );
  } else {
    return defined($val) ? $val : $def;    # val !== undefined: null passes through
  }
}

#### dictsort

sub dictsort {
  my ( $self, $val, $case_sensitive, $by ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  if ( !$lib->is_object($val) ) {
    die $self->_template_error_class->new('dictsort filter: val must be an object');
  }

  my $array = [];
  # deliberately include properties from the object's prototype -- a raw
  # for-in, Lib's js_for_in_keys; val[k] is the JS property read (ADR 0016),
  # where a SafeString's val reads undefined (k72)
  for my $k ( @{ $lib->js_for_in_keys($val) } ) {
    push @$array, [ $k, $rt->member_lookup( $val, $k ) ];
  }

  my $si;
  if ( !defined($by) || $rt->op_seq( $by, 'key' ) ) {
    $si = 0;
  } elsif ( $rt->op_seq( $by, 'value' ) ) {
    $si = 1;
  } else {
    die $self->_template_error_class->new('dictsort filter: You can only sort by either key or value');
  }

  # array.sort: V8's TimSort, the one Lib seam (ADR 0017)
  $lib->js_array_sort(
    $array,
    sub {
      my ( $t1, $t2 ) = @_;
      my $a = $t1->[$si];
      my $b = $t2->[$si];

      if ( $rt->_falsy($case_sensitive) ) {
        if ( $lib->is_string($a) ) {
          $a = $lib->js_to_upper_case($a);
        }
        if ( $lib->is_string($b) ) {
          $b = $lib->js_to_upper_case($b);
        }
      }

      return $rt->op_gt( $a, $b ) ? 1 : ( $rt->op_seq( $a, $b ) ? 0 : -1 );
    }
  );

  return $array;
}

#### dump

# JSON.stringify(obj, null, spaces): Lib's js_json_stringify, which returns
# undef -- JS undefined, rendered '' -- where JSON.stringify does.
sub dump {
  my ( $self, $obj, $spaces ) = @_;
  return $self->_lib->js_json_stringify( $obj, $spaces );
}

#### escape

# str.toString() is the value's JS ToString (Runtime _js_to_string): an array's
# join, '[object Object]', a regex's /source/flags. An own toString member and a
# null-prototype object are k44.
sub escape {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  if ( $rt->_is_safe_string($str) ) {
    return $str;
  }
  $str = ( !defined($str) || $rt->_is_none($str) ) ? '' : $str;
  return $rt->mark_safe( $self->_lib->escape( $rt->_js_to_string($str) ) );
}

#### safe

sub safe {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  if ( $rt->_is_safe_string($str) ) {
    return $str;
  }
  $str = ( !defined($str) || $rt->_is_none($str) ) ? '' : $str;
  return $rt->mark_safe( $rt->_js_to_string($str) );
}

#### first

sub first {
  my ( $self, $arr ) = @_;
  return $self->_runtime->js_member_read( $arr, 0 );
}

#### forceescape

sub forceescape {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  $str = ( !defined($str) || $rt->_is_none($str) ) ? '' : $str;
  return $rt->mark_safe( $self->_lib->escape( $rt->_js_to_string($str) ) );
}

#### groupby

# this.env.opts.throwOnUndefined: $env comes first, from exports' closure.
sub groupby {
  my ( $self, $env, $arr, $attr ) = @_;
  return $self->_lib->group_by( $arr, $attr, $env->opts->{throwOnUndefined} );
}

#### indent

sub indent {
  my ( $self, $str, $width, $indentfirst ) = @_;
  my $rt = $self->_runtime;
  $str = $self->normalize( $str, '' );

  if ( $rt->op_seq( $str, '' ) ) {
    return '';
  }

  $width = $rt->op_or( $width, 4 );
  # let res = '';
  my $lines = $rt->js_method_call( $str, 'str', 'split', "\n" );
  # lib.repeat counts `i < width`, a numeric compare: ToNumber here, as Lib's
  # repeat takes a number (oracle: indent('3') is 3 spaces, indent('2x') none)
  my $sp = $self->_lib->repeat( ' ', $rt->_to_number($width) );

  my $res = $rt->_array_join(
    $self->_lib->map(
      $lines,
      sub {
        my ( $l, $i ) = @_;
        return ( $i == 0 && $rt->_falsy($indentfirst) ) ? $l : $rt->op_concat( $sp, $l );    # `${sp}${l}`
      }
    ),
    "\n"
  );

  return $rt->copy_safeness( $str, $res );
}

#### join

sub join {
  my ( $self, $arr, $del, $attr ) = @_;
  my $rt = $self->_runtime;
  $del = $rt->op_or( $del, '' );

  if ( $rt->_truthy($attr) ) {
    # v[attr]: one property read, so 'a.b' is the key 'a.b', not a path
    $arr = $self->_lib->map( $arr, sub { $rt->js_member_read( $_[0], $attr ) } );
  }

  return $rt->js_method_call( $arr, 'arr', 'join', $del );
}

#### last

sub last {
  my ( $self, $arr ) = @_;
  my $rt = $self->_runtime;
  return $rt->js_member_read( $arr, $rt->op_sub( $rt->js_member_read( $arr, 'length' ), 1 ) );
}

#### lengthFilter

sub length_filter {
  my ( $self, $val ) = @_;
  my $rt    = $self->_runtime;
  my $value = $self->normalize( $val, '' );

  if ( defined $value ) {
    # ECMAScript 2015 Maps and Sets (value.size) have no Perl form (k44)
    if ( $self->_lib->is_object($value) && !$rt->_is_safe_string($value) ) {
      # Objects (besides SafeStrings), non-primative Arrays
      return scalar @{ $self->_lib->keys($value) };
    }
    return $rt->js_member_read( $value, 'length' );
  }
  return 0;
}

#### list

sub list {
  my ( $self, $val ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  if ( $lib->is_string($val) ) {
    return $rt->js_method_call( $val, 'val', 'split', '' );
  } elsif ( $lib->is_object($val) ) {
    # the entries array's own .map; ({key, value}) is an engine-built object,
    # insertion-ordered (ADR 0011)
    return [ map { $rt->make_dict( key => $_->[0], value => $_->[1] ) } @{ $lib->_entries( $rt->op_or( $val, {} ) ) } ];
  } elsif ( $lib->is_array($val) ) {
    return $val;
  } else {
    die $self->_template_error_class->new('list filter: type not iterable');
  }
}

#### lower

sub lower {
  my ( $self, $str ) = @_;
  $str = $self->normalize( $str, '' );
  return $self->_runtime->js_method_call( $str, 'str', 'toLowerCase' );
}

#### nl2br

sub nl2br {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  if ( !defined($str) || $rt->_is_none($str) ) {
    return '';
  }
  return $rt->copy_safeness( $str, $rt->js_string_this( $str, 'str', 'replace' ) =~ s/\r\n|\n/<br \/>\n/gr );
}

#### random

sub random {
  my ( $self, $arr ) = @_;
  my $rt = $self->_runtime;
  # Math.random() is Perl's rand, [0, 1) like it but a different PRNG from
  # V8's, so the pick is never byte-comparable with upstream's; upstream's own
  # test asserts membership only. Listed for the divergence ledger (k24).
  return $rt->js_member_read( $arr,
    $self->_lib->js_math_floor( $rt->op_mul( rand(), $rt->js_member_read( $arr, 'length' ) ) ) );
}

#### getSelectOrReject

# Construct select or reject filter. The filter reads this.env.getTest, so it
# takes the Environment first, from exports' closure; the test is called with
# (item, secondArg) and no this (ADR 0009), and its result must be
# === expectedTestResult (oracle: select('truthy') keeps 1 and 'a' of
# [1, 0, 'a', '']).
sub get_select_or_reject {
  my ( $self, $expected_test_result ) = @_;
  my $filter = sub {
    my ( $env, $arr, $test_name, $second_arg ) = @_;
    my $rt = $self->_runtime;
    $test_name = 'truthy' unless defined $test_name;    # testName = 'truthy': undefined only
    my $test = $env->get_test($test_name);

    return $rt->js_method_call(
      $self->_lib->to_array($arr),
      'lib.toArray(...)',
      'filter',
      sub {
        my ($item) = @_;
        return $rt->op_seq( $test->( $item, $second_arg ), $expected_test_result );
      }
    );
  };

  return $filter;
}

#### rejectattr

# arr.filter and item[attr] are the JS member call and read (ADR 0008 / 0016):
# a value without filter -- a string, an object -- is "TypeError: arr.filter
# is not a function", an undefined item "Cannot read properties of undefined
# (reading 'a')" (oracle).
sub rejectattr {
  my ( $self, $arr, $attr ) = @_;
  my $rt = $self->_runtime;
  return $rt->js_method_call( $arr, 'arr', 'filter', sub { $rt->op_not( $rt->js_member_read( $_[0], $attr ) ) } );
}

#### selectattr

sub selectattr {
  my ( $self, $arr, $attr ) = @_;
  my $rt = $self->_runtime;
  return $rt->js_method_call( $arr, 'arr', 'filter',
    sub { $rt->op_not( $rt->op_not( $rt->js_member_read( $_[0], $attr ) ) ) } );
}

#### replace

sub replace {
  my ( $self, $str, $old, $new_, $max_count ) = @_;
  my $rt           = $self->_runtime;
  my $original_str = $str;

  if ( $rt->_is_regex($old) ) {
    # str.replace(old, new_): RegExp.prototype[Symbol.replace] (ADR 0013)
    return $old->symbol_replace( $rt->js_string_this( $str, 'str', 'replace' ), $new_ );
  }

  if ( !defined($max_count) ) {    # typeof maxCount === 'undefined'
    $max_count = -1;
  }

  my $res = '';    # Output

  # Cast Numbers in the search term to string
  if ( $rt->_js_type($old) eq 'number' ) {
    $old = $rt->op_add( '', $old );
  } elsif ( $rt->_js_type($old) ne 'string' ) {
    # If it is something other than number or string,
    # return the original string
    return $str;
  }

  # Cast numbers in the replacement to string
  if ( $rt->_js_type($str) eq 'number' ) {
    $str = $rt->op_add( '', $str );
  }

  # If by now, we don't have a string, throw it back
  if ( $rt->_js_type($str) ne 'string' && !$rt->_is_safe_string($str) ) {
    return $str;
  }

  # ShortCircuits
  if ( $old eq '' ) {
    # Mimic the python behaviour: empty string is replaced
    # by replacement e.g. "abc"|replace("", ".") -> .a.b.c.
    $res = $rt->op_add(
      $rt->op_add( $new_, $rt->js_method_call( $rt->js_method_call( $str, 'str', 'split', '' ), 'str.split(...)', 'join', $new_ ) ),
      $new_ );
    return $rt->copy_safeness( $str, $res );
  }

  my $next_index = $rt->js_method_call( $str, 'str', 'indexOf', $old );
  # if # of replacements to perform is 0, or the string to does
  # not contain the old value, return the string
  if ( $rt->op_seq( $max_count, 0 ) || $rt->op_seq( $next_index, -1 ) ) {
    return $str;
  }

  my $pos   = 0;
  my $count = 0;    # # of replacements made

  while ( $next_index > -1 && ( $rt->op_seq( $max_count, -1 ) || $rt->op_lt( $count, $max_count ) ) ) {
    # Grab the next chunk of src string and add it with the
    # replacement, to the result (res is a string: `res +=` appends in place)
    $self->_lib->js_string_append( $res,
      $rt->op_add( $rt->js_method_call( $str, 'str', 'substring', $pos, $next_index ), $new_ ) );
    # Increment our pointer in the src string
    $pos = $next_index + $rt->member_lookup( $old, 'length' );
    $count++;
    # See if there are any more replacements to be made
    $next_index = $rt->js_method_call( $str, 'str', 'indexOf', $old, $pos );
  }

  # We've either reached the end, or done the max # of
  # replacements, tack on any remaining string
  if ( $pos < $rt->member_lookup( $str, 'length' ) ) {
    $self->_lib->js_string_append( $res, $rt->js_method_call( $str, 'str', 'substring', $pos ) );
  }

  return $rt->copy_safeness( $original_str, $res );
}

#### reverse

sub reverse {
  my ( $self, $val ) = @_;
  my $rt = $self->_runtime;
  my $arr;
  if ( $self->_lib->is_string($val) ) {
    $arr = $self->list($val);
  } else {
    # Copy it
    $arr = $self->_lib->map( $val, sub { $_[0] } );
  }

  $rt->js_method_call( $arr, 'arr', 'reverse' );

  if ( $self->_lib->is_string($val) ) {
    return $rt->copy_safeness( $val, $rt->js_method_call( $arr, 'arr', 'join', '' ) );
  }
  return $arr;
}

#### round

sub round {
  my ( $self, $val, $precision, $method ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  $precision = $rt->op_or( $precision, 0 );
  my $factor = $lib->js_math_pow( 10, $rt->_to_number($precision) );
  my $rounder;

  if ( $rt->op_seq( $method, 'ceil' ) ) {
    $rounder = sub { $lib->js_math_ceil( $_[0] ) };
  } elsif ( $rt->op_seq( $method, 'floor' ) ) {
    $rounder = sub { $lib->js_math_floor( $_[0] ) };
  } else {
    $rounder = sub { $lib->js_math_round( $_[0] ) };
  }

  # rounder's ToNumber is a no-op on the product, already a Number
  return $rt->op_div( $rounder->( $rt->op_mul( $val, $factor ) ), $factor );
}

#### slice

sub slice {
  my ( $self, $arr, $slices, $fill_with ) = @_;
  my $rt           = $self->_runtime;
  my $slice_length = $self->_lib->js_math_floor( $rt->op_div( $rt->js_member_read( $arr, 'length' ), $slices ) );
  my $extra        = $rt->op_mod( $rt->js_member_read( $arr, 'length' ), $slices );
  my $res          = [];
  my $offset       = 0;

  for ( my $i = 0; $rt->op_lt( $i, $slices ); $i++ ) {
    my $start = $rt->op_add( $offset, $rt->op_mul( $i, $slice_length ) );
    if ( $rt->op_lt( $i, $extra ) ) {
      $offset++;
    }
    my $end = $rt->op_add( $offset, $rt->op_mul( $i + 1, $slice_length ) );

    # Array or String slice by the receiver's kind; push on a string slice
    # throws (oracle: 'abcdef'|slice(3, 'x') -> currSlice.push is not a function)
    my $curr_slice = $rt->js_method_call( $arr, 'arr', 'slice', $start, $end );
    if ( $rt->_truthy($fill_with) && $rt->op_ge( $i, $extra ) ) {
      $rt->js_method_call( $curr_slice, 'currSlice', 'push', $fill_with );
    }
    push @$res, $curr_slice;
  }

  return $res;
}

#### sum

sub sum {
  my ( $self, $arr, $attr, $start ) = @_;
  my $rt = $self->_runtime;
  $start = 0 unless defined $start;    # start = 0, a default parameter: undefined only

  if ( $rt->_truthy($attr) ) {
    # v[attr]: one property read, as in join
    $arr = $self->_lib->map( $arr, sub { $rt->js_member_read( $_[0], $attr ) } );
  }

  return $rt->op_add( $start, $rt->js_method_call( $arr, 'arr', 'reduce', sub { $rt->op_add( $_[0], $_[1] ) }, 0 ) );
}

#### sort

# The function upstream hands to r.makeMacro(['value', 'reverse',
# 'case_sensitive', 'attribute'], [], sortFilter); exports builds the macro
# around it. Its comparator reads this.env.opts.throwOnUndefined -- makeMacro
# passes `this` through --, so $env comes first, from exports' closure.
sub sort_filter {
  my ( $self, $env, $arr, $reversed, $case_sens, $attr ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  # Copy it
  my $array         = $lib->map( $arr, sub { $_[0] } );
  my $get_attribute = $lib->get_attr_getter($attr);

  # array.sort: V8's TimSort, the one Lib seam (ADR 0017)
  $lib->js_array_sort(
    $array,
    sub {
      my ( $a, $b ) = @_;
      my $x = ( $rt->_truthy($attr) ) ? $get_attribute->($a) : $a;
      my $y = ( $rt->_truthy($attr) ) ? $get_attribute->($b) : $b;

      if ( $rt->_truthy( $env->opts->{throwOnUndefined} )
        && $rt->_truthy($attr)
        && ( !defined($x) || !defined($y) ) )
      {
        # `${attr}`: attr's JS ToString
        die $self->_error_class->new( 'sort: attribute "' . $rt->_js_to_string($attr) . '" resolved to undefined',
          name => 'TypeError' );
      }

      if ( $rt->_falsy($case_sens) && $lib->is_string($x) && $lib->is_string($y) ) {
        $x = $lib->js_to_lower_case($x);
        $y = $lib->js_to_lower_case($y);
      }

      if ( $rt->op_lt( $x, $y ) ) {
        return $rt->_truthy($reversed) ? 1 : -1;
      } elsif ( $rt->op_gt( $x, $y ) ) {
        return $rt->_truthy($reversed) ? -1 : 1;
      } else {
        return 0;
      }
    }
  );

  return $array;
}

#### string

sub string {
  my ( $self, $obj ) = @_;
  return $self->_runtime->copy_safeness( $obj, $obj );
}

#### striptags

sub striptags {
  my ( $self, $input, $preserve_linebreaks ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  $input = $self->normalize( $input, '' );
  # /<\/?([a-z][a-z0-9]*)\b[^>]*>|<!--[\s\S]*?-->/gi -- without the u flag, i
  # folds no non-ASCII letter onto a-z (oracle: K U+212A and s-long U+017F are
  # not tag letters), and \b is the ASCII word boundary of js_word_class
  my $w    = $lib->js_word_class;
  my $tags = qr/<\/?([A-Za-z][A-Za-z0-9]*)(?:(?<=$w)(?!$w)|(?<!$w)(?=$w))[^>]*>|<!--(?s:.)*?-->/;
  # cutting a tag out can bring a lone high and a lone low surrogate together:
  # re-pair them (ADR 0012)
  my $trimmed_input =
    $self->trim( $lib->_js_from_units( $rt->js_string_this( $input, 'input', 'replace' ) =~ s/$tags//gr ) );
  my $res = '';
  if ( $rt->_truthy($preserve_linebreaks) ) {
    # /^ +| +$/gm: under m, ^ and $ also match next to any JS LineTerminator
    # (\n \r U+2028 U+2029), not only \n as Perl's /m does
    $res = $trimmed_input
      =~ s/(?<![^\n\r\x{2028}\x{2029}]) +| +(?![^\n\r\x{2028}\x{2029}])//gr    # remove leading and trailing spaces
      =~ s/ +/ /gr                                                          # squash adjacent spaces
      =~ s/(\r\n)/\n/gr                                                     # normalize linebreaks (CRLF -> LF)
      =~ s/\n\n\n+/\n\n/gr;                                                 # squash abnormal adjacent linebreaks
  } else {
    my $ws = $lib->js_whitespace_class;
    $res = $trimmed_input =~ s/(?:$ws)+/ /gr;
  }
  return $rt->copy_safeness( $input, $res );
}

#### title

sub title {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  $str = $self->normalize( $str, '' );
  my $words = $self->_lib->map( $rt->js_method_call( $str, 'str', 'split', ' ' ), sub { $self->capitalize( $_[0] ) } );
  return $rt->copy_safeness( $str, $rt->_array_join( $words, ' ' ) );
}

#### trim

sub trim {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  my $ws = $self->_lib->js_whitespace_class;    # /^\s*|\s*$/g
  return $rt->copy_safeness( $str, $rt->js_string_this( $str, 'str', 'replace' ) =~ s/\A(?:$ws)*|(?:$ws)*\z//gr );
}

#### truncate

sub truncate {
  my ( $self, $input, $length, $killwords, $end ) = @_;
  my $rt   = $self->_runtime;
  my $orig = $input;
  $input  = $self->normalize( $input, '' );
  $length = $rt->op_or( $length, 255 );

  if ( $rt->op_le( $rt->member_lookup( $input, 'length' ), $length ) ) {
    return $input;
  }

  if ( $rt->_truthy($killwords) ) {
    $input = $rt->js_method_call( $input, 'input', 'substring', 0, $length );
  } else {
    my $idx = $rt->js_method_call( $input, 'input', 'lastIndexOf', ' ', $length );
    if ( $rt->op_seq( $idx, -1 ) ) {
      $idx = $length;
    }

    $input = $rt->js_method_call( $input, 'input', 'substring', 0, $idx );
  }

  $input = $rt->op_add( $input, ( defined($end) && !$rt->_is_none($end) ) ? $end : '...' );
  return $rt->copy_safeness( $orig, $input );
}

#### upper

sub upper {
  my ( $self, $str ) = @_;
  $str = $self->normalize( $str, '' );
  return $self->_runtime->js_method_call( $str, 'str', 'toUpperCase' );
}

#### urlencode

sub urlencode {
  my ( $self, $obj ) = @_;
  my $rt  = $self->_runtime;
  my $lib = $self->_lib;
  # encodeURIComponent: ToString, then the UTF-16 seam (ADR 0012)
  my $enc = sub { $lib->js_encode_uri_component( $rt->_js_to_string( $_[0] ) ) };
  if ( $lib->is_string($obj) ) {
    return $enc->($obj);
  } else {
    my $keyvals = ( $lib->is_array($obj) ) ? $obj : $lib->_entries($obj);
    # ([k, v]) destructures each entry through the iteration protocol; the
    # template literal glues percent-encoded ASCII, where no pair can form
    return $rt->_array_join(
      [ map { my ( $k, $v ) = $rt->js_array_destructure( $_, 2 ); $enc->($k) . '=' . $enc->($v) } @$keyvals ],
      '&' );
  }
}

#### urlize

my $INFINITY = 9**9**9;

# For the jinja regexp, see
# https://github.com/mitsuhiko/jinja2/blob/f15b814dcba6aa12bc74d1f7d0c881d55f7126be/jinja2/utils.py#L20-L23
# JS `.` stops at a LineTerminator (\n \r U+2028 U+2029), and `$` without the m
# flag is the end of input only: \z, where Perl's $ also matches before a final
# newline
my $PUNC_RE = qr/\A(?:\(|<|&lt;)?([^\n\r\x{2028}\x{2029}]*?)(?:\.|,|\)|\n|&gt;)?\z/;
# from http://blog.gerv.net/2011/05/html5_email_address_regexp/
# /i without the u flag folds no character above U+007F onto ASCII (oracle: the
# Kelvin sign U+212A and long s U+017F match no [a-z]), so [a-z] is [A-Za-z];
# \w and \d are the ECMAScript sets (ADR 0005), which /i leaves alone
my $EMAIL_RE = do {
  my $w = Text::Nunjucks::Lib->js_word_class;
  my $d = Text::Nunjucks::Lib->js_digit_class;
  qr/\A(?:$w|[.!#\$%&'*+\-\/=?\^`{|}~])+\@(?:[A-Za-z\-]|$d)+(\.(?:[A-Za-z\-]|$d)+)+\z/;
};
my $HTTP_HTTPS_RE = qr/\Ahttps?:\/\/[^\n\r\x{2028}\x{2029}]*\z/;
my $WWW_RE        = qr/\Awww\./;
my $TLD_RE        = qr/\.(?:org|net|com)(?::|\/|\z)/;

sub urlize {
  my ( $self, $str, $length, $nofollow ) = @_;
  my $rt = $self->_runtime;
  my $ws = $self->_lib->js_whitespace_class;
  if ( $self->is_nan($length) ) {
    $length = $INFINITY;
  }

  my $no_follow_attr = ( $rt->op_seq( $nofollow, true ) ? ' rel="nofollow"' : '' );

  # str.split(/(\s+)/): the captured separators stay in the array; no
  # whitespace run starts or ends inside a surrogate pair, so the pieces need no
  # re-pairing
  my $words = [ split /((?:$ws)+)/, $rt->js_string_this( $str, 'str', 'split' ), -1 ];
  $words = [
    grep {
      # If the word has no length, bail. This can happen for str with
      # trailing whitespace.
      $rt->_truthy( $rt->op_and( $_, $rt->member_lookup( $_, 'length' ) ) );
    } @$words
  ];
  my $urlize_word = sub {
    my ($word) = @_;
    my $possible_url = ( $word =~ $PUNC_RE ) ? $1 : $word;    # word.match(puncRe)
    my $short_url    = $rt->js_method_call( $possible_url, 'possibleUrl', 'substr', 0, $length );

    # the template literals glue ASCII onto each piece, so no pair can form

    # url that starts with http or https
    if ( $possible_url =~ $HTTP_HTTPS_RE ) {
      return '<a href="' . $possible_url . '"' . $no_follow_attr . '>' . $short_url . '</a>';
    }

    # url that starts with www.
    if ( $possible_url =~ $WWW_RE ) {
      return '<a href="http://' . $possible_url . '"' . $no_follow_attr . '>' . $short_url . '</a>';
    }

    # an email address of the form username@domain.tld
    if ( $possible_url =~ $EMAIL_RE ) {
      return '<a href="mailto:' . $possible_url . '">' . $possible_url . '</a>';
    }

    # url that ends in .com, .org or .net that is not an email address
    if ( $possible_url =~ $TLD_RE ) {
      return '<a href="http://' . $possible_url . '"' . $no_follow_attr . '>' . $short_url . '</a>';
    }

    return $word;
  };
  $words = [ map { $urlize_word->($_) } @$words ];

  return $rt->_array_join( $words, '' );
}

#### wordcount

sub wordcount {
  my ( $self, $str ) = @_;
  my $rt = $self->_runtime;
  my $w  = $self->_lib->js_word_class;
  $str = $self->normalize( $str, '' );
  my $words = $rt->None;
  if ( $rt->_truthy($str) ) {
    # str.match(/\w+/g): every match, or null when there is none
    my @matches = $rt->js_string_this( $str, 'str', 'match' ) =~ /(?:$w)+/g;
    $words = @matches ? \@matches : $rt->None;
  }
  return $rt->_truthy($words) ? scalar(@$words) : $rt->None;
}

#### float

sub float {
  my ( $self, $val, $def ) = @_;
  # parseFloat(val): ToString first
  my $res = $self->_lib->js_parse_float( $self->_runtime->_js_to_string($val) );
  return ( $self->is_nan($res) ) ? $def : $res;
}

#### intFilter

# The function upstream hands to r.makeMacro(['value', 'default', 'base'], [],
# doInt); exports builds the macro around it, so keyword arguments reach it by
# name (value=, default=, base=).
sub do_int {
  my ( $self, $value, $default_value, $base ) = @_;
  my $rt = $self->_runtime;
  $base = 10 unless defined $base;    # base = 10, a default parameter: undefined only
  # parseInt(value, base): ToString(value), ToNumber(base) for its ToInt32
  my $res = $self->_lib->js_parse_int( $rt->_js_to_string($value), $rt->_to_number($base) );
  return ( $self->is_nan($res) ) ? $default_value : $res;
}

#### exports -- the bag Environment.init registers, built per Environment

sub exports {
  my ( $self, $env ) = @_;
  # the Environment holds the bag these closures are in (see the header)
  weaken($env);
  my $reject = $self->get_select_or_reject(false);
  my $select = $self->get_select_or_reject(true);
  my $exports = {
    abs         => sub { $self->abs(@_) },
    batch       => sub { $self->batch(@_) },
    capitalize  => sub { $self->capitalize(@_) },
    center      => sub { $self->center(@_) },
    default     => sub { $self->default_(@_) },
    dictsort    => sub { $self->dictsort(@_) },
    dump        => sub { $self->dump(@_) },
    escape      => sub { $self->escape(@_) },
    safe        => sub { $self->safe(@_) },
    first       => sub { $self->first(@_) },
    forceescape => sub { $self->forceescape(@_) },
    groupby     => sub { $self->groupby( $env, @_ ) },
    indent      => sub { $self->indent(@_) },
    join        => sub { $self->join(@_) },
    last        => sub { $self->last(@_) },
    length      => sub { $self->length_filter(@_) },
    list        => sub { $self->list(@_) },
    lower       => sub { $self->lower(@_) },
    nl2br       => sub { $self->nl2br(@_) },
    random      => sub { $self->random(@_) },
    reject      => sub { $reject->( $env, @_ ) },
    rejectattr  => sub { $self->rejectattr(@_) },
    select      => sub { $select->( $env, @_ ) },
    selectattr  => sub { $self->selectattr(@_) },
    replace     => sub { $self->replace(@_) },
    reverse     => sub { $self->reverse(@_) },
    round       => sub { $self->round(@_) },
    slice       => sub { $self->slice(@_) },
    sum         => sub { $self->sum(@_) },
    sort        => $self->_runtime->make_macro(
      [ 'value', 'reverse', 'case_sensitive', 'attribute' ], [], sub { $self->sort_filter( $env, @_ ) }
    ),
    string      => sub { $self->string(@_) },
    striptags   => sub { $self->striptags(@_) },
    title       => sub { $self->title(@_) },
    trim        => sub { $self->trim(@_) },
    truncate    => sub { $self->truncate(@_) },
    upper       => sub { $self->upper(@_) },
    urlencode   => sub { $self->urlencode(@_) },
    urlize      => sub { $self->urlize(@_) },
    wordcount   => sub { $self->wordcount(@_) },
    float       => sub { $self->float(@_) },
    int         => $self->_runtime->make_macro( [ 'value', 'default', 'base' ], [], sub { $self->do_int(@_) } ),
  };

  # Aliases
  $exports->{d} = $exports->{default};
  $exports->{e} = $exports->{escape};

  return $exports;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Filters - 1:1 port of Nunjucks src/filters.js -- the built-in filters

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A 1:1 port of Nunjucks C<src/filters.js>: the built-in filters. C<exports> builds
the name to code reference hash for one Environment, which registers them when
it is constructed. The filters are described in the Nunjucks template
documentation, L<https://mozilla.github.io/nunjucks/templating.html#builtin-filters>.
To add or replace a filter use C<add_filter> of L<Text::Nunjucks::Environment>.

Engine-internal: used by L<Text::Nunjucks::Environment> and the code the compiler emits, and
not an interface for applications.

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
