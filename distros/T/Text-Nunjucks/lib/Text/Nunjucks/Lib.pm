package Text::Nunjucks::Lib;
# ABSTRACT: 1:1 port of Nunjucks src/lib.js -- foundation utilities and escaping

our $VERSION = '0.001';

use strict;
use warnings;
use builtin qw( is_bool created_as_number true false );
use feature qw( current_sub );
use Carp qw( croak );
use Config ();
use Cwd ();
use Errno ();
use Math::BigInt ();
use POSIX ();
use Scalar::Util qw( blessed refaddr );
use Text::Nunjucks::Lib::TemplateError;
use Text::Nunjucks::Lib::Error;
# Circular with Runtime's `use Text::Nunjucks::Lib`. Lib calls up into it for
# the JS semantics Runtime is the one home of -- the property reads and
# ToPropertyKey of hasOwnProp / getAttrGetter / groupBy / toArray / map's
# array-like branch, groupBy's result object (make_dict), ToNumber / ToString /
# the operators in groupBy, toArray, JSON.stringify and the sort comparator --
# from inside their subs, run time. Caveat: when Lib loads first,
# this line compiles and runs all of Runtime before the rest of Lib is even
# compiled -- the Lib subs below this line do not exist yet and its file-scope
# lexicals (%ESCAPE_MAP, $JS_WORD_CLASS, $NUM_POS_INF, ...) are still unset. So
# Runtime must never call a Lib function at file scope (a `my $X = Lib->...`,
# a BEGIN, a `use constant`); calls from inside its subs are fine.
use Text::Nunjucks::Runtime;

no warnings 'experimental::builtin';

# lib.js is a plain bag of exported functions accessed qualified as `lib.foo`.
# Ported as a class-method-only module (getty-perl-core "dispatch through the
# invocant"): every function is a method taking $self, callers use
# Text::Nunjucks::Lib->is_array($x), cross-calls go through $self. No instances.
# ADR 0001 designates this module the single home for value-kind checks.

# The collaborator class, named once (getty-perl-core resolver), for map's
# array-like branch and groupBy's engine-built result.
sub _runtime { 'Text::Nunjucks::Runtime' }

#### module constants (var escapeMap / escapeRegex)

my %ESCAPE_MAP = (
  '&'  => '&amp;',
  '"'  => '&quot;',
  "'"  => '&#39;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '\\' => '&#92;',
);

my $ESCAPE_REGEX = qr/[&"'<>\\]/;

#### hasOwnProp

# ObjProto.hasOwnProperty.call(obj, k): ToPropertyKey(k) first (Runtime's, the
# key obj[k] reads), then ToObject(obj), which throws on undefined and null
# (oracle: [u]|groupby('a') and [{'a': null}]|groupby('a.b') -> "TypeError:
# Cannot convert undefined or null to object"). The own properties per value
# kind, oracle-measured through groupby(attr): an object -- caller hash or
# ordered dict -- its keys; an array its indices and length; a primitive
# string, a String object after ToObject, its code-unit indices and length
# (ADR 0012; '01' is no index); a SafeString this.val and this.length; a regex
# its lastIndex (source and flags are inherited accessors). A number and a
# boolean own nothing. A function owns length and name in JS (a macro: 0 and
# 'macro'), which a Perl coderef has no form of, so it owns nothing here; nor
# does any other blessed object (k47).
sub has_own_prop {
  my ( $self, $obj, $k ) = @_;
  my $rt  = $self->_runtime;
  my $key = $rt->_member_key($k);
  die Text::Nunjucks::Lib::Error->new( 'Cannot convert undefined or null to object', name => 'TypeError' )
    if !defined($obj) || $rt->_is_none($obj);

  my $r = ref $obj;
  return exists $obj->{$key} ? 1 : 0 if $r eq 'HASH';
  return $obj->exists($key)  ? 1 : 0 if $rt->_is_ordered_hash($obj);
  if ( $r eq 'ARRAY' ) {
    return 1 if $key eq 'length';
    return ( $self->_is_array_index($key) && $key < scalar @$obj ) ? 1 : 0;
  }
  if ( $self->is_string($obj) ) {
    return 1 if $key eq 'length';
    return ( $self->_is_array_index($key) && $key < $self->js_string_length($obj) ) ? 1 : 0;
  }
  return ( $key eq 'val' || $key eq 'length' ) ? 1 : 0 if $rt->_is_safe_string($obj);
  return $key eq 'lastIndex' ? 1 : 0 if $rt->_is_regex($obj);
  return 0;
}

#### lookupEscape

sub lookup_escape {
  my ( $self, $ch ) = @_;
  return $ESCAPE_MAP{$ch};
}

#### _prettifyError

sub _prettify_error {
  my ( $self, $path, $with_internals, $err ) = @_;

  if ( !( blessed($err) && $err->can('update') ) ) {
    # not one of ours, cast it
    $err = Text::Nunjucks::Lib::TemplateError->new($err);
  }
  $err->update($path);

  # Unless they marked the dev flag, show them a trace from here. In JS this
  # rebuilds a plain Error to scrub internal stack frames; Perl has no such
  # stack in the message, but reproducing "an object without update()" matters:
  # a re-prettified error must be re-wrapped, not updated again.
  if ( !$with_internals ) {
    my $old = $err;
    $err = Text::Nunjucks::Lib::Error->new( $old->message, name => $old->name );
  }

  return $err;
}

#### TemplateError -- Text::Nunjucks::Lib::TemplateError (own file)

#### escape

sub escape {
  my ( $self, $val ) = @_;
  return $val =~ s/($ESCAPE_REGEX)/$self->lookup_escape($1)/ger;
}

#### isFunction

sub is_function {
  my ( $self, $obj ) = @_;
  # plain coderef only; blessed / overloaded callables are k8 (callables) territory
  return ref($obj) eq 'CODE' ? 1 : 0;
}

#### isArray

sub is_array {
  my ( $self, $obj ) = @_;
  return ref($obj) eq 'ARRAY' ? 1 : 0;
}

#### isString

sub is_string {
  my ( $self, $obj ) = @_;
  # ADR 0001: a string is a defined non-ref scalar that is neither a boolean
  # nor created-as-number. A numeric *string* ('5') is a string; 5 is not.
  return ( defined($obj) && !ref($obj) && !is_bool($obj) && !created_as_number($obj) )
    ? 1 : 0;
}

#### isObject

sub is_object {
  my ( $self, $obj ) = @_;
  # Object.prototype.toString.call(obj) === '[object Object]': a plain hashref,
  # an ordered dict (template literal / engine-built object, ADR 0011) and a
  # SafeString -- a String subclass whose instances are ordinary objects
  # (oracle: '{% macro m() %}ab{% endmacro %}' m()|list gives val=ab;length=2;).
  # Other blessed objects are k6/Runtime member-access territory.
  return 1 if ref($obj) eq 'HASH';
  return ( blessed($obj) && ( $obj->isa('Hash::Ordered') || $obj->isa('Text::Nunjucks::Runtime::SafeString') ) )
    ? 1 : 0;
}

#### _prepareAttributeParts

sub _prepare_attribute_parts {
  my ( $self, $attr ) = @_;

  # JS: if (!attr) return [];  -- JS falsiness, NOT Perl's: Runtime's, which
  # knows null (oracle: groupby(null) groups by the item itself)
  return [] if $self->_runtime->_falsy($attr);

  # JS: if (typeof attr === 'string') return attr.split('.');  (-1 keeps trailing empties)
  return [ split /\./, $attr, -1 ] if $self->is_string($attr);

  return [$attr];
}

#### getAttrGetter

sub get_attr_getter {
  my ( $self, $attribute ) = @_;
  my $parts = $self->_prepare_attribute_parts($attribute);

  return sub {
    my ($item) = @_;
    my $_item = $item;

    for my $part (@$parts) {
      # If item is not an object, and we still got parts to handle, roll out to
      # undefined.
      if ( $self->has_own_prop( $_item, $part ) ) {
        # _item[part]: the JS property read, Runtime's (ADR 0016) -- a
        # SafeString's val reads undefined there (k72)
        $_item = $self->_runtime->member_lookup( $_item, $part );
      } else {
        return undef;
      }
    }

    return $_item;
  };
}

#### groupBy

sub group_by {
  my ( $self, $obj, $val, $throw_on_undefined ) = @_;
  my $rt = $self->_runtime;
  # const result = {} -- an engine-built object, so an ordered dict from
  # Runtime's make_dict (ADR 0011): groups iterate in JS key order
  my $result   = $rt->make_dict;
  my $iterator = $self->is_function($val) ? $val : $self->get_attr_getter($val);

  # i < obj.length and obj[i] are JS property reads and a JS comparison,
  # Runtime's (oracle: undefined|groupby('a') -> "TypeError: Cannot read
  # properties of undefined (reading 'length')", a number or an object without
  # length groups nothing, a SafeString's obj[i] is undefined). A primitive
  # string cannot change under the loop: its split('') units are the same
  # length and obj[i] (ADR 0012), measured once.
  my $array_like = $rt->_for_code_units($obj);
  for ( my $i = 0; $rt->op_lt( $i, $rt->js_member_read( $array_like, 'length' ) ); $i++ ) {
    my $value = $rt->js_member_read( $array_like, $i );
    my $key   = $iterator->( $value, $i );

    # JS: if (key === undefined && throwOnUndefined === true)
    if ( !defined($key)
      && defined($throw_on_undefined)
      && is_bool($throw_on_undefined)
      && $throw_on_undefined )
    {
      # `${val}` is val's JS ToString (oracle: groupby(['a', 'b']) names
      # "a,b", groupby({'a': 1}) "[object Object]", groupby(0.1 + 0.2)
      # "0.30000000000000004")
      die Text::Nunjucks::Lib::Error->new(
        'groupby: attribute "' . $rt->_js_to_string($val) . '" resolved to undefined',
        name => 'TypeError'
      );
    }

    # result[key] reads the key's ToPropertyKey: undefined -> 'undefined', true
    # -> 'true', null -> 'null', a number its JS ToString (ADR 0007: 0.3 and
    # 0.30000000000000004 stay apart, -0 is '0'), an array its join, a
    # SafeString its value (oracle). A key naming an Object.prototype member
    # groups here where JS throws -- k81.
    my $hkey = $rt->_member_key($key);
    # (result[key] || (result[key] = [])).push(value)
    push @{ $result->get($hkey) // $result->set( $hkey, [] ) }, $value;
  }

  return $result;
}

#### toArray

# Array.prototype.slice.call(obj): ToObject(obj), a TypeError on undefined and
# null; len = ToLength(obj.length); then every index below len obj has, in
# order -- Runtime's property reads (oracle, through select: {'length': '2',
# '0': 1, '1': 2} -> 1,2, {'length': 1.7, ...} -> 1, {'length': -1} ->
# nothing, a length above 2^32 - 1 -> "RangeError: Invalid array length"). An
# array is copied, a primitive string gives its UTF-16 code units, the same
# list as split('') (ADR 0012). A SafeString has a length but no indices; a
# number, boolean, function or regex has no length, ToLength(undefined) is 0.
# An index obj lacks is a hole in JS's result: the value model has none (ADR
# 0001), so it is left out -- which the one caller, select / reject's filter,
# cannot tell apart, as filter skips holes.
sub to_array {
  my ( $self, $obj ) = @_;
  my $rt = $self->_runtime;
  die Text::Nunjucks::Lib::Error->new( 'Cannot convert undefined or null to object', name => 'TypeError' )
    if !defined($obj) || $rt->_is_none($obj);
  return [ @$obj ] if ref($obj) eq 'ARRAY';
  return $self->js_split( $obj, '' ) if $self->is_string($obj);

  my $len = $self->_js_to_integer_or_infinity( $rt->_to_number( $rt->member_lookup( $obj, 'length' ) ) );
  $len = 0 if $len < 0;
  # ArraySpeciesCreate(O, count) -> ArrayCreate, which caps an array's length
  die Text::Nunjucks::Lib::Error->new( 'Invalid array length', name => 'RangeError' ) if $len > 4294967295;

  my $result = [];
  for my $k ( 0 .. $len - 1 ) {
    push @$result, $rt->member_lookup( $obj, $k ) if $self->has_own_prop( $obj, $k );
  }
  return $result;
}

#### without

sub without {
  my ( $self, $array, @contains ) = @_;
  my $result = [];
  return $result unless $array;    # JS !array (array is arrayref|undef here)

  my $length = scalar @$array;
  my $index  = -1;

  while ( ++$index < $length ) {
    if ( $self->index_of( \@contains, $array->[$index] ) == -1 ) {
      push @$result, $array->[$index];
    }
  }
  return $result;
}

#### repeat

sub repeat {
  my ( $self, $char, $n ) = @_;
  my $str = '';
  # JS: for (let i = 0; i < n; i++) -- runs (ceil of) fractional n times, unlike
  # Perl's `1..$n` which truncates. center() feeds fractional counts (spaces/2).
  for ( my $i = 0; $i < $n; $i++ ) {
    $self->js_string_append( $str, $char );    # str += char_ (ADR 0012)
  }
  return $str;
}

#### each

sub each {
  my ( $self, $obj, $func, $context ) = @_;
  return if !defined $obj;    # JS obj == null

  # array / array-like branch; context (`this`) is k8 and not modelled
  if ( ref($obj) eq 'ARRAY' ) {
    for my $i ( 0 .. $#$obj ) {
      $func->( $obj->[$i], $i, $obj );
    }
  }
}

#### map

sub map {
  my ( $self, $obj, $func ) = @_;
  my $results = [];
  # if (obj == null) -- undefined here; null (Runtime's None) after the array
  # branch, which so needs nothing from Runtime
  return $results if !defined $obj;

  # if (ArrayProto.map && obj.map === ArrayProto.map) return obj.map(func);
  # -- a real array; native Array.map passes (element, index, array)
  if ( $self->is_array($obj) ) {
    for my $i ( 0 .. $#$obj ) {
      $results->[$i] = $func->( $obj->[$i], $i, $obj );
    }
    return $results;
  }

  # Anything else is read as an array-like. obj.length and obj[i] are JS
  # property reads and `i < obj.length` a JS comparison: Runtime's
  # member_lookup and op_lt, the one home of both (ADR 0008 / 0007), so this
  # branch calls up into Runtime (as groupBy does for make_dict). Oracle: a
  # SafeString has a length but no index access ('abc' from a macro, |reverse
  # -> ',,'), {length: '2', 0: 'x', 1: 'y'} maps x, y, a number or a plain
  # object without length maps nothing. A primitive string cannot change under
  # the loop, so it is read through its split('') units -- the same length and
  # the same obj[i] (ADR 0012) without measuring the string once per index.
  my $rt = $self->_runtime;
  return $results if $rt->_is_none($obj);
  my $array_like = $self->is_string($obj) ? $self->js_split( $obj, '' ) : $obj;

  for ( my $i = 0; $rt->op_lt( $i, $rt->member_lookup( $array_like, 'length' ) ); $i++ ) {
    $results->[ scalar @$results ] = $func->( $rt->member_lookup( $array_like, $i ), $i );
  }

  # if (obj.length === +obj.length) results.length = obj.length; -- setting an
  # array's length to anything but an integer in [0, 2^32 - 1] is a RangeError
  # (oracle: {length: 2.5}|reverse, {length: -1}|reverse)
  my $length = $rt->member_lookup( $array_like, 'length' );
  if ( $self->_strict_eq( $length, $rt->op_pos($length) ) ) {
    die Text::Nunjucks::Lib::Error->new( 'Invalid array length', name => 'RangeError' )
      if $self->_js_to_uint32($length) != $length;
    $#$results = $length - 1;
  }

  return $results;
}

#### asyncIter

sub async_iter {
  my ( $self, $arr, $iter, $cb ) = @_;
  my $i = -1;

  # Port-only (k107): JS's `function next()` names itself; here the closure
  # hands itself on as __SUB__. Closing over the variable that holds it would
  # be a reference cycle that keeps $iter, $cb and everything they reach (the
  # render's Context, Frame and Template) alive for the life of the process.
  my $next = sub {
    $i++;
    if ( $i < scalar @$arr ) {
      # Port-only (k83): every item nests one call deeper, $iter being entered
      # again before it has returned -- upstream's next() nests one JS call per
      # item the same way (ADR 0003). Perl warns at the 100th nested call of a
      # sub, here where the call is made; the depth is bounded by memory, not
      # by Perl, so that warning is noise and is off for this call alone.
      no warnings 'recursion';
      $iter->( $arr->[$i], $i, __SUB__, $cb );
    } else {
      $cb->();
    }
  };

  $next->();
}

#### asyncFor

sub async_for {
  my ( $self, $obj, $iter, $cb ) = @_;
  # JS: lib.keys(arr || {}) -- JS falsiness, not Perl's `// {}` which only
  # guarded undef and let a 0 / '' / false through to crash keys() on the deref.
  # None (JS null) is a Runtime sentinel that Lib does not know (ADR 0006); the
  # only caller that can pass a null iterable, Runtime::async_each, guards it
  # there before delegating, so _falsy (kind-based, no None) suffices here.
  my $keys = $self->keys( $self->_falsy($obj) ? {} : $obj );
  my $len  = scalar @$keys;
  my $i    = -1;

  # Value lookup mirrors the ordering policy of keys() above (ADR 0011): a
  # Hash::Ordered (template dict literal / engine-built object) reads via ->get;
  # a plain hashref reads via ->{}. asyncFor doesn't reach Runtime->member_lookup
  # (Lib calls up into Runtime only in map and groupBy),
  # so this is the single seam -- the Runtime side mirrors it for its own
  # async_all loop.
  my $lookup = ( blessed($obj) && $obj->isa('Hash::Ordered') )
    ? sub { my $k = shift; $obj->exists($k) ? $obj->get($k) : undef }
    : sub { my $k = shift; $obj->{$k} };

  # __SUB__, not a captured $next: see async_iter (k107).
  my $next = sub {
    $i++;
    my $k = $keys->[$i];
    if ( $i < $len ) {
      # one call deeper per key, as in async_iter (k83)
      no warnings 'recursion';
      $iter->( $k, $lookup->($k), $i, $len, __SUB__ );
    } else {
      $cb->();
    }
  };

  $next->();
}

#### indexOf

sub index_of {
  my ( $self, $arr, $search, $from_index ) = @_;
  # Array.prototype.indexOf.call(arr || [], searchElement, fromIndex) -- uses
  # strict equality (===). See _strict_eq below.
  $arr = [] unless defined $arr;
  my $len = scalar @$arr;

  my $start = defined($from_index) ? int($from_index) : 0;
  if ( $start < 0 ) {
    $start += $len;
    $start = 0 if $start < 0;
  }

  for ( my $i = $start; $i < $len; $i++ ) {
    return $i if $self->_strict_eq( $arr->[$i], $search );
  }
  return -1;
}

#### keys (keys_)

sub keys {
  my ( $self, $obj ) = @_;
  # own enumerable keys. ADR 0011 (amended on k51) sets the ordering policy in
  # one place:
  #
  #   * Hash::Ordered (template dict literal / engine-built object): own keys
  #     in JS order -- _ordinary_own_property_keys over its insertion order,
  #     byte-identical to JS Object.keys.
  #   * Plain caller hash: the array-index keys first, ascending, then the
  #     rest key-sorted -- the documented divergence is only in that rest
  #     (Perl hashes carry no insertion order to preserve; sorted gives a
  #     deterministic cross-PERL_HASH_SEED iteration where JS would have shown
  #     insertion order).
  #
  # _entries / _values / extend / async_for / member_lookup / the dump /
  # dictsort / list / items filters (k17) all reach the iterator here, so this
  # is the only seam the policy needs.
  #
  # Non-hash refs are an open latency: JS keys([10,20]) -> ['0','1'], but a
  # non-HASH ref dies here on the deref. The value model routes arrays through
  # async_iter / to_array, so this is believed unreachable; keys(undef) already
  # yields [] cleanly. Revisit if a k14/k17 call site reaches it.
  #
  # for-in over undefined, null, a number, a boolean or a function enumerates
  # nothing (oracle: 5|urlencode, none|urlencode and a macro|urlencode render
  # '' -- lib._entries(obj) is []). A primitive string's indices are k59.
  return [] if !defined($obj) || ( !ref($obj) && !$self->is_string($obj) );
  return [] if $self->_runtime->_is_none($obj) || $self->is_function($obj);
  return $self->_ordinary_own_property_keys( [ $obj->keys ] ) if blessed($obj) && $obj->isa('Hash::Ordered');

  # A SafeString (engine-built): its own properties in the order its
  # constructor creates them, this.val then this.length.
  return [ 'val', 'length' ] if blessed($obj) && $obj->isa('Text::Nunjucks::Runtime::SafeString');

  # Any other blessed object -- a regex, keyword arguments (k79), a caller's
  # object (k47) -- enumerates nothing: its hash fields are no JS properties
  # (a regex's own lastIndex is not enumerable).
  return [] if blessed($obj);

  # Plain hash: sort CORE::keys (per-process-random Perl order) deterministically.
  my $arr = [];
  for my $k ( sort CORE::keys %$obj ) {
    push @$arr, $k if $self->has_own_prop( $obj, $k );
  }
  return $self->_ordinary_own_property_keys($arr);
}

# Port addition (ADR 0011, k51): the order JS's for-in gives an ordinary
# object's own string keys, ECMAScript OrdinaryOwnPropertyKeys -- every array
# index first, in ascending numeric order, then the other keys in the order
# given (insertion order for an ordered dict, key-sorted for a plain hash).
# oracle: {"a":1,"10":2,"9":3,"01":4,"-1":5,"4294967295":6,"4294967294":7,"1.5":8}
# iterates 9;10;4294967294;a;01;-1;4294967295;1.5;
sub _ordinary_own_property_keys {
  my ( $self, $keys ) = @_;
  my ( @index, @rest );
  for my $k (@$keys) {
    if ( $self->_is_array_index($k) ) { push @index, $k }
    else                               { push @rest,  $k }
  }
  return [ ( sort { $a <=> $b } @index ), @rest ];
}

# An array index is a String P with ToString(ToUint32(P)) === P and
# ToUint32(P) !== 2^32 - 1: the canonical ASCII decimal form of an integer
# 0 .. 4294967294. oracle: '0' and '4294967294' are indices; '4294967295',
# '00', '01', '-0', '-1', '+1', '1.5', '1e3', ' 1', '0x1', '' and non-ASCII
# digits are not. At most ten digits pass the pattern; a ten-digit one is
# compared with 4294967294 as a string.
sub _is_array_index {
  my ( $self, $k ) = @_;
  return 0 unless $k =~ /\A(?:0|[1-9][0-9]{0,9})\z/;
  return ( length($k) < 10 || $k le '4294967294' ) ? 1 : 0;
}

#### js_for_in_keys -- the keys `for (k in obj)` visits

# Port addition: lib.js's for-in loops filter by hasOwnProp, so keys above is
# their whole iteration; a raw for-in (the dictsort filter's, which upstream
# notes deliberately includes properties from the object's prototype) visits
# the enumerable properties up the prototype chain after the own ones, each
# name once. The own ones are keys', the one ordering seam (ADR 0011). Of the
# prototypes the value model reaches, only SafeString.prototype has
# enumerable properties: valueOf and toString, assigned after the
# Object.create that made its length non-enumerable, and never shadowed by a
# SafeString's own val and length -- Object.prototype, Array.prototype and
# String.prototype have none (oracle: 'ab'|safe|dictsort gives length,
# toString, val, valueOf).
sub js_for_in_keys {
  my ( $self, $obj ) = @_;
  my $keys = $self->keys($obj);
  push @$keys, qw( valueOf toString ) if blessed($obj) && $obj->isa('Text::Nunjucks::Runtime::SafeString');
  return $keys;
}

#### _entries

sub _entries {
  my ( $self, $obj ) = @_;
  return [ CORE::map { [ $_, $self->_own_value( $obj, $_ ) ] } @{ $self->keys($obj) } ];
}

#### _values

sub _values {
  my ( $self, $obj ) = @_;
  return [ CORE::map { $self->_own_value( $obj, $_ ) } @{ $self->keys($obj) } ];
}

# obj[k] for a key keys() returned: an ordered dict (a blessed array, ADR 0011)
# reads through ->get, a hash -- a SafeString's included -- by its key.
sub _own_value {
  my ( $self, $obj, $k ) = @_;
  return ( blessed($obj) && $obj->isa('Hash::Ordered') ) ? $obj->get($k) : $obj->{$k};
}

#### extend / _assign

sub extend {
  my ( $self, $obj1, $obj2 ) = @_;
  $obj1 = {} unless $obj1;    # JS obj1 || {} (obj1 is hashref|undef; refs are truthy)
  for my $k ( @{ $self->keys($obj2) } ) {
    $obj1->{$k} = $self->_own_value( $obj2, $k );
  }
  return $obj1;
}

# exports._assign = exports.extend
*_assign = \&extend;

#### inOperator

sub in_operator {
  my ( $self, $key, $val ) = @_;

  # JS: if (isArray(val) || isString(val)) return val.indexOf(key) !== -1;
  # Array.indexOf and String.indexOf differ in Perl, so the one JS branch
  # splits in two.
  if ( $self->is_array($val) ) {
    return $self->index_of( $val, $key ) != -1 ? true : false;
  }
  if ( $self->is_string($val) ) {
    # JS String.prototype.indexOf coerces the search value via ToString:
    # undefined -> "undefined", true -> "true", numbers -> their decimal form.
    # Perl's index() stringifies too, but undef -> "" (which matches at 0)
    # instead of "undefined". Coerce undef here to match JS. The full ToString
    # for other non-string values (booleans especially: true -> "true", not
    # Perl's "1") rides on k6 (native coercion) and is left to that decision.
    my $needle = defined($key) ? $key : 'undefined';
    return $self->js_string_index_of( $val, $needle ) != -1 ? true : false;    # code units (ADR 0012)
  }
  # Ordered hash (template dict literal / engine-built object, ADR 0011).
  if ( blessed($val) && $val->isa('Hash::Ordered') ) {
    return $val->exists($key) ? true : false;
  }

  if ( $self->is_object($val) ) {
    return exists( $val->{$key} ) ? true : false;    # key in val
  }

  die Text::Nunjucks::Lib::Error->new(
    'Cannot use "in" operator to search for "' . $key . '" in unexpected types.'
  );
}

#### JS regex character classes -- explicit ECMAScript sets (ADR 0005)

# JavaScript's \s is a FIXED ECMAScript set (WhiteSpace + LineTerminator), not
# Perl's \s. It includes U+00A0 (NBSP, a member of the lexer's whitespace_chars)
# and U+FEFF, and excludes U+0085; Perl's default /d \s additionally matches (or
# not) U+00A0 depending on whether the target SV carries the UTF-8 flag, so the
# same template would lex differently by how it reached the engine. The engine's
# own regexes therefore map JS \s to this explicit class, matched flag-
# independently under /u. Membership is oracle-verified via the lstripBlocks
# /^\s+$/ path (see t/10-lexer.t / the k10 report), never recalled:
#   WhiteSpace     U+0009 U+000B U+000C U+0020 U+00A0 U+FEFF
#                  + Unicode Zs: U+1680, U+2000-U+200A, U+202F, U+205F, U+3000
#   LineTerminator U+000A U+000D U+2028 U+2029
# \w is js_word_class and \d js_digit_class below (ADR 0005: added on demand,
# one seam per class, like _strict_eq / _falsy below).
my $JS_WHITESPACE_CLASS =
  qr/[\x09\x0A\x0B\x0C\x0D\x20\x{A0}\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]/u;

sub js_whitespace_class {
  my ($self) = @_;
  return $JS_WHITESPACE_CLASS;
}

# JavaScript's \w is [A-Za-z0-9_] -- ASCII only, without the u flag and with it
# (only u together with i widens it). Perl's \w is Unicode word characters. The
# filters' own regexes (wordcount's /\w+/g, striptags' \b) use this set; oracle:
# 'héllo wörld'|wordcount is 4, '١٢٣ abc'|wordcount is 1, and striptags keeps
# '<ab_c>' (no \b between b and _) but strips '<aſb>' (ſ is not a word char).
my $JS_WORD_CLASS = qr/[A-Za-z0-9_]/;

sub js_word_class {
  my ($self) = @_;
  return $JS_WORD_CLASS;
}

# JavaScript's \d is [0-9] -- ASCII only, with or without the u and i flags.
# Perl's \d is every Unicode decimal digit. urlize's emailRe uses it; oracle:
# 'a@x\u0663.com'|urlize does not take the mailto: branch (ARABIC-INDIC DIGIT
# THREE is not \d), 'a@x3.com' does.
my $JS_DIGIT_CLASS = qr/[0-9]/;

sub js_digit_class {
  my ($self) = @_;
  return $JS_DIGIT_CLASS;
}

#### JS !x (falsiness) for async_for, and Runtime _falsy's kind-based half

# Provisional JS falsiness keyed to ADR 0001 kinds. JS falsy values are
# undefined/null, false, 0, NaN and '' -- but the string '0' is TRUTHY in JS
# (Perl disagrees), so this cannot be a bare Perl boolean test. Truthiness's
# mechanism is slated for Runtime (k14); this is the single Lib seam it will
# merge with, mirroring _strict_eq below.
sub _falsy {
  my ( $self, $x ) = @_;
  return 1 if !defined($x);
  return ( $x ? 0 : 1 ) if is_bool($x);                                 # false is falsy
  return ( ( $x == 0 || $x != $x ) ? 1 : 0 ) if created_as_number($x);  # 0 or NaN
  return ( $x eq '' ? 1 : 0 ) if $self->is_string($x);                  # '' falsy, '0' truthy
  return 0;                                                              # refs are truthy
}

#### JS === for index_of / in_operator membership

# Provisional strict-equality keyed to ADR 0001 kinds. This mirrors the === that
# lib.js's indexOf relies on via Array.prototype.indexOf, so it lives here 1:1;
# Runtime will grow its own === for the template operator (k14). Whether the two
# should share one mechanism is an open placement question -- see the k9 report.
sub _strict_eq {
  my ( $self, $a, $b ) = @_;

  return 1 if !defined($a) && !defined($b);
  return 0 if !defined($a) || !defined($b);

  my ( $ra, $rb ) = ( ref($a), ref($b) );
  return ( ( $ra && $rb && refaddr($a) == refaddr($b) ) ? 1 : 0 ) if $ra || $rb;

  my ( $ba, $bb ) = ( is_bool($a), is_bool($b) );
  return 0 if !$ba != !$bb;                    # one boolean, one not
  return ( ( $a == $b ) ? 1 : 0 ) if $ba;      # both booleans

  my ( $na, $nb ) = ( created_as_number($a), created_as_number($b) );
  return 0 if !$na != !$nb;                     # number vs string
  if ($na) {
    return 0 if $a != $a || $b != $b;           # NaN !== NaN
    return $a == $b ? 1 : 0;
  }
  return $a eq $b ? 1 : 0;                       # both strings
}

#### number_to_string -- ECMAScript Number::toString, shortest round-trip (ADR 0007)

# Not a src/lib.js function: ADR 0007 designates Lib the single home for the
# JS Number->String routine, and the JS *operators* that home in Runtime feed
# their numeric results back through it. It reproduces ECMAScript
# Number::toString: the shortest decimal that round-trips to the same IEEE
# double, then JS's exponent thresholds and the spellings Infinity / -Infinity
# / NaN. Every number reaching template output goes through it
# (Runtime::_js_to_string / suppress_value); nothing uses bare "$n".
#
# JS numbers are all IEEE doubles; a Perl scalar can hold an exact 64-bit
# integer no double can represent -- a literal like 1234567890123456789, or an
# IV product Perl computed exactly (123456789 * 987654321 stays exact in Perl,
# but JS rounds it). pack/unpack('d') forces the value through a C double first
# so the rounding matches Node's. Runtime's operators round their operands the
# same way before computing, so intermediates are doubles too.
my $NUM_POS_INF  = 9**9**9;
my $NUM_NEG_INF  = -$NUM_POS_INF;
my $NUM_NAN      = $NUM_POS_INF - $NUM_POS_INF;
my $NUM_NEG_ZERO = -0.0;

sub number_to_string {
  my ( $self, $n ) = @_;

  $n = unpack( 'd', pack( 'd', $n ) );      # normalise to a real IEEE double

  return 'NaN'       if $n != $n;           # NaN is the only value != itself
  return 'Infinity'  if $n == $NUM_POS_INF;
  return '-Infinity' if $n == $NUM_NEG_INF;
  return '0'         if $n == 0;            # +0 and -0 both render "0"

  my $neg = $n < 0 ? 1 : 0;
  my $abs = $neg ? -$n : $n;

  # Shortest significant-digit count p (1..17) whose p-digit rounding of $abs
  # parses back to exactly $abs. 17 sig digits always round-trip a double, so
  # the loop terminates; sprintf %e gives the correctly-rounded p-digit form.
  # On a perl whose NV is wider than a double (ADR 0019) the comparison is made
  # on the double's bytes: 0 + $sci would be a long double, which a 17-digit
  # string never equals.
  my $wide = $Config::Config{nvsize} != 8;
  my $abs_bytes = $wide ? pack( 'd', $abs ) : undef;
  my ( $digits, $e10 );
  for my $p ( 1 .. 17 ) {
    my $sci = sprintf( '%.*e', $p - 1, $abs );
    if ( $wide ? pack( 'd', 0 + $sci ) eq $abs_bytes : 0 + $sci == $abs ) {
      $sci =~ /\A(\d)(?:\.(\d+))?e([+-]\d+)\z/
        or croak __PACKAGE__ . '->number_to_string cannot parse ' . $sci;
      $digits = $1 . ( defined $2 ? $2 : '' );
      $e10    = 0 + $3;
      last;
    }
  }

  # Strip trailing zeros for the spec's significant digits s (length k); the
  # decimal point position is n = e10 + 1 (value = s x 10^(n-k)).
  $digits =~ s/0+\z//;
  $digits = '0' if $digits eq '';
  my $k     = length $digits;
  my $point = $e10 + 1;

  my $out;
  if ( $k <= $point && $point <= 21 ) {
    $out = $digits . ( '0' x ( $point - $k ) );
  } elsif ( 0 < $point && $point <= 21 ) {
    $out = substr( $digits, 0, $point ) . '.' . substr( $digits, $point );
  } elsif ( -6 < $point && $point <= 0 ) {
    $out = '0.' . ( '0' x ( -$point ) ) . $digits;
  } elsif ( $k == 1 ) {
    my $e = $point - 1;
    $out = $digits . 'e' . ( $e >= 0 ? '+' : '-' ) . abs($e);
  } else {
    my $e = $point - 1;
    $out = substr( $digits, 0, 1 ) . '.' . substr( $digits, 1 )
      . 'e' . ( $e >= 0 ? '+' : '-' ) . abs($e);
  }

  return $neg ? '-' . $out : $out;
}

#### js_math_floor -- Math.floor(x)

# Not a src/lib.js function: the filters' Math.floor (random, slice), over an
# already-ToNumber'd value as the other number seams here take it. C's floor is
# IEEE's: NaN and +-Infinity pass through, -0 stays -0.
sub js_math_floor {
  my ( $self, $n ) = @_;
  return POSIX::floor($n);
}

#### js_math_ceil -- Math.ceil(x)

# The round filter's 'ceil' method, over an already-ToNumber'd value like
# js_math_floor: C's ceil is IEEE's, -0.5 gives -0.
sub js_math_ceil {
  my ( $self, $n ) = @_;
  return POSIX::ceil($n);
}

#### js_math_round -- Math.round(x)

# The round filter's default method, over an already-ToNumber'd value. The
# integral Number closest to x, a tie going towards +Infinity: 2.5 -> 3, -2.5 ->
# -2, and -0 for x in [-0.5, -0] (oracle: -0.5|round(0) is -0 -- 1/x is
# -Infinity). V8's Float64Round, step for step: ceil(x), one less unless ceil(x)
# - 0.5 <= x. It never computes x + 0.5, which rounds 0.49999999999999994 up to
# 1 and an odd integer above 2^52 to the next even one; NaN and +-Infinity pass
# through.
sub js_math_round {
  my ( $self, $n ) = @_;
  my $c = POSIX::ceil($n);
  return ( $c - 0.5 <= $n ) ? $c : $c - 1;
}

#### js_math_abs -- Math.abs(x)

# The abs filter (exports.abs = Math.abs), over an already-ToNumber'd value: C's
# fabs, so -0 is +0 and NaN stays NaN.
sub js_math_abs {
  my ( $self, $n ) = @_;
  return POSIX::fabs($n);
}

#### js_math_pow -- Math.pow(base, exponent)

# The round filter's Math.pow(10, precision) and the template ** operator
# (compiler.js emits Math.pow), over already-ToNumber'd values. Number::
# exponentiate is IEEE pow with two exceptions C's pow does not share: a NaN
# exponent gives NaN even for base 1, and base +-1 with an infinite exponent
# gives NaN, not 1 (oracle: 1 ** (1/0) -> NaN).
sub js_math_pow {
  my ( $self, $base, $exponent ) = @_;
  return $NUM_NAN if $exponent != $exponent;
  return $NUM_NAN
    if ( $exponent == $NUM_POS_INF || $exponent == $NUM_NEG_INF ) && ( $base == 1 || $base == -1 );
  return POSIX::pow( $base, $exponent );
}

#### js_parse_int -- parseInt(string, radix)

# Not a src/lib.js function: the global parseInt the int filter calls, over an
# already-ToString'd string and an already-ToNumber'd radix (undef for JS
# undefined), as the other number seams here take their arguments. ECMAScript
# parseInt step by step: leading StrWhiteSpaceChar trimmed (js_whitespace_class),
# one sign, the radix through ToInt32 -- 0 means 10, or 16 after a 0x / 0X
# prefix, which radix 16 strips too; outside 2..36 is NaN -- then the longest
# prefix of radix digits, NaN when there is none, and a zero keeps its sign
# (oracle: '-0'|int is -0). The digits' value is computed as V8 computes it,
# which the spec leaves to the implementation beyond 2^53 (oracle-fuzzed):
#
#   * radix 10: correctly rounded, as V8's Strtod -- Perl's numification of the
#     digit string is (an exact integer below 2^64, else C's strtod);
#   * radix 2, 4, 8, 16, 32: correctly rounded, round-half-even on the bits, the
#     integer arithmetic of V8's InternalStringToIntDouble;
#   * any other radix: V8's HandleGenericCase -- 32-bit chunks folded in by a
#     double multiply and a double add, two roundings per chunk.
sub js_parse_int {
  my ( $self, $input_string, $radix ) = @_;
  my $ws = $self->js_whitespace_class;
  ( my $s = $input_string ) =~ s/\A(?:$ws)+//;    # TrimString(inputString, start)
  my $sign = 1;
  $sign = -1 if substr( $s, 0, 1 ) eq '-';
  $s = substr( $s, 1 ) if $s =~ /\A[+-]/;
  my $r            = $self->_js_to_int32($radix);
  my $strip_prefix = 1;
  if ( $r != 0 ) {
    return $NUM_NAN if $r < 2 || $r > 36;
    $strip_prefix = 0 if $r != 16;
  } else {
    $r = 10;
  }
  if ( $strip_prefix && $s =~ /\A0[xX]/ ) {
    $s = substr( $s, 2 );
    $r = 16;
  }
  # the radix-R digits: 0-9 then a-z / A-Z, ASCII only
  my $class = $r <= 10
    ? '0-' . ( $r - 1 )
    : '0-9a-' . chr( ord('a') + $r - 11 ) . 'A-' . chr( ord('A') + $r - 11 );
  my ($z) = $s =~ /\A([$class]*)/;
  return $NUM_NAN if $z eq '';
  my $math_int = $self->_js_parse_int_value( $z, $r );
  return $sign < 0 ? $NUM_NEG_ZERO : 0 if $math_int == 0;
  return $sign < 0 ? -$math_int : $math_int;
}

# The value of a non-empty string of radix-$r digits, as V8 computes it.
sub _js_parse_int_value {
  my ( $self, $z, $r ) = @_;
  $z =~ s/\A0+//;    # V8 skips leading zeros before it counts digits
  return 0 if $z eq '';
  if ( $r == 10 ) {
    # V8 keeps the first 310 significant digits; more than 309 is past the
    # largest double either way
    return unpack( 'd', pack( 'd', 0 + substr( $z, 0, 310 ) ) );
  }
  my @digits = CORE::map { /[0-9]/ ? ord($_) - ord('0') : ( ord( lc $_ ) - ord('a') + 10 ) } split //, $z;
  return $self->_js_parse_int_power_of_two( \@digits, $r ) if ( $r & ( $r - 1 ) ) == 0;
  return $self->_js_parse_int_generic( \@digits, $r );
}

# V8's InternalStringToIntDouble<radix_log_2>: accumulate the digits in an
# integer until it passes 53 bits, then round half to even on the bits dropped,
# a non-zero tail breaking a tie upwards, and scale by the bits left over.
sub _js_parse_int_power_of_two {
  my ( $self, $digits, $radix ) = @_;
  my $radix_log_2 = 0;
  $radix_log_2++ while ( 1 << $radix_log_2 ) < $radix;
  # an exact integer, below 2^58. Perl IVs of 64 bits hold it; a perl with a
  # 4-byte IV (ADR 0019) computes it in Math::BigInt, the bit operations alike.
  my $big      = $Config::Config{ivsize} < 8;
  my $one      = $big ? Math::BigInt->new(1) : 1;
  my $number   = $big ? Math::BigInt->new(0) : 0;
  my $exponent = 0;
  for ( my $i = 0; $i < @$digits; $i++ ) {
    $number = $number * $radix + $digits->[$i];
    my $overflow = $number >> 53;
    if ( $overflow != 0 ) {
      # Overflow occurred. Need to determine which direction to round the result.
      my $overflow_bits_count = 1;
      while ( $overflow > 1 ) {
        $overflow_bits_count++;
        $overflow >>= 1;
      }

      my $dropped_bits_mask = ( $one << $overflow_bits_count ) - 1;
      my $dropped_bits      = $number & $dropped_bits_mask;
      $number >>= $overflow_bits_count;
      $exponent = $overflow_bits_count;

      my $zero_tail = 1;
      for ( $i++; $i < @$digits; $i++ ) {
        $zero_tail = 0 if $digits->[$i] != 0;
        $exponent += $radix_log_2;
      }

      my $middle_value = $one << ( $overflow_bits_count - 1 );
      if ( $dropped_bits > $middle_value ) {
        $number++;    # Rounding up.
      } elsif ( $dropped_bits == $middle_value ) {
        # Rounding to even to consistency with decimals: half-way case rounds
        # up if significant part is odd and down otherwise.
        $number++ if ( $number & 1 ) != 0 || !$zero_tail;
      }

      # Rounding up may cause overflow.
      if ( ( $number & ( $one << 53 ) ) != 0 ) {
        $exponent++;
        $number >>= 1;
      }
      last;
    }
  }
  $number = $number->numify if $big;
  return unpack( 'd', pack( 'd', $number ) ) if $exponent == 0;
  return POSIX::ldexp( $number, $exponent );
}

# V8's HandleGenericCase: the digits in chunks whose multiplier stays below
# 0xFFFFFFFF / 36, each folded in as result * multiplier + part in double
# arithmetic -- every step through pack('d'), since Perl would otherwise keep an
# exact integer product where the double rounds.
sub _js_parse_int_generic {
  my ( $self, $digits, $radix ) = @_;
  my $maximum_multiplier = int( 0xFFFFFFFF / 36 );
  my $result             = 0;
  my $i                  = 0;
  my $done               = 0;
  while ( !$done ) {
    my ( $part, $multiplier ) = ( 0, 1 );
    while (1) {
      if ( $i >= @$digits ) {
        $done = 1;
        last;
      }
      my $m = $multiplier * $radix;
      last if $m > $maximum_multiplier;
      $part       = $part * $radix + $digits->[$i];
      $multiplier = $m;
      $i++;
    }
    $result = unpack( 'd', pack( 'd', $result * $multiplier ) );
    $result = unpack( 'd', pack( 'd', $result + $part ) );
  }
  return $result;
}

#### js_parse_float -- parseFloat(string)

# Not a src/lib.js function: the global parseFloat the float filter calls, over
# an already-ToString'd string. Leading StrWhiteSpaceChar trimmed, then the
# longest prefix that is a StrDecimalLiteral -- an optional sign, then Infinity
# or digits with an optional fraction and exponent, no 0x, no numeric separator
# -- else NaN (oracle: '3.7abc' -> 3.7, '.5' -> 0.5, '1e' -> 1, 'Infinityx' ->
# Infinity, 'infinity' -> NaN, '-0' -> -0). The value is the correctly rounded
# double, as V8's StringToDouble gives it; Perl numifies a decimal string through
# C's strtod, which rounds correctly too.
sub js_parse_float {
  my ( $self, $input_string ) = @_;
  my $ws = $self->js_whitespace_class;
  ( my $s = $input_string ) =~ s/\A(?:$ws)+//;    # TrimString(inputString, start)
  my ( $sign, $unsigned ) =
    $s =~ /\A([+-]?)(Infinity|(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?)/
    or return $NUM_NAN;
  my $n = $unsigned eq 'Infinity' ? $NUM_POS_INF : unpack( 'd', pack( 'd', 0 + $unsigned ) );
  return $n if $sign ne '-';
  return $n == 0 ? $NUM_NEG_ZERO : -$n;
}

#### JS strings reckon in UTF-16 code units (ADR 0012)

# Not src/lib.js functions: ADR 0012 designates Lib the single home for the
# string operations JS defines over UTF-16 code units. Strings stay ordinary
# Perl character strings; the code-unit view is computed per call:
#
#   * the "unit form" of a string spells every astral character (U+10000 ..
#     U+10FFFF) as its two surrogate characters, so each Perl character of the
#     unit form IS one UTF-16 code unit, and Perl's own length / substr / index /
#     rindex / cmp run in code units on it;
#   * a result goes back through _js_from_units, which re-pairs every valid
#     high + low surrogate pair into its astral character. A surrogate left
#     without its partner -- a slice, split or index through a pair -- stays a
#     lone surrogate character, 1:1 with JS (ADR 0012 accepts them).
#
# The invariant: no string the engine builds holds a valid pair (a high
# surrogate U+D800..DBFF directly followed by a low one U+DC00..DFFF) as two
# surrogate characters -- a pair is always the one astral character. Seam
# results keep it through _js_from_units; joins keep it through
# js_string_append, the one way two strings are glued together (template `~`
# and string `+`, String concat / replace, Array join and toString, the output
# buffer, asyncAll's output, repeat). Because every string satisfies it, the
# two code-unit sequences JS compares are equal exactly when the Perl strings
# are, so Perl's eq and hash keys stand in for JS ==, ===, object keys and `in`
# over an array or object with no further mapping. A caller string that spells
# a pair as two surrogate characters is outside the invariant: the seams below
# give both spellings the same unit form, but eq and hash keys tell them apart.
#
# Index and length arguments follow one contract, because ToNumber lives in
# Runtime (ADR 0007) and these seams do not call into Runtime: an argument is a JS
# number (already through ToNumber) or undef for JS `undefined`, and undef means
# whatever `undefined` means for that parameter of that method. Search strings
# and separators arrive already through ToString.

my $JS_ASTRAL = qr/[\x{10000}-\x{10FFFF}]/;

# The last astral string converted and its unit form. Spelling the pairs out
# costs a Perl-level substitution per astral character, the eq that finds the
# string again a C-level compare, so a template that indexes one string in a
# loop ({{ s[i] }}) converts it once instead of once per index.
my ( $JS_UNITS_OF, $JS_UNITS );

sub _js_to_units {
  my ( $self, $s ) = @_;
  return $s unless $s =~ $JS_ASTRAL;
  return $JS_UNITS if defined($JS_UNITS_OF) && $JS_UNITS_OF eq $s;
  $JS_UNITS_OF = "$s";
  return $JS_UNITS = $s =~ s/($JS_ASTRAL)/$self->_js_surrogate_pair( ord $1 )/ger;
}

sub _js_surrogate_pair {
  my ( $self, $cp ) = @_;
  $cp -= 0x10000;
  return chr( 0xD800 + ( $cp >> 10 ) ) . chr( 0xDC00 + ( $cp & 0x3FF ) );
}

sub _js_from_units {
  my ( $self, $u ) = @_;
  return $u unless $u =~ /[\x{D800}-\x{DBFF}]/;
  return $u =~ s/([\x{D800}-\x{DBFF}])([\x{DC00}-\x{DFFF}])/
    chr( 0x10000 + ( ( ord($1) - 0xD800 ) << 10 ) + ( ord($2) - 0xDC00 ) )/ger;
}

# ECMAScript ToIntegerOrInfinity over an already-ToNumber'd value: NaN (and
# undef, JS undefined -> NaN) is 0, +-Infinity stays, the rest truncates to zero.
sub _js_to_integer_or_infinity {
  my ( $self, $n ) = @_;
  return 0 if !defined($n) || $n != $n;
  return $n if $n == $NUM_POS_INF || $n == $NUM_NEG_INF;
  return int($n);
}

# ECMAScript ToUint32 over an already-ToNumber'd value (String.prototype.split's
# limit): NaN and +-Infinity are 0, else truncate and wrap modulo 2^32.
sub _js_to_uint32 {
  my ( $self, $n ) = @_;
  return 0 if $n != $n || $n == $NUM_POS_INF || $n == $NUM_NEG_INF;
  my $m = POSIX::fmod( int($n), 4294967296 );
  return $m < 0 ? $m + 4294967296 : $m;
}

# ECMAScript ToInt32 over an already-ToNumber'd value (parseInt's radix), undef
# being JS undefined: ToUint32, then the upper half of the range wraps negative.
sub _js_to_int32 {
  my ( $self, $n ) = @_;
  return 0 unless defined $n;
  my $m = $self->_js_to_uint32($n);
  return $m >= 2147483648 ? $m - 4294967296 : $m;
}

# Clamp an integer-or-infinity to [0, $len].
sub _js_clamp {
  my ( $self, $n, $len ) = @_;
  return $n < 0 ? 0 : $n > $len ? $len : $n;
}

# The code units [$from, $to) of a unit form, back as a Perl string.
sub _js_unit_range {
  my ( $self, $u, $from, $to ) = @_;
  return '' if $from >= $to;
  return $self->_js_from_units( substr( $u, $from, $to - $from ) );
}

#### js_string_append -- JS string concatenation, in place

# Appends $str to the caller's string variable -- $_[1] is aliased, so the
# buffer is extended in place and never copied -- and returns nothing. JS joins
# code units, so a lone high surrogate at the end of the buffer and a lone low
# one at the start of $str form a valid pair in JS's result; here they become
# the one astral character, which keeps the invariant above. Only that boundary
# is looked at: each side already holds the invariant, so no other pair can
# form, and the check is O(1) whatever the buffer's length -- a test of $str's
# first character, then a chop of the buffer's last one (put back unless it is
# a high surrogate). Not a /[\x{D800}-\x{DBFF}]\z/ match: a successful match
# shares the buffer copy-on-write, so the chop after it would copy the whole
# buffer, and an output of many re-paired halves would turn O(n^2).
sub js_string_append {
  my ( $self, undef, $str ) = @_;
  my $lo = ord $str;    # ord '' is 0
  if ( $lo >= 0xDC00 && $lo <= 0xDFFF ) {
    my $last = chop $_[1];    # '' on an empty buffer
    my $hi   = ord $last;
    if ( $hi >= 0xD800 && $hi <= 0xDBFF ) {
      $_[1] .= chr( 0x10000 + ( ( $hi - 0xD800 ) << 10 ) + ( $lo - 0xDC00 ) ) . substr( $str, 1 );
      return;
    }
    $_[1] .= $last;
  }
  $_[1] .= $str;
  return;
}

#### js_string_length -- String length

sub js_string_length {
  my ( $self, $s ) = @_;
  # one code unit per character, plus the second unit of each astral one; the
  # match first, because tr over a wide range costs ~20 ns per character even
  # on a string with no astral character in it
  return CORE::length($s) unless $s =~ $JS_ASTRAL;
  return CORE::length($s) + ( $s =~ tr/\x{10000}-\x{10FFFF}// );
}

#### js_char_at -- String.prototype.charAt(pos)

sub js_char_at {
  my ( $self, $s, $pos ) = @_;
  my $u = $self->_js_to_units($s);
  my $p = $self->_js_to_integer_or_infinity($pos);
  return '' if $p < 0 || $p >= CORE::length($u);
  return substr( $u, $p, 1 );    # one unit: an ordinary character or a lone surrogate
}

#### js_string_slice -- String.prototype.slice(start, end)

sub js_string_slice {
  my ( $self, $s, $start, $end ) = @_;
  my $u    = $self->_js_to_units($s);
  my $len  = CORE::length($u);
  my $from = $self->_js_to_integer_or_infinity($start);
  my $to   = defined($end) ? $self->_js_to_integer_or_infinity($end) : $len;
  $from = $from < 0 ? $len + $from : $from;    # negative counts from the end
  $to   = $to < 0   ? $len + $to   : $to;
  return $self->_js_unit_range( $u, $self->_js_clamp( $from, $len ), $self->_js_clamp( $to, $len ) );
}

#### js_substring -- String.prototype.substring(start, end)

sub js_substring {
  my ( $self, $s, $start, $end ) = @_;
  my $u    = $self->_js_to_units($s);
  my $len  = CORE::length($u);
  my $from = $self->_js_clamp( $self->_js_to_integer_or_infinity($start), $len );
  my $to   = defined($end) ? $self->_js_clamp( $self->_js_to_integer_or_infinity($end), $len ) : $len;
  ( $from, $to ) = ( $to, $from ) if $from > $to;    # substring swaps, slice does not
  return $self->_js_unit_range( $u, $from, $to );
}

#### js_substr -- String.prototype.substr(start, length) (ECMAScript Annex B)

sub js_substr {
  my ( $self, $s, $start, $length ) = @_;
  my $u    = $self->_js_to_units($s);
  my $size = CORE::length($u);
  my $from = $self->_js_to_integer_or_infinity($start);
  $from = $from < 0 ? $size + $from : $from;
  $from = $self->_js_clamp( $from, $size );
  # length undefined -> to the end; a negative or NaN length takes nothing
  # (JS 'abc'.substr(0, -1) is '', where Perl's substr would drop the last char)
  my $n = defined($length) ? $self->_js_clamp( $self->_js_to_integer_or_infinity($length), $size ) : $size;
  my $to = $from + $n > $size ? $size : $from + $n;
  return $self->_js_unit_range( $u, $from, $to );
}

#### js_string_index_of -- String.prototype.indexOf(searchString, position)

sub js_string_index_of {
  my ( $self, $s, $search, $position ) = @_;
  my $u = $self->_js_to_units($s);
  my $p = $self->_js_clamp( $self->_js_to_integer_or_infinity($position), CORE::length($u) );
  return index( $u, $self->_js_to_units($search), $p );
}

#### js_string_last_index_of -- String.prototype.lastIndexOf(searchString, position)

sub js_string_last_index_of {
  my ( $self, $s, $search, $position ) = @_;
  my $u = $self->_js_to_units($s);
  # NaN -- and so undefined -- searches from the end, unlike indexOf's 0
  my $p = ( !defined($position) || $position != $position )
    ? $NUM_POS_INF
    : $self->_js_to_integer_or_infinity($position);
  return rindex( $u, $self->_js_to_units($search), $self->_js_clamp( $p, CORE::length($u) ) );
}

#### js_split -- String.prototype.split(separator, limit), string separator

sub js_split {
  my ( $self, $s, $separator, $limit ) = @_;
  my $lim = defined($limit) ? $self->_js_to_uint32($limit) : 4294967295;
  return [] if $lim == 0;
  return [$s] unless defined $separator;    # split(undefined) -> [S]

  my $u = $self->_js_to_units($s);
  # split('') -> the code units themselves, an astral character as two lone
  # surrogates; ''.split('') is [] while ''.split(',') is [''] (oracle)
  if ( $separator eq '' ) {
    my $head = $lim < CORE::length($u) ? substr( $u, 0, $lim ) : $u;
    return [ split //, $head ];
  }
  return [$s] if $u eq '';

  my $r     = $self->_js_to_units($separator);
  my $r_len = CORE::length($r);
  my @parts;
  my $i = 0;
  my $j = index( $u, $r, 0 );
  while ( $j != -1 ) {
    push @parts, $self->_js_unit_range( $u, $i, $j );
    return \@parts if @parts == $lim;
    $i = $j + $r_len;
    $j = index( $u, $r, $i );
  }
  push @parts, $self->_js_unit_range( $u, $i, CORE::length($u) );
  return \@parts;
}

#### js_string_compare -- the code-unit order of the JS relational operators

# IsLessThan on two strings compares UTF-16 code units, so U+FF01 sorts after
# U+1F600 (high surrogate U+D83D) where code points would put it before. cmp
# over the unit forms is exactly that order. Returns -1, 0 or 1.
sub js_string_compare {
  my ( $self, $x, $y ) = @_;
  return $self->_js_to_units($x) cmp $self->_js_to_units($y);
}

#### js_to_lower_case / js_to_upper_case -- String.prototype.toLowerCase / toUpperCase

# Not src/lib.js functions: the one home of JS case mapping, for the lower /
# upper / capitalize / title filters and the String methods a template calls.
# JS maps by code point with the full Unicode default case conversion -- the
# unconditional SpecialCasing mappings included (oracle: 'ß' upper is 'SS', 'İ'
# lower is 'i' + U+0307, two code units) -- which Perl's lc / uc also do, with
# two differences handled here:
#
#   * Final_Sigma, the one language-independent conditional mapping: a capital
#     sigma lowercases to final 'ς' where it ends a word, else to 'σ'. Perl's lc
#     always gives 'σ'. Oracle: 'ΑΣ' -> 'ας', 'ΑΣΑ' -> 'ασα', 'ΑΣ.' -> 'ας.',
#     'Α.Σ' -> 'α.ς', 'ΑΣ1' -> 'ας1', '1Σ' -> '1σ', 'ΑΣ\x{AD}' -> 'ας\x{AD}'.
#     The context test is ICU's, which V8 calls: skip case-ignorable characters
#     outward from the sigma, and the first other character must be cased
#     before it and must not be cased after it. A character that is both cased
#     and case-ignorable counts as ignorable (oracle: 'ʰΣ' -> 'ʰσ', U+02B0 is
#     both, where the Unicode wording alone would give 'ʰς').
#   * Perl maps Latin-1 characters by Unicode rules only under the
#     unicode_strings feature (else uc("\xDF") stays "\xDF" on a string without
#     the UTF-8 flag); both seams enable it.
#
# A lone surrogate maps to itself, as in JS (Perl would warn). A caller string
# that spells a pair as two surrogate characters is re-paired first, so both
# spellings map alike.
my $JS_FINAL_SIGMA = qr/
  ( (?!\p{Case_Ignorable})\p{Cased} \p{Case_Ignorable}* )    # the cased letter before
  \x{3A3}
  (?! \p{Case_Ignorable}* (?!\p{Case_Ignorable})\p{Cased} )  # no cased letter after
/x;

sub js_to_lower_case {
  my ( $self, $s ) = @_;
  use feature 'unicode_strings';
  no warnings 'surrogate';
  $s = $self->_js_from_units($s);
  $s =~ s/$JS_FINAL_SIGMA/$1\x{3C2}/g if index( $s, "\x{3A3}" ) >= 0;
  return lc $s;
}

sub js_to_upper_case {
  my ( $self, $s ) = @_;
  use feature 'unicode_strings';
  no warnings 'surrogate';
  return uc $self->_js_from_units($s);
}

#### js_get_substitution -- GetSubstitution, the replacement patterns of replace

# Not a src/lib.js function: ECMAScript GetSubstitution(matched, str, position,
# captures, namedCaptures, replacement), which String.prototype.replace and
# RegExp.prototype[Symbol.replace] apply to a string replacement:
#
#   $$ -> '$'   $& -> matched   $` -> str before the match   $' -> str after it
#   $n / $nn    -> capture n (1..99), '' for a group that did not take part; a
#                  two-digit index past the last group is read as one digit and a
#                  literal digit ($10 with one group -> capture 1 then '0'), and an
#                  index of 0 or past the groups stays literal ($0, $00, $1 with none)
#   $<name>     -> the named group ('' if absent); literal '$<' when the regex has
#                  no named groups ($named undef) or no '>' follows; $named is
#                  the match's groups object, an engine-built Hash::Ordered
#
# Oracle: 'abc'.replace(/(b)/, '[$1$2$0$01$10]') -> 'a[b$2$0bb0]c'; with eleven
# groups '[$11|$10|$1|$12|$011|$00|$100]' -> '[k|j|a|a2|a1|$00|j0]'. $position
# counts code units (ADR 0012); $captures is an arrayref (undef for a group that
# did not participate); every piece is joined through js_string_append.
sub js_get_substitution {
  my ( $self, $matched, $str, $position, $captures, $named, $replacement ) = @_;
  return $replacement if index( $replacement, '$' ) < 0;

  my $m      = scalar @$captures;
  my $result = '';
  pos($replacement) = 0;
  while ( pos($replacement) < CORE::length($replacement) ) {
    my $ref_replacement;
    if ( $replacement =~ /\G([^\$]+)/gc ) {
      $ref_replacement = $1;
    } elsif ( $replacement =~ /\G\$\$/gc ) {
      $ref_replacement = '$';
    } elsif ( $replacement =~ /\G\$`/gc ) {
      $ref_replacement = $self->js_substring( $str, 0, $position );
    } elsif ( $replacement =~ /\G\$&/gc ) {
      $ref_replacement = $matched;
    } elsif ( $replacement =~ /\G\$'/gc ) {
      my $tail_pos = $position + $self->js_string_length($matched);
      $ref_replacement = $self->js_substring( $str, $tail_pos );    # substring clamps to the length
    } elsif ( $replacement =~ /\G\$([0-9])([0-9]?)/gc ) {
      my ( $d1, $d2 ) = ( $1, $2 );
      my $index = $d1 . $d2;
      if ( $d2 ne '' && $index > $m ) {
        # a two-digit index past the groups: one digit, the second is literal
        ( $index, $d2 ) = ( $d1, '' );
        pos($replacement) = pos($replacement) - 1;
      }
      $ref_replacement = ( $index >= 1 && $index <= $m )
        ? ( defined( $captures->[ $index - 1 ] ) ? $captures->[ $index - 1 ] : '' )
        : '$' . $d1 . $d2;
    } elsif ( $replacement =~ /\G\$</gc ) {
      my $gt_pos = index( $replacement, '>', pos($replacement) );
      if ( $gt_pos < 0 || !defined($named) ) {
        $ref_replacement = '$<';
      } else {
        my $group_name = substr( $replacement, pos($replacement), $gt_pos - pos($replacement) );
        pos($replacement) = $gt_pos + 1;
        my $capture = $named->get($group_name);
        $ref_replacement = defined($capture) ? $capture : '';
      }
    } else {
      $replacement =~ /\G\$/gc;
      $ref_replacement = '$';
    }
    $self->js_string_append( $result, $ref_replacement );
  }
  return $result;
}

#### js_encode_uri_component -- encodeURIComponent(uriComponent)

# Not a src/lib.js function: the global encodeURIComponent the urlencode filter
# calls, over an already-ToString'd string. ECMAScript Encode(string,
# extraUnescaped): A-Z a-z 0-9 and - _ . ! ~ * ' ( ) stay, every other code
# point goes out as the %XX bytes of its UTF-8 form in uppercase hex (oracle:
# 'a b&c' -> a%20b%26c, 'é' -> %C3%A9, '\u{1F600}' -> %F0%9F%98%80). It walks code
# units: a surrogate pair is the one code point, a lone surrogate has no UTF-8
# form and throws URIError: URI malformed (oracle: '\u{1F600}'|first|urlencode). A
# caller string spelling a pair as two surrogate characters is re-paired first,
# so both spellings encode alike (ADR 0012).
sub js_encode_uri_component {
  my ( $self, $s ) = @_;
  my $str = $self->_js_from_units($s);
  die Text::Nunjucks::Lib::Error->new( 'URI malformed', name => 'URIError' )
    if $str =~ /[\x{D800}-\x{DFFF}]/;
  return $str =~ s{([^A-Za-z0-9\-_.!~*'()])}{$self->_js_utf8_percent_encode($1)}ger;
}

sub _js_utf8_percent_encode {
  my ( $self, $char ) = @_;
  utf8::encode($char);
  return CORE::join( '', CORE::map { sprintf( '%%%02X', ord $_ ) } split //, $char );
}

#### js_array_sort -- Array.prototype.sort(comparefn), V8's TimSort

# Not a src/lib.js function: the one home of JS Array.prototype.sort -- the
# Array `sort` member of the ADR 0008 surface and the sort / dictsort filters'
# array.sort(...). Maintainer decision B (k17): a port of V8's implementation,
# pinned to the V8 of the oracle's Node (v24.19.0, V8 13.6.233.17), so that a
# comparator that is no consistent order -- or one that watches its calls --
# gets exactly the calls V8 makes and leaves the array as V8 leaves it. Source:
# third_party/v8/builtins/array-sort.tq at V8 tag 13.6.233.17
# (https://raw.githubusercontent.com/v8/v8/13.6.233.17/third_party/v8/builtins/array-sort.tq),
# CPython's TimSort: natural runs, binary insertion sort up to the minimum run
# length, merge_lo / merge_hi with galloping and the min_gallop adaptation. The
# macros and builtins below are the .tq's, in its order, named in snake_case
# with a _js_sort_ prefix; the comparator call sequence follows from their
# control flow, which is therefore kept as is. The sort state is a hash, the
# .tq's SortState fields in snake_case.
#
# Around the TimSort, the spec steps V8 implements: a comparefn that is neither
# undefined nor callable throws before anything else, even on an empty array
# (oracle: [].sort(5) -> "TypeError: The comparison function must be either a
# function or undefined: 5"); fewer than two elements return untouched; the
# undefined elements are counted out of the work array, never passed to the
# comparator, and written back after the sorted values (oracle: [u, 'z',
# 'a'].sort() -> a,z,undefined). Without a comparefn two elements compare as
# their ToStrings in UTF-16 code-unit order (Runtime's JS ToString, ADR 0012's
# js_string_compare); a comparefn is called with (x, y) and no this (ADR 0009),
# its result goes through JS ToNumber and NaN counts as +0 (oracle: a macro's
# SafeString output ' 2 ' is 2, 'x' is 0); only the sign is used, and -0 is not
# below 0. Whatever the comparefn throws propagates as is. It sorts a copy of
# the elements, and the receiver is written once, at the end: the comparefn
# sees the unsorted array, and an exception leaves it unchanged.
#
# What the .tq does that has no counterpart here, and why:
#   * the elements-kind accessors (Load / Store / Delete for Smi, double, object
#     and generic elements, CheckAccessor, ResetToGenericAccessor): Perl has one
#     array kind, and every accessor writes the same values back -- index by
#     index, so a comparefn that grew the array keeps its tail, as in V8;
#   * array holes: the Perl value model has none (ADR 0001), so the compaction
#     skips nothing and the copy back deletes nothing;
#   * SortCompareDefault's Smi fast path (SmiLexicographicCompare): it returns
#     what comparing the two decimal strings returns;
#   * the Smi clamps of the lengths (kSmiMaxValue), the offset overflow guards
#     in the gallops (Smi wrap-around) and the temp array's size policy: Perl
#     integers do not wrap at array sizes, and a Perl array grows on demand.

# When we get into galloping mode, we stay there until both runs win less often
# than kMinGallopWins consecutive times.
my $JS_SORT_MIN_GALLOP_WINS = 7;

# SortState.Compare
sub _js_sort_compare {
  my ( $self, $sort_state, $x, $y ) = @_;
  return defined( $sort_state->{user_cmp_fn} )
    ? $self->_js_sort_compare_user_fn( $sort_state->{user_cmp_fn}, $x, $y )
    : $self->_js_sort_compare_default( $x, $y );
}

sub _js_sort_new_sort_state {
  my ( $self, $receiver, $comparefn, $initial_receiver_length ) = @_;
  return {
    receiver                => $receiver,
    initial_receiver_length => $initial_receiver_length,
    user_cmp_fn             => $comparefn,
    min_gallop              => $JS_SORT_MIN_GALLOP_WINS,
    pending_runs_size       => 0,
    pending_runs            => [],
    work_array              => [],
    temp_array              => [],
    sort_length             => 0,
    number_of_undefined     => 0,
  };
}

sub _js_sort_compare_default {
  my ( $self, $x, $y ) = @_;
  my $rt = $self->_runtime;

  # 5. Let xString be ? ToString(x).
  # 6. Let yString be ? ToString(y).
  # 7.-11. xString < yString -> -1, yString < xString -> 1, else +0
  return $self->js_string_compare( $rt->_js_to_string($x), $rt->_js_to_string($y) );
}

sub _js_sort_compare_user_fn {
  my ( $self, $comparefn, $x, $y ) = @_;

  # a. Let v be ? ToNumber(? Call(comparefn, undefined, x, y)).
  my $v = $self->_runtime->_to_number( $comparefn->( $x, $y ) );

  # b. If v is NaN, return +0.
  return 0 if $v != $v;

  # c. return v.
  return $v;
}

# The pending runs, run #i at [2 * i] (base) and [2 * i + 1] (length).
sub _js_sort_get_pending_runs_size  { my ( $self, $sort_state ) = @_; $sort_state->{pending_runs_size} }
sub _js_sort_get_pending_run_base   { my ( $self, $pending_runs, $run ) = @_; $pending_runs->[ $run << 1 ] }
sub _js_sort_set_pending_run_base   { my ( $self, $pending_runs, $run, $value ) = @_; $pending_runs->[ $run << 1 ] = $value; return }
sub _js_sort_get_pending_run_length { my ( $self, $pending_runs, $run ) = @_; $pending_runs->[ ( $run << 1 ) + 1 ] }
sub _js_sort_set_pending_run_length { my ( $self, $pending_runs, $run, $value ) = @_; $pending_runs->[ ( $run << 1 ) + 1 ] = $value; return }

sub _js_sort_push_run {
  my ( $self, $sort_state, $base, $length ) = @_;
  my $stack_size   = $self->_js_sort_get_pending_runs_size($sort_state);
  my $pending_runs = $sort_state->{pending_runs};

  $self->_js_sort_set_pending_run_base( $pending_runs, $stack_size, $base );
  $self->_js_sort_set_pending_run_length( $pending_runs, $stack_size, $length );

  $sort_state->{pending_runs_size} = $stack_size + 1;
  return;
}

# Returns the temporary array. V8 makes sure it has at least
# max(kSortStateTempSize, requestedSize) slots; a Perl array grows on demand.
sub _js_sort_get_temp_array {
  my ( $self, $sort_state, $requested_size ) = @_;
  return $sort_state->{temp_array};
}

# source and target might be the same array, with overlapping ranges; V8 copies
# from the back when srcPos < dstPos. A slice assignment reads the whole source
# range before it writes, which gives the same result.
sub _js_sort_copy {
  my ( $self, $source, $src_pos, $target, $dst_pos, $length ) = @_;
  @{$target}[ $dst_pos .. $dst_pos + $length - 1 ] = @{$source}[ $src_pos .. $src_pos + $length - 1 ];
  return;
}

# BinaryInsertionSort is the best method for sorting small arrays: it does few
# compares, but can do data movement quadratic in the number of elements.
# [low, high) is a contiguous range of an array, and is sorted via binary
# insertion. This sort is stable. On entry, must have low <= start <= high, and
# that [low, start) is already sorted. Pass start == low if you do not know!
sub _js_sort_binary_insertion_sort {
  my ( $self, $sort_state, $low, $start_arg, $high ) = @_;
  my $work_array = $sort_state->{work_array};

  my $start = $low == $start_arg ? $start_arg + 1 : $start_arg;

  for ( ; $start < $high; ++$start ) {
    # Set left to where a[start] belongs.
    my $left  = $low;
    my $right = $start;

    my $pivot = $work_array->[$right];

    # Invariants:
    #   pivot >= all in [low, left).
    #   pivot  < all in [right, start).
    # Find pivot insertion point.
    while ( $left < $right ) {
      my $mid   = $left + ( ( $right - $left ) >> 1 );
      my $order = $self->_js_sort_compare( $sort_state, $pivot, $work_array->[$mid] );

      if ( $order < 0 ) {
        $right = $mid;
      } else {
        $left = $mid + 1;
      }
    }

    # The invariants still hold, so pivot belongs at left. Note that if there
    # are elements equal to pivot, left points to the first slot after them --
    # that's why this sort is stable. Slide over to make room.
    @{$work_array}[ $left + 1 .. $start ] = @{$work_array}[ $left .. $start - 1 ];
    $work_array->[$left] = $pivot;
  }
  return;
}

# Return the length of the run beginning at low, in the range [low, high), low
# < high is required on entry. "A run" is the longest ascending sequence, with
#   a[low] <= a[low + 1] <= a[low + 2] <= ...
# or the longest descending sequence, with
#   a[low] > a[low + 1] > a[low + 2] > ...
# The strict ">" ensures there are no equal elements to get out of order when
# a descending run is reversed, so the returned length is always an ascending
# sequence.
sub _js_sort_count_and_make_run {
  my ( $self, $sort_state, $low_arg, $high ) = @_;
  my $work_array = $sort_state->{work_array};

  my $low = $low_arg + 1;
  return 1 if $low == $high;

  my $run_length = 2;

  my $element_low      = $work_array->[$low];
  my $element_low_pred = $work_array->[ $low - 1 ];
  my $order            = $self->_js_sort_compare( $sort_state, $element_low, $element_low_pred );

  my $is_descending = $order < 0 ? 1 : 0;

  my $previous_element = $element_low;
  for ( my $idx = $low + 1; $idx < $high; ++$idx ) {
    my $current_element = $work_array->[$idx];
    $order = $self->_js_sort_compare( $sort_state, $current_element, $previous_element );

    if ($is_descending) {
      last if $order >= 0;
    } else {
      last if $order < 0;
    }

    $previous_element = $current_element;
    ++$run_length;
  }

  $self->_js_sort_reverse_range( $work_array, $low_arg, $low_arg + $run_length ) if $is_descending;

  return $run_length;
}

sub _js_sort_reverse_range {
  my ( $self, $array, $from, $to ) = @_;
  @{$array}[ $from .. $to - 1 ] = reverse @{$array}[ $from .. $to - 1 ];
  return;
}

# Merges the two runs at stack indices i and i + 1. We are only allowed to
# either merge the two top-most runs, or leave the top most run alone and merge
# the two next runs.
sub _js_sort_merge_at {
  my ( $self, $sort_state, $i ) = @_;
  my $stack_size = $self->_js_sort_get_pending_runs_size($sort_state);
  my $work_array = $sort_state->{work_array};

  my $pending_runs = $sort_state->{pending_runs};
  my $base_a       = $self->_js_sort_get_pending_run_base( $pending_runs, $i );
  my $length_a     = $self->_js_sort_get_pending_run_length( $pending_runs, $i );
  my $base_b       = $self->_js_sort_get_pending_run_base( $pending_runs, $i + 1 );
  my $length_b     = $self->_js_sort_get_pending_run_length( $pending_runs, $i + 1 );

  # Record the length of the combined runs; if i is the 3rd-last run now, also
  # slide over the last run (which isn't involved in this merge). The current
  # run i + 1 goes away in any case.
  $self->_js_sort_set_pending_run_length( $pending_runs, $i, $length_a + $length_b );
  if ( $i == $stack_size - 3 ) {
    my $base   = $self->_js_sort_get_pending_run_base( $pending_runs, $i + 2 );
    my $length = $self->_js_sort_get_pending_run_length( $pending_runs, $i + 2 );
    $self->_js_sort_set_pending_run_base( $pending_runs, $i + 1, $base );
    $self->_js_sort_set_pending_run_length( $pending_runs, $i + 1, $length );
  }
  $sort_state->{pending_runs_size} = $stack_size - 1;

  # Where does b start in a? Elements in a before that can be ignored, because
  # they are already in place.
  my $key_right = $work_array->[$base_b];
  my $k         = $self->_js_sort_gallop_right( $sort_state, $work_array, $key_right, $base_a, $length_a, 0 );

  $base_a   = $base_a + $k;
  $length_a = $length_a - $k;
  return if $length_a == 0;

  # Where does a end in b? Elements in b after that can be ignored, because
  # they are already in place.
  my $key_left = $work_array->[ $base_a + $length_a - 1 ];
  $length_b = $self->_js_sort_gallop_left( $sort_state, $work_array, $key_left, $base_b, $length_b, $length_b - 1 );
  return if $length_b == 0;

  # Merge what remains of the runs, using a temp array with min(lengthA,
  # lengthB) elements.
  if ( $length_a <= $length_b ) {
    $self->_js_sort_merge_low( $sort_state, $base_a, $length_a, $base_b, $length_b );
  } else {
    $self->_js_sort_merge_high( $sort_state, $base_a, $length_a, $base_b, $length_b );
  }
  return;
}

# Locates the proper position of key in a sorted array; if the array contains
# an element equal to key, return the position immediately to the left of the
# leftmost equal element. (GallopRight does the same except returns the
# position to the right of the rightmost equal element (if any)).
#
# The array is sorted with "length" elements, starting at "base". "length" must
# be > 0. "hint" is an index at which to begin the search, 0 <= hint < n. The
# closer hint is to the final result, the faster this runs.
#
# The return value is the int offset in 0..length such that
#   array[base + offset] < key <= array[base + offset + 1]
# pretending that array[base - 1] is minus infinity and array[base + len] is
# plus infinity. In other words, key belongs at index base + k.
sub _js_sort_gallop_left {
  my ( $self, $sort_state, $array, $key, $base, $length, $hint ) = @_;

  my $last_ofs = 0;
  my $offset   = 1;

  my $base_hint_element = $array->[ $base + $hint ];
  my $order             = $self->_js_sort_compare( $sort_state, $base_hint_element, $key );

  if ( $order < 0 ) {
    # a[base + hint] < key: gallop right, until
    # a[base + hint + lastOfs] < key <= a[base + hint + offset].

    # a[base + length - 1] is highest.
    my $max_ofs = $length - $hint;
    while ( $offset < $max_ofs ) {
      my $offset_element = $array->[ $base + $hint + $offset ];
      $order = $self->_js_sort_compare( $sort_state, $offset_element, $key );

      # a[base + hint + offset] >= key? Break.
      last if $order >= 0;

      $last_ofs = $offset;
      $offset   = ( $offset << 1 ) + 1;
    }

    $offset = $max_ofs if $offset > $max_ofs;

    # Translate back to positive offsets relative to base.
    $last_ofs = $last_ofs + $hint;
    $offset   = $offset + $hint;
  } else {
    # key <= a[base + hint]: gallop left, until
    # a[base + hint - offset] < key <= a[base + hint - lastOfs].

    # a[base + hint] is lowest.
    my $max_ofs = $hint + 1;
    while ( $offset < $max_ofs ) {
      my $offset_element = $array->[ $base + $hint - $offset ];
      $order = $self->_js_sort_compare( $sort_state, $offset_element, $key );

      last if $order < 0;

      $last_ofs = $offset;
      $offset   = ( $offset << 1 ) + 1;
    }

    $offset = $max_ofs if $offset > $max_ofs;

    # Translate back to positive offsets relative to base.
    my $tmp = $last_ofs;
    $last_ofs = $hint - $offset;
    $offset   = $hint - $tmp;
  }

  # Now a[base+lastOfs] < key <= a[base+offset], so key belongs somewhere to the
  # right of lastOfs but no farther right than offset. Do a binary search, with
  # invariant: a[base + lastOfs - 1] < key <= a[base + offset].
  $last_ofs++;
  while ( $last_ofs < $offset ) {
    my $m = $last_ofs + ( ( $offset - $last_ofs ) >> 1 );

    $order = $self->_js_sort_compare( $sort_state, $array->[ $base + $m ], $key );

    if ( $order < 0 ) {
      $last_ofs = $m + 1;    # a[base + m] < key.
    } else {
      $offset = $m;          # key <= a[base + m].
    }
  }
  # so a[base + offset - 1] < key <= a[base + offset].
  return $offset;
}

# Exactly like GallopLeft, except that if key already exists in [base, base +
# length), finds the position immediately to the right of the rightmost equal
# value. The return value is the int offset in 0..length such that
#   array[base + offset - 1] <= key < array[base + offset]
sub _js_sort_gallop_right {
  my ( $self, $sort_state, $array, $key, $base, $length, $hint ) = @_;

  my $last_ofs = 0;
  my $offset   = 1;

  my $base_hint_element = $array->[ $base + $hint ];
  my $order             = $self->_js_sort_compare( $sort_state, $key, $base_hint_element );

  if ( $order < 0 ) {
    # key < a[base + hint]: gallop left, until
    # a[base + hint - offset] <= key < a[base + hint - lastOfs].

    # a[base + hint] is lowest.
    my $max_ofs = $hint + 1;
    while ( $offset < $max_ofs ) {
      my $offset_element = $array->[ $base + $hint - $offset ];
      $order = $self->_js_sort_compare( $sort_state, $key, $offset_element );

      last if $order >= 0;

      $last_ofs = $offset;
      $offset   = ( $offset << 1 ) + 1;
    }

    $offset = $max_ofs if $offset > $max_ofs;

    # Translate back to positive offsets relative to base.
    my $tmp = $last_ofs;
    $last_ofs = $hint - $offset;
    $offset   = $hint - $tmp;
  } else {
    # a[base + hint] <= key: gallop right, until
    # a[base + hint + lastOfs] <= key < a[base + hint + offset].

    # a[base + length - 1] is highest.
    my $max_ofs = $length - $hint;
    while ( $offset < $max_ofs ) {
      my $offset_element = $array->[ $base + $hint + $offset ];
      $order = $self->_js_sort_compare( $sort_state, $key, $offset_element );

      # a[base + hint + ofs] <= key.
      last if $order < 0;

      $last_ofs = $offset;
      $offset   = ( $offset << 1 ) + 1;
    }

    $offset = $max_ofs if $offset > $max_ofs;

    # Translate back to positive offests relative to base.
    $last_ofs = $last_ofs + $hint;
    $offset   = $offset + $hint;
  }

  # Now a[base + lastOfs] <= key < a[base + ofs], so key belongs somewhere to
  # the right of lastOfs but no farther right than ofs. Do a binary search, with
  # invariant a[base + lastOfs - 1] < key <= a[base + ofs].
  $last_ofs++;
  while ( $last_ofs < $offset ) {
    my $m = $last_ofs + ( ( $offset - $last_ofs ) >> 1 );

    $order = $self->_js_sort_compare( $sort_state, $key, $array->[ $base + $m ] );

    if ( $order < 0 ) {
      $offset = $m;          # key < a[base + m].
    } else {
      $last_ofs = $m + 1;    # a[base + m] <= key.
    }
  }
  # so a[base + offset - 1] <= key < a[base + offset].
  return $offset;
}

# Merge the lengthA elements starting at baseA with the lengthB elements
# starting at baseB in a stable way, in-place. lengthA and lengthB must be > 0,
# and baseA + lengthA == baseB. Must also have that array[baseB] <
# array[baseA], that array[baseA + lengthA - 1] belongs at the end of the
# merge, and should have lengthA <= lengthB.
#
# The .tq's try / label blocks: `goto Succeed` and `goto CopyB` leave the MERGE
# block with `last MERGE`, the label's name in $goto.
sub _js_sort_merge_low {
  my ( $self, $sort_state, $base_a, $length_a_arg, $base_b, $length_b_arg ) = @_;

  my $length_a = $length_a_arg;
  my $length_b = $length_b_arg;

  my $work_array = $sort_state->{work_array};
  my $temp_array = $self->_js_sort_get_temp_array( $sort_state, $length_a );
  $self->_js_sort_copy( $work_array, $base_a, $temp_array, 0, $length_a );

  my $dest        = $base_a;
  my $cursor_temp = 0;
  my $cursor_b    = $base_b;

  $work_array->[ $dest++ ] = $work_array->[ $cursor_b++ ];

  my $goto = 'Succeed';
  MERGE: {
    last MERGE if --$length_b == 0;
    if ( $length_a == 1 ) { $goto = 'CopyB'; last MERGE }

    my $min_gallop = $sort_state->{min_gallop};
    while (1) {
      my $nof_wins_a = 0;    # # of times A won in a row.
      my $nof_wins_b = 0;    # # of times B won in a row.

      # Do the straightforward thing until (if ever) one run appears to win
      # consistently.
      while (1) {
        my $order = $self->_js_sort_compare( $sort_state, $work_array->[$cursor_b], $temp_array->[$cursor_temp] );

        if ( $order < 0 ) {
          $work_array->[ $dest++ ] = $work_array->[ $cursor_b++ ];

          ++$nof_wins_b;
          --$length_b;
          $nof_wins_a = 0;

          last MERGE if $length_b == 0;
          last if $nof_wins_b >= $min_gallop;
        } else {
          $work_array->[ $dest++ ] = $temp_array->[ $cursor_temp++ ];

          ++$nof_wins_a;
          --$length_a;
          $nof_wins_b = 0;

          if ( $length_a == 1 ) { $goto = 'CopyB'; last MERGE }
          last if $nof_wins_a >= $min_gallop;
        }
      }

      # One run is winning so consistently that galloping may be a huge win. So
      # try that, and continue galloping until (if ever) neither run appears to
      # be winning consistently anymore.
      ++$min_gallop;
      my $first_iteration = 1;
      while ( $nof_wins_a >= $JS_SORT_MIN_GALLOP_WINS || $nof_wins_b >= $JS_SORT_MIN_GALLOP_WINS || $first_iteration ) {
        $first_iteration = 0;

        $min_gallop = $min_gallop - 1 > 1 ? $min_gallop - 1 : 1;    # SmiMax(1, minGallop - 1)
        $sort_state->{min_gallop} = $min_gallop;

        $nof_wins_a = $self->_js_sort_gallop_right( $sort_state, $temp_array, $work_array->[$cursor_b], $cursor_temp, $length_a, 0 );

        if ( $nof_wins_a > 0 ) {
          $self->_js_sort_copy( $temp_array, $cursor_temp, $work_array, $dest, $nof_wins_a );
          $dest        = $dest + $nof_wins_a;
          $cursor_temp = $cursor_temp + $nof_wins_a;
          $length_a    = $length_a - $nof_wins_a;

          if ( $length_a == 1 ) { $goto = 'CopyB'; last MERGE }

          # lengthA == 0 is impossible now if the comparison function is
          # consistent, but we can't assume that it is.
          last MERGE if $length_a == 0;
        }
        $work_array->[ $dest++ ] = $work_array->[ $cursor_b++ ];
        last MERGE if --$length_b == 0;

        $nof_wins_b = $self->_js_sort_gallop_left( $sort_state, $work_array, $temp_array->[$cursor_temp], $cursor_b, $length_b, 0 );
        if ( $nof_wins_b > 0 ) {
          $self->_js_sort_copy( $work_array, $cursor_b, $work_array, $dest, $nof_wins_b );

          $dest     = $dest + $nof_wins_b;
          $cursor_b = $cursor_b + $nof_wins_b;
          $length_b = $length_b - $nof_wins_b;

          last MERGE if $length_b == 0;
        }
        $work_array->[ $dest++ ] = $temp_array->[ $cursor_temp++ ];
        if ( --$length_a == 1 ) { $goto = 'CopyB'; last MERGE }
      }
      ++$min_gallop;    # Penalize it for leaving galloping mode
      $sort_state->{min_gallop} = $min_gallop;
    }
  }

  if ( $goto eq 'Succeed' ) {
    $self->_js_sort_copy( $temp_array, $cursor_temp, $work_array, $dest, $length_a ) if $length_a > 0;
  } else {    # CopyB
    # The last element of run A belongs at the end of the merge.
    $self->_js_sort_copy( $work_array, $cursor_b, $work_array, $dest, $length_b );
    $work_array->[ $dest + $length_b ] = $temp_array->[$cursor_temp];
  }
  return;
}

# Merge the lengthA elements starting at baseA with the lengthB elements
# starting at baseB in a stable way, in-place. lengthA and lengthB must be > 0.
# Must also have that array[baseA + lengthA - 1] belongs at the end of the
# merge and should have lengthA >= lengthB. Labels as in _js_sort_merge_low,
# here Succeed and CopyA.
sub _js_sort_merge_high {
  my ( $self, $sort_state, $base_a, $length_a_arg, $base_b, $length_b_arg ) = @_;

  my $length_a = $length_a_arg;
  my $length_b = $length_b_arg;

  my $work_array = $sort_state->{work_array};
  my $temp_array = $self->_js_sort_get_temp_array( $sort_state, $length_b );
  $self->_js_sort_copy( $work_array, $base_b, $temp_array, 0, $length_b );

  # MergeHigh merges the two runs backwards.
  my $dest        = $base_b + $length_b - 1;
  my $cursor_temp = $length_b - 1;
  my $cursor_a    = $base_a + $length_a - 1;

  $work_array->[ $dest-- ] = $work_array->[ $cursor_a-- ];

  my $goto = 'Succeed';
  MERGE: {
    last MERGE if --$length_a == 0;
    if ( $length_b == 1 ) { $goto = 'CopyA'; last MERGE }

    my $min_gallop = $sort_state->{min_gallop};
    while (1) {
      my $nof_wins_a = 0;    # # of times A won in a row.
      my $nof_wins_b = 0;    # # of times B won in a row.

      # Do the straightforward thing until (if ever) one run appears to win
      # consistently.
      while (1) {
        my $order = $self->_js_sort_compare( $sort_state, $temp_array->[$cursor_temp], $work_array->[$cursor_a] );

        if ( $order < 0 ) {
          $work_array->[ $dest-- ] = $work_array->[ $cursor_a-- ];

          ++$nof_wins_a;
          --$length_a;
          $nof_wins_b = 0;

          last MERGE if $length_a == 0;
          last if $nof_wins_a >= $min_gallop;
        } else {
          $work_array->[ $dest-- ] = $temp_array->[ $cursor_temp-- ];

          ++$nof_wins_b;
          --$length_b;
          $nof_wins_a = 0;

          if ( $length_b == 1 ) { $goto = 'CopyA'; last MERGE }
          last if $nof_wins_b >= $min_gallop;
        }
      }

      # One run is winning so consistently that galloping may be a huge win. So
      # try that, and continue galloping until (if ever) neither run appears to
      # be winning consistently anymore.
      ++$min_gallop;
      my $first_iteration = 1;
      while ( $nof_wins_a >= $JS_SORT_MIN_GALLOP_WINS || $nof_wins_b >= $JS_SORT_MIN_GALLOP_WINS || $first_iteration ) {
        $first_iteration = 0;

        $min_gallop = $min_gallop - 1 > 1 ? $min_gallop - 1 : 1;    # SmiMax(1, minGallop - 1)
        $sort_state->{min_gallop} = $min_gallop;

        my $k = $self->_js_sort_gallop_right( $sort_state, $work_array, $temp_array->[$cursor_temp], $base_a, $length_a, $length_a - 1 );
        $nof_wins_a = $length_a - $k;

        if ( $nof_wins_a > 0 ) {
          $dest     = $dest - $nof_wins_a;
          $cursor_a = $cursor_a - $nof_wins_a;
          $self->_js_sort_copy( $work_array, $cursor_a + 1, $work_array, $dest + 1, $nof_wins_a );

          $length_a = $length_a - $nof_wins_a;
          last MERGE if $length_a == 0;
        }
        $work_array->[ $dest-- ] = $temp_array->[ $cursor_temp-- ];
        if ( --$length_b == 1 ) { $goto = 'CopyA'; last MERGE }

        $k = $self->_js_sort_gallop_left( $sort_state, $temp_array, $work_array->[$cursor_a], 0, $length_b, $length_b - 1 );
        $nof_wins_b = $length_b - $k;

        if ( $nof_wins_b > 0 ) {
          $dest        = $dest - $nof_wins_b;
          $cursor_temp = $cursor_temp - $nof_wins_b;
          $self->_js_sort_copy( $temp_array, $cursor_temp + 1, $work_array, $dest + 1, $nof_wins_b );

          $length_b = $length_b - $nof_wins_b;
          if ( $length_b == 1 ) { $goto = 'CopyA'; last MERGE }

          # lengthB == 0 is impossible now if the comparison function is
          # consistent, but we can't assume that it is.
          last MERGE if $length_b == 0;
        }
        $work_array->[ $dest-- ] = $work_array->[ $cursor_a-- ];
        last MERGE if --$length_a == 0;
      }
      ++$min_gallop;
      $sort_state->{min_gallop} = $min_gallop;
    }
  }

  if ( $goto eq 'Succeed' ) {
    $self->_js_sort_copy( $temp_array, 0, $work_array, $dest - ( $length_b - 1 ), $length_b ) if $length_b > 0;
  } else {    # CopyA
    # The first element of run B belongs at the front of the merge.
    $dest     = $dest - $length_a;
    $cursor_a = $cursor_a - $length_a;
    $self->_js_sort_copy( $work_array, $cursor_a + 1, $work_array, $dest + 1, $length_a );
    $work_array->[$dest] = $temp_array->[$cursor_temp];
  }
  return;
}

# Compute a good value for the minimum run length; natural runs shorter than
# this are boosted artificially via binary insertion sort. If n < 64, return n
# (it's too small to bother with fancy stuff). Else if n is an exact power of 2,
# return 32. Else return an int k, 32 <= k <= 64, such that n/k is close to,
# but strictly less than, an exact power of 2.
sub _js_sort_compute_min_run_length {
  my ( $self, $n_arg ) = @_;
  my $n = $n_arg;
  my $r = 0;    # Becomes 1 if any 1 bits are shifted off.

  while ( $n >= 64 ) {
    $r = $r | ( $n & 1 );
    $n = $n >> 1;
  }

  return $n + $r;
}

# Returns true iff run_length(n - 2) > run_length(n - 1) + run_length(n).
sub _js_sort_run_invariant_established {
  my ( $self, $pending_runs, $n ) = @_;
  return 1 if $n < 2;

  my $run_length_n   = $self->_js_sort_get_pending_run_length( $pending_runs, $n );
  my $run_length_nm  = $self->_js_sort_get_pending_run_length( $pending_runs, $n - 1 );
  my $run_length_nmm = $self->_js_sort_get_pending_run_length( $pending_runs, $n - 2 );

  return $run_length_nmm > $run_length_nm + $run_length_n ? 1 : 0;
}

# Examines the stack of runs waiting to be merged, merging adjacent runs until
# the stack invariants are re-established:
#   1. run_length(i - 3) > run_length(i - 2) + run_length(i - 1)
#   2. run_length(i - 2) > run_length(i - 1)
sub _js_sort_merge_collapse {
  my ( $self, $sort_state ) = @_;
  my $pending_runs = $sort_state->{pending_runs};

  # Reload the stack size because MergeAt might change it.
  while ( $self->_js_sort_get_pending_runs_size($sort_state) > 1 ) {
    my $n = $self->_js_sort_get_pending_runs_size($sort_state) - 2;

    if ( !$self->_js_sort_run_invariant_established( $pending_runs, $n + 1 )
      || !$self->_js_sort_run_invariant_established( $pending_runs, $n ) )
    {
      --$n
        if $self->_js_sort_get_pending_run_length( $pending_runs, $n - 1 )
        < $self->_js_sort_get_pending_run_length( $pending_runs, $n + 1 );

      $self->_js_sort_merge_at( $sort_state, $n );
    } elsif ( $self->_js_sort_get_pending_run_length( $pending_runs, $n )
      <= $self->_js_sort_get_pending_run_length( $pending_runs, $n + 1 ) )
    {
      $self->_js_sort_merge_at( $sort_state, $n );
    } else {
      last;
    }
  }
  return;
}

# Regardless of invariants, merge all runs on the stack until only one remains.
# This is used at the end of the mergesort.
sub _js_sort_merge_force_collapse {
  my ( $self, $sort_state ) = @_;
  my $pending_runs = $sort_state->{pending_runs};

  # Reload the stack size because MergeAt might change it.
  while ( $self->_js_sort_get_pending_runs_size($sort_state) > 1 ) {
    my $n = $self->_js_sort_get_pending_runs_size($sort_state) - 2;

    --$n
      if $n > 0
      && $self->_js_sort_get_pending_run_length( $pending_runs, $n - 1 )
      < $self->_js_sort_get_pending_run_length( $pending_runs, $n + 1 );
    $self->_js_sort_merge_at( $sort_state, $n );
  }
  return;
}

sub _js_array_tim_sort_impl {
  my ( $self, $sort_state, $length ) = @_;
  return if $length < 2;
  my $remaining = $length;

  # March over the array once, left to right, finding natural runs, and
  # extending short natural runs to minrun elements.
  my $low            = 0;
  my $min_run_length = $self->_js_sort_compute_min_run_length($remaining);
  while ( $remaining != 0 ) {
    my $current_run_length = $self->_js_sort_count_and_make_run( $sort_state, $low, $low + $remaining );

    # If the run is short, extend it to min(minRunLength, remaining).
    if ( $current_run_length < $min_run_length ) {
      my $forced_run_length = $min_run_length < $remaining ? $min_run_length : $remaining;
      $self->_js_sort_binary_insertion_sort( $sort_state, $low, $low + $current_run_length, $low + $forced_run_length );
      $current_run_length = $forced_run_length;
    }

    # Push run onto pending-runs stack, and maybe merge.
    $self->_js_sort_push_run( $sort_state, $low, $current_run_length );

    $self->_js_sort_merge_collapse($sort_state);

    # Advance to find next run.
    $low       = $low + $current_run_length;
    $remaining = $remaining - $current_run_length;
  }

  $self->_js_sort_merge_force_collapse($sort_state);
  return;
}

# Move all non-undefined elements into the work array and count the undefined
# ones. V8 skips holes here; the Perl value model has none (ADR 0001).
sub _js_sort_compact_receiver_elements_into_work_array {
  my ( $self, $sort_state ) = @_;
  my $receiver        = $sort_state->{receiver};
  my $receiver_length = $sort_state->{initial_receiver_length};
  my $work_array      = $sort_state->{work_array};

  my $number_of_undefined = 0;
  for ( my $i = 0; $i < $receiver_length; ++$i ) {
    my $element = $receiver->[$i];

    if ( !defined($element) ) {
      $number_of_undefined++;
    } else {
      push @$work_array, $element;
    }
  }

  $sort_state->{sort_length}         = $receiver_length;
  $sort_state->{number_of_undefined} = $number_of_undefined;

  return scalar @$work_array;
}

# Writing the elements back is a 3 step process:
#   1. Copy the sorted elements from the workarray to the receiver.
#   2. Add {nOfUndefined} undefineds to the receiver.
#   3. Depending on the backing store either delete properties or set them to
#      the TheHole up to {sortState.sortLength}.
# Without holes the first two steps reach sortLength, so the third has nothing
# to do.
sub _js_sort_copy_work_array_to_receiver {
  my ( $self, $sort_state, $number_of_non_undefined ) = @_;
  my $receiver   = $sort_state->{receiver};
  my $work_array = $sort_state->{work_array};

  my $index = 0;
  for ( ; $index < $number_of_non_undefined; ++$index ) {
    $receiver->[$index] = $work_array->[$index];
  }

  my $number_of_undefined_end = $sort_state->{number_of_undefined} + $number_of_non_undefined;
  for ( ; $index < $number_of_undefined_end; ++$index ) {
    $receiver->[$index] = undef;
  }
  return;
}

sub _js_array_tim_sort {
  my ( $self, $sort_state ) = @_;
  my $number_of_non_undefined = $self->_js_sort_compact_receiver_elements_into_work_array($sort_state);
  $self->_js_array_tim_sort_impl( $sort_state, $number_of_non_undefined );

  # The comparison function or toString might have changed the receiver; V8
  # then writes back through the generic accessor -- the same values.
  $self->_js_sort_copy_work_array_to_receiver( $sort_state, $number_of_non_undefined );
  return;
}

# ArrayPrototypeSort -- https://tc39.github.io/ecma262/#sec-array.prototype.sort
# Sorts $arr in place and returns it; $comparefn undef is JS undefined.
sub js_array_sort {
  my ( $self, $arr, $comparefn ) = @_;

  # 1. If comparefn is not undefined and IsCallable(comparefn) is false, throw
  #    a TypeError exception. (V8 shows the value without side effects.)
  if ( defined($comparefn) && !$self->is_function($comparefn) ) {
    die Text::Nunjucks::Lib::Error->new(
      'The comparison function must be either a function or undefined: '
        . $self->_runtime->_js_no_side_effects_to_string($comparefn),
      name => 'TypeError',
    );
  }

  # 2. Let obj be ? ToObject(this value).
  # 3. Let len be ? ToLength(? Get(obj, "length")).
  my $len = scalar @$arr;

  return $arr if $len < 2;

  my $sort_state = $self->_js_sort_new_sort_state( $arr, $comparefn, $len );
  $self->_js_array_tim_sort($sort_state);

  return $arr;
}

#### js_json_stringify -- JSON.stringify(value, null, space)

# Not a src/lib.js function: the dump filter's JSON.stringify(obj, null,
# spaces) -- ECMAScript's SerializeJSONProperty, SerializeJSONObject,
# SerializeJSONArray and QuoteJSONString over the value model, in their order
# and names, with V8's message for a circular structure. The replacer is null
# at the one call site, so it has no parameter. Returns undef where
# JSON.stringify returns undefined (oracle: u|dump and a macro|dump render '').
#
# The gap is V8's (InitializeGap; oracle, dump(space)): a string's first ten
# UTF-16 code units, an astral character two of them; a number above 0 its
# integer part in spaces, at most ten (1.5 is one, 1/0 ten). V8 departs from
# the spec below 1: a number in (0, 1) has a gap of no spaces that still
# breaks the output into lines, "key": value included (oracle: dump(0.5) is
# "[\n1\n]"). An empty string, a number not above 0 (NaN, -1) and anything
# else -- a boolean, null, an array, an object, keyword arguments, a
# SafeString (no primitive wrapper) -- give no gap.
#
# The values (oracle): undefined and a function serialize to undefined, so a
# property holding one is left out and an array element becomes null; null,
# true and false; a finite number its JS ToString (ADR 0007, -0 is 0), NaN and
# +-Infinity null; a string quoted -- the control characters, '"' and '\'
# escaped, each lone surrogate (ADR 0012) as \uXXXX, U+007F, U+2028, U+2029
# and U+FEFF as they are. An array serializes its elements; any other object
# its own enumerable properties, in keys' order (ADR 0011), each read as
# _entries reads it: a SafeString is {"val": ..., "length": ...}, a regex {}
# (its lastIndex is not enumerable). A callable toJSON member is called with
# the key -- '' at the top, an index as its string -- and its result
# serialized instead (oracle: {'toJSON': m} with a macro m dumps m's
# SafeString output); no prototype the value model reaches has one.
#
# An object met again inside itself throws V8's TypeError, "Converting
# circular structure to JSON" and the circle as V8 prints it (V8 13.6.233.17,
# src/json/json-stringifier.cc: StackPush,
# ConstructCircularStructureErrorMessage, CircularStructureMessageBuilder):
# the object that starts the circle, at most two of the objects after it,
# '...' when more are skipped, the last one, then the key that closes the
# circle -- an index as "index N", a property as "property 'k'", the empty key
# as <anonymous> (oracle). Only arrays and plain objects hold objects, so
# every constructor named is 'Array' or 'Object'. Every join goes through
# js_string_append (ADR 0012): a gap may hold lone surrogates.

my %JS_JSON_ESCAPE = (
  "\x08" => '\b',
  "\t"   => '\t',
  "\n"   => '\n',
  "\f"   => '\f',
  "\r"   => '\r',
  '"'    => '\"',
  '\\'   => '\\\\',
);

# kCircularErrorMessagePrefixCount / kCircularErrorMessagePostfixCount
my $JS_JSON_CIRCULAR_PREFIX_COUNT  = 2;
my $JS_JSON_CIRCULAR_POSTFIX_COUNT = 1;

sub js_json_stringify {
  my ( $self, $value, $space ) = @_;
  my $type = $self->_runtime->_js_type($space);
  # V8's gap_ is a string or none at all; has_gap is "gap_ != nullptr"
  my ( $gap, $has_gap ) = ( '', 0 );
  if ( $type eq 'string' ) {
    $gap     = $self->js_substring( $space, 0, 10 );
    $has_gap = $gap ne '' ? 1 : 0;
  } elsif ( $type eq 'number' ) {
    my $value = $space > 10 ? 10 : $space;    # std::min(value, 10.0); NaN fails both tests
    if ( $value > 0 ) {
      $gap     = ' ' x int($value);           # DoubleToUint32
      $has_gap = 1;
    }
  }

  my $state = { stack => [], indent => '', gap => $gap, has_gap => $has_gap };
  # SerializeJSONProperty(state, '', wrapper) -- wrapper is { '': value }
  return $self->_js_json_serialize_property( $state, '', 0, $value );
}

# $key is the property key as a string; $is_index says it is an array index,
# which V8's circle message prints differently. $value is Get(holder, key).
sub _js_json_serialize_property {
  my ( $self, $state, $key, $is_index, $value ) = @_;
  my $rt = $self->_runtime;

  # 2. If value is an Object, let toJSON be ? GetV(value, "toJSON"); if it is
  #    callable, value = ? Call(toJSON, value, << key >>) -- no this (ADR 0009)
  if ( ref($value) && !$rt->_is_none($value) && !$self->is_function($value) ) {
    my $to_json = $rt->member_lookup( $value, 'toJSON' );
    $value = $to_json->($key) if $self->is_function($to_json);
  }

  return undef if !defined($value) || $self->is_function($value);
  return 'null' if $rt->_is_none($value);
  return ( $value ? 'true' : 'false' ) if is_bool($value);
  return $self->_js_json_quote($value) if $self->is_string($value);
  if ( created_as_number($value) ) {
    return 'null' if $value != $value || $value == $NUM_POS_INF || $value == $NUM_NEG_INF;
    return $self->number_to_string($value);
  }
  return $self->_js_json_serialize_array( $state, $key, $is_index, $value ) if ref($value) eq 'ARRAY';
  return $self->_js_json_serialize_object( $state, $key, $is_index, $value );
}

sub _js_json_quote {
  my ( $self, $s ) = @_;
  # A caller string spelling a pair as two surrogate characters is re-paired
  # first, so both spellings quote alike (ADR 0012); every surrogate character
  # left is a lone one and comes out escaped, so the quotes cannot pair with
  # anything.
  $s = $self->_js_from_units($s);
  return '"' . ( $s =~ s{([\x{0}-\x{1F}"\\\x{D800}-\x{DFFF}])}{ $JS_JSON_ESCAPE{$1} // sprintf( '\\u%04x', ord $1 ) }ger ) . '"';
}

sub _js_json_serialize_object {
  my ( $self, $state, $key, $is_index, $value ) = @_;
  $self->_js_json_stack_push( $state, $key, $is_index, $value );
  my $stepback = $state->{indent};
  $self->js_string_append( $state->{indent}, $state->{gap} );

  my @partial;
  for my $p ( @{ $self->keys($value) } ) {
    my $str_p = $self->_js_json_serialize_property( $state, $p, 0, $self->_own_value( $value, $p ) );
    next unless defined $str_p;
    my $member = $self->_js_json_quote($p) . ':';
    $member .= ' ' if $state->{has_gap};
    $self->js_string_append( $member, $str_p );
    push @partial, $member;
  }

  my $final = $self->_js_json_final( $state, '{', '}', \@partial, $stepback );
  pop @{ $state->{stack} };
  $state->{indent} = $stepback;
  return $final;
}

sub _js_json_serialize_array {
  my ( $self, $state, $key, $is_index, $value ) = @_;
  $self->_js_json_stack_push( $state, $key, $is_index, $value );
  my $stepback = $state->{indent};
  $self->js_string_append( $state->{indent}, $state->{gap} );

  my @partial;
  my $len = scalar @$value;
  for my $index ( 0 .. $len - 1 ) {
    my $str_p = $self->_js_json_serialize_property( $state, "$index", 1, $value->[$index] );
    push @partial, defined($str_p) ? $str_p : 'null';
  }

  my $final = $self->_js_json_final( $state, '[', ']', \@partial, $stepback );
  pop @{ $state->{stack} };
  $state->{indent} = $stepback;
  return $final;
}

# The final string SerializeJSONObject and SerializeJSONArray both build.
sub _js_json_final {
  my ( $self, $state, $open, $close, $partial, $stepback ) = @_;
  return $open . $close unless @$partial;
  my $separator = ',';
  my $final     = $open;
  if ( $state->{has_gap} ) {
    $separator = ",\n";
    $self->js_string_append( $separator, $state->{indent} );
    $self->js_string_append( $final, "\n" );
    $self->js_string_append( $final, $state->{indent} );
  }
  for my $i ( 0 .. $#$partial ) {
    $self->js_string_append( $final, $separator ) if $i > 0;
    $self->js_string_append( $final, $partial->[$i] );
  }
  if ( $state->{has_gap} ) {
    $self->js_string_append( $final, "\n" );
    $self->js_string_append( $final, $stepback );
  }
  $self->js_string_append( $final, $close );
  return $final;
}

# If state.[[Stack]] contains value, throw a TypeError; else append it.
sub _js_json_stack_push {
  my ( $self, $state, $key, $is_index, $value ) = @_;
  my $stack = $state->{stack};
  for my $i ( 0 .. $#$stack ) {
    die $self->_js_json_circular_error( $stack, $key, $is_index, $i ) if refaddr( $stack->[$i][2] ) == refaddr($value);
  }
  push @$stack, [ $key, $is_index, $value ];
  return;
}

sub _js_json_circular_error {
  my ( $self, $stack, $last_key, $last_is_index, $start_index ) = @_;
  my $index      = $start_index;
  my $stack_size = scalar @$stack;

  my $message = 'Converting circular structure to JSON';
  $self->js_string_append( $message,
    "\n    --> starting at object with constructor " . $self->_js_json_constructor_name( $stack->[ $index++ ][2] ) );

  # Append a maximum of kCircularErrorMessagePrefixCount normal lines.
  my $prefix_end = $index + $JS_JSON_CIRCULAR_PREFIX_COUNT;
  $prefix_end = $stack_size if $stack_size < $prefix_end;
  for ( ; $index < $prefix_end; ++$index ) {
    $self->_js_json_circular_normal_line( $message, $stack->[$index] );
  }

  # If the circle consists of too many objects, we skip them and just print
  # an ellipsis.
  $self->js_string_append( $message, "\n    |     ..." ) if $stack_size > $index + $JS_JSON_CIRCULAR_POSTFIX_COUNT;

  # The postfix lines count from the back of the stack; none is printed twice.
  my $postfix_start = $stack_size - $JS_JSON_CIRCULAR_POSTFIX_COUNT;
  $index = $postfix_start if $index < $postfix_start;
  for ( ; $index < $stack_size; ++$index ) {
    $self->_js_json_circular_normal_line( $message, $stack->[$index] );
  }

  $self->js_string_append( $message, "\n    --- " );
  $self->js_string_append( $message, $self->_js_json_circular_key( $last_key, $last_is_index ) );
  $self->js_string_append( $message, ' closes the circle' );
  return Text::Nunjucks::Lib::Error->new( $message, name => 'TypeError' );
}

# Appends to the caller's message ($_[1], aliased).
sub _js_json_circular_normal_line {
  my ( $self, undef, $entry ) = @_;
  $self->js_string_append( $_[1], "\n    |     " );
  $self->js_string_append( $_[1], $self->_js_json_circular_key( $entry->[0], $entry->[1] ) );
  $self->js_string_append( $_[1], ' -> object with constructor ' . $self->_js_json_constructor_name( $entry->[2] ) );
  return;
}

sub _js_json_circular_key {
  my ( $self, $key, $is_index ) = @_;
  return 'index ' . $key if $is_index;
  return '<anonymous>' if $key eq '';
  my $text = "property '";
  $self->js_string_append( $text, $key );
  $self->js_string_append( $text, "'" );
  return $text;
}

sub _js_json_constructor_name {
  my ( $self, $object ) = @_;
  return ref($object) eq 'ARRAY' ? "'Array'" : "'Object'";
}

#### node built-ins -- path, fs, console (ADR 0018)

# Not src/lib.js functions: the one home of the node built-ins the loaders call
# -- src/loader.js's path.resolve / path.dirname, src/node-loaders.js's
# path.normalize, path.resolve, fs.existsSync, fs.readFileSync(p, 'utf-8') and
# console.log -- next to the JS built-ins above. As the oracle's node
# (v24.19.0) has them, posix flavour: the separator is '/' and only '/', a
# backslash is an ordinary character (ADR 0018). Source: node's lib/path.js as
# that node reports it (posix.resolve / normalize / dirname and
# normalizeString), pinned by t/data/node-builtins.json
# (maint/node-builtins-fixtures). The path functions are lexical -- '..' and
# '.' collapse on the string, the file system is never asked, symlinks stay as
# they are -- and only resolve reads the process's working directory. Each
# checks its arguments first, as node's do (_node_validate_string): anything
# but a string throws node's ERR_INVALID_ARG_TYPE, a TypeError -- a search path
# is whatever the caller passed FileSystemLoader.

# process.cwd() -- the working directory as the system reports it (getcwd(3),
# as libuv's uv_cwd), physical, no trailing '/'.
sub node_process_cwd { return Cwd::getcwd() }

# path.resolve(...args) -- the shortcut compares strictly (===), so only a
# string is the cwd there; the loop validates each argument it reaches, from
# the last one back to the first absolute one (node: resolve(5, '/a') is '/a').
sub node_path_resolve {
  my ( $self, @args ) = @_;
  if ( @args == 0 || ( @args == 1 && ( $self->_strict_eq( $args[0], '' ) || $self->_strict_eq( $args[0], '.' ) ) ) ) {
    my $cwd = $self->node_process_cwd;
    if ( substr( $cwd, 0, 1 ) eq '/' ) {
      return $cwd;
    }
  }
  my $resolved_path     = '';
  my $resolved_absolute = 0;

  for ( my $i = $#args; $i >= 0 && !$resolved_absolute; $i-- ) {
    my $path = $args[$i];
    $self->_node_validate_string( $path, 'paths[' . $i . ']' );

    # Skip empty entries
    if ( length($path) == 0 ) {
      next;
    }

    $resolved_path     = $path . '/' . $resolved_path;
    $resolved_absolute = substr( $path, 0, 1 ) eq '/' ? 1 : 0;
  }

  if ( !$resolved_absolute ) {
    my $cwd = $self->node_process_cwd;
    $resolved_path     = $cwd . '/' . $resolved_path;
    $resolved_absolute = substr( $cwd, 0, 1 ) eq '/' ? 1 : 0;
  }

  # At this point the path should be resolved to a full absolute path, but
  # handle relative paths to be safe (might happen when process.cwd() fails)

  # Normalize the path
  $resolved_path = $self->_node_normalize_string( $resolved_path, !$resolved_absolute );

  if ($resolved_absolute) {
    return '/' . $resolved_path;
  }
  return length($resolved_path) > 0 ? $resolved_path : '.';
}

# path.normalize(path)
sub node_path_normalize {
  my ( $self, $path ) = @_;
  $self->_node_validate_string( $path, 'path' );

  return '.' if length($path) == 0;

  my $is_absolute        = substr( $path, 0, 1 ) eq '/';
  my $trailing_separator = substr( $path, -1 ) eq '/';

  # Normalize the path
  $path = $self->_node_normalize_string( $path, !$is_absolute );

  if ( length($path) == 0 ) {
    return '/' if $is_absolute;
    return $trailing_separator ? './' : '.';
  }
  $path .= '/' if $trailing_separator;

  return $is_absolute ? '/' . $path : $path;
}

# path.dirname(path)
sub node_path_dirname {
  my ( $self, $path ) = @_;
  $self->_node_validate_string( $path, 'path' );
  return '.' if length($path) == 0;
  my $has_root      = substr( $path, 0, 1 ) eq '/';
  my $end           = -1;
  my $matched_slash = 1;
  for ( my $i = length($path) - 1; $i >= 1; --$i ) {
    if ( substr( $path, $i, 1 ) eq '/' ) {
      if ( !$matched_slash ) {
        $end = $i;
        last;
      }
    }
    else {
      # We saw the first non-path separator
      $matched_slash = 0;
    }
  }

  return $has_root ? '/' : '.' if $end == -1;
  return '//' if $has_root && $end == 1;
  return substr( $path, 0, $end );
}

# normalizeString(path, allowAboveRoot, separator, isPathSeparator) -- the
# posix call, separator '/' and isPosixPathSeparator, fixed. Resolves . and ..
# elements in a path with directory names. Counts characters where node counts
# UTF-16 code units: the counts only ever measure the segments between two
# separators, and a surrogate is never a '/' or a '.', so both cut the same.
sub _node_normalize_string {
  my ( $self, $path, $allow_above_root ) = @_;
  my $res                 = '';
  my $last_segment_length = 0;
  my $last_slash          = -1;
  my $dots                = 0;
  my $code                = '';
  for ( my $i = 0; $i <= length($path); ++$i ) {
    if ( $i < length($path) ) {
      $code = substr( $path, $i, 1 );
    }
    elsif ( $code eq '/' ) {
      last;
    }
    else {
      $code = '/';
    }

    if ( $code eq '/' ) {
      if ( $last_slash == $i - 1 || $dots == 1 ) {
        # NOOP
      }
      elsif ( $dots == 2 ) {
        if ( length($res) < 2
          || $last_segment_length != 2
          || substr( $res, -1, 1 ) ne '.'
          || substr( $res, -2, 1 ) ne '.' )
        {
          if ( length($res) > 2 ) {
            my $last_slash_index = length($res) - $last_segment_length - 1;
            if ( $last_slash_index == -1 ) {
              $res                 = '';
              $last_segment_length = 0;
            }
            else {
              $res                 = substr( $res, 0, $last_slash_index );
              $last_segment_length = length($res) - 1 - rindex( $res, '/' );
            }
            $last_slash = $i;
            $dots       = 0;
            next;
          }
          elsif ( length($res) != 0 ) {
            $res                 = '';
            $last_segment_length = 0;
            $last_slash          = $i;
            $dots                = 0;
            next;
          }
        }
        if ($allow_above_root) {
          $res .= length($res) > 0 ? '/..' : '..';
          $last_segment_length = 2;
        }
      }
      else {
        if ( length($res) > 0 ) {
          $res .= '/' . substr( $path, $last_slash + 1, $i - $last_slash - 1 );
        }
        else {
          $res = substr( $path, $last_slash + 1, $i - $last_slash - 1 );
        }
        $last_segment_length = $i - $last_slash - 1;
      }
      $last_slash = $i;
      $dots       = 0;
    }
    elsif ( $code eq '.' && $dots != -1 ) {
      ++$dots;
    }
    else {
      $dots = -1;
    }
  }
  return $res;
}

# validateString(value, name) -- node's lib/internal/validators.js: anything
# but a string throws ERR_INVALID_ARG_TYPE(name, 'string', value), a TypeError
# (Lib::Error, ADR 0010) whose message lib/internal/errors.js builds. Only the
# shape the path functions' names take is ported: 'path' and 'paths[i]' end
# in no ' argument' and hold no '.', so node writes `The "<name>" argument`.
# Measured in node: `The "path" argument must be of type string. Received
# null`, `The "paths[1]" argument ... Received type number (5)`.
sub _node_validate_string {
  my ( $self, $value, $name ) = @_;
  return if $self->is_string($value);
  die Text::Nunjucks::Lib::Error->new(
    'The "' . $name . '" argument must be of type string. Received ' . $self->_node_determine_specific_type($value),
    name => 'TypeError',
  );
}

# determineSpecificType(value) -- how node's ERR_INVALID_ARG_TYPE shows the
# value it got, over the kinds the port models (none is a string here, and
# bigint and symbol have no Perl image). Measured in node: null, undefined,
# 'type number (5)', '(-0)', '(NaN)', '(Infinity)', '(1e+21)', 'type boolean
# (true)', 'function <name>' -- a Perl coderef has no name (k88), so
# 'function ', as an anonymous JS function. An object shows its constructor's
# name: an array 'an instance of Array', a regex 'RegExp', a SafeString
# 'String' (SafeString.prototype has no constructor of its own, String's is
# inherited), a dict, caller hash or keyword arguments 'Object'. A plain
# object with an own 'constructor' member is shown through that member, as
# node reads value.constructor: a function by its name (a coderef's is '',
# where JS names a function written as a member after it: 'an instance of
# constructor'), an object by its own 'name' ({'constructor': {'name':
# 'Foo'}} -> 'an instance of Foo'); anything
# else falsy or nameless is util.inspect(value, { depth: -1 }), '[Object]';
# a truthy primitive cannot be searched with `in` and V8 throws ("Cannot use
# 'in' operator to search for 'name' in 1"). Any other blessed object is a
# plain object to the port (ADR 0016): 'an instance of Object', the port's
# choice -- it has no JS counterpart to measure.
sub _node_determine_specific_type {
  my ( $self, $value ) = @_;
  my $rt = $self->_runtime;
  if ( $rt->_is_none($value) ) {
    return 'null';
  }
  elsif ( !defined($value) ) {
    return 'undefined';
  }

  my $type = $self->is_function($value) ? 'function' : $rt->_js_type($value);

  if ( $type eq 'number' ) {
    if ( $value == 0 ) {
      return $rt->op_div( 1, $value ) == $NUM_NEG_INF ? 'type number (-0)' : 'type number (0)';
    }
    elsif ( $value != $value ) {
      return 'type number (NaN)';
    }
    elsif ( $value == $NUM_POS_INF ) {
      return 'type number (Infinity)';
    }
    elsif ( $value == $NUM_NEG_INF ) {
      return 'type number (-Infinity)';
    }
    return 'type number (' . $self->number_to_string($value) . ')';
  }
  if ( $type eq 'boolean' ) {
    return $value ? 'type boolean (true)' : 'type boolean (false)';
  }
  if ( $type eq 'function' ) {
    return 'function ' . $rt->_js_function_name($value);
  }

  # 'object': value.constructor && 'name' in value.constructor
  return 'an instance of Array'  if $self->is_array($value);
  return 'an instance of RegExp' if $rt->_is_regex($value);
  return 'an instance of String' if $rt->_is_safe_string($value);
  return 'an instance of Object' unless $self->has_own_prop( $value, 'constructor' );
  my $ctor = $self->_own_value( $value, 'constructor' );
  if ( $rt->_truthy($ctor) ) {
    die Text::Nunjucks::Lib::Error->new(
      "Cannot use 'in' operator to search for 'name' in " . $rt->_js_to_string($ctor),
      name => 'TypeError',
    ) unless ref($ctor);
    return 'an instance of ' . $rt->_js_function_name($ctor) if $self->is_function($ctor);
    return 'an instance of ' . $rt->_js_to_string( $rt->member_lookup( $ctor, 'name' ) )
      if $self->has_own_prop( $ctor, 'name' );
  }
  return '[Object]';
}

# fs.existsSync(path) -- true if the path exists, a directory as well; false,
# never an exception, for anything node cannot look up (a name with a NUL is
# an invalid argument to node, and so false). node hands the system the
# path's UTF-8 bytes, whatever its characters; so does this.
sub node_fs_exists_sync {
  my ( $self, $path ) = @_;
  return 0 if index( $path, "\0" ) >= 0;
  my $bytes = $self->_node_fs_path_bytes($path);
  return -e $bytes ? 1 : 0;
}

# fs.readFileSync(path, 'utf-8') -- the file's bytes, decoded as node decodes
# UTF-8 (_node_utf8_decode: a BOM stays a U+FEFF, malformed bytes become
# U+FFFD), per ADR 0012's I/O contract. A failure throws node's error, an
# Error whose message is libuv's '<CODE>: <description>, <syscall>' -- the
# path, as given, follows an open: "EISDIR: illegal operation on a directory,
# read" for a directory, "EACCES: permission denied, open '<path>'" for a file
# that cannot be read, "ENOENT: no such file or directory, open '<path>'" for
# a dangling symlink (measured in node). A plain open and read, as node's
# open(2) and read(2), not Path::Tiny: its slurp takes flock(LOCK_SH) first,
# which blocks while another process holds LOCK_EX (node reads at once) and
# fails where flock is not supported. Each failure is that syscall's errno.
sub node_fs_read_file_sync_utf8 {
  my ( $self, $path ) = @_;
  open( my $fh, '<:raw', $self->_node_fs_path_bytes($path) )
    or die $self->_node_uv_exception( $! + 0, 'open', $path );
  my $bytes = '';
  while (1) {
    my $n = read( $fh, $bytes, 65536, length($bytes) );
    die $self->_node_uv_exception( $! + 0, 'read' ) unless defined $n;
    last if $n == 0;
  }
  close($fh);
  return $self->_node_utf8_decode($bytes);
}

sub _node_fs_path_bytes {
  my ( $self, $path ) = @_;
  my $bytes = $path;
  utf8::encode($bytes);
  return $bytes;
}

# libuv's error descriptions (uv_strerror) for the errors a read of an existing
# path can meet, as node's util.getSystemErrorMap() lists them. Any other
# errno keeps libuv's message shape with the system's own text, lowercased.
my %NODE_UV_ERROR_MESSAGE = (
  EACCES => 'permission denied',
  EIO    => 'i/o error',
  EISDIR => 'illegal operation on a directory',
  EMFILE => 'too many open files',
  ENFILE => 'file table overflow',
  ENOENT => 'no such file or directory',
  EPERM  => 'operation not permitted',
);

# libuv's name for an errno the system knows by two (util.getSystemErrorMap()
# lists EAGAIN and ENOTSUP, never EWOULDBLOCK or EOPNOTSUPP); any other errno
# with two names (EDEADLK / EDEADLOCK, not in libuv's map) takes the first in
# sort order, so the code never depends on hash order.
my %NODE_UV_ERRNO_ALIAS = (
  EOPNOTSUPP  => 'ENOTSUP',
  EWOULDBLOCK => 'EAGAIN',
);

# node's uvException: `${code}: ${message}, ${syscall}` plus ` '${path}'`.
sub _node_uv_exception {
  my ( $self, $errno, $syscall, $path ) = @_;
  local $! = $errno;
  my $strerror = "$!";
  my ($code) = sort { $a cmp $b } CORE::map { $NODE_UV_ERRNO_ALIAS{$_} // $_ } grep { $!{$_} } CORE::keys %!;
  $code //= 'UNKNOWN';
  my $message = $code . ': ' . ( $NODE_UV_ERROR_MESSAGE{$code} // lc $strerror ) . ', ' . $syscall;
  $message .= " '" . $path . "'" if defined $path;
  return Text::Nunjucks::Lib::Error->new($message);
}

# node's UTF-8 decoder, the WHATWG Encoding Standard's: a BOM is kept (a
# U+FEFF character, oracle: a file starting EF BB BF renders U+FEFF first),
# and every maximal subpart of an ill-formed sequence becomes one U+FFFD --
# a lead byte with the continuation bytes that can still follow it, else a
# single byte (oracle: C0 80 -> two, ED A0 80 -> three, F4 90 80 80 -> four,
# E2 82 'b' -> one and 'b'). Perl's own strict decoder replaces differently
# (one U+FFFD for each of those) and refuses noncharacters such as U+10FFFF,
# which node decodes. Well-formed input -- what Perl's lax utf8::decode
# accepts, minus surrogates and code points past U+10FFFF -- decodes in one
# step; anything else runs the standard's decoder, byte by byte.
sub _node_utf8_decode {
  my ( $self, $bytes ) = @_;
  my $str = $bytes;
  return $str if utf8::decode($str) && $str !~ /[\x{D800}-\x{DFFF}]|[^\x{0}-\x{10FFFF}]/;

  # Encoding Standard, 8.1.1 UTF-8 decoder (error mode replacement).
  my $out             = '';
  my $code_point      = 0;
  my $bytes_seen      = 0;
  my $bytes_needed    = 0;
  my $lower_boundary  = 0x80;
  my $upper_boundary  = 0xBF;
  my $i               = 0;
  my $n               = length($bytes);
  while (1) {
    if ( $i >= $n ) {
      # end-of-queue
      $out .= "\x{FFFD}" if $bytes_needed != 0;
      last;
    }
    my $byte = ord( substr( $bytes, $i, 1 ) );
    if ( $bytes_needed == 0 ) {
      $i++;
      if ( $byte <= 0x7F ) {
        $out .= chr($byte);
      }
      elsif ( $byte >= 0xC2 && $byte <= 0xDF ) {
        $bytes_needed = 1;
        $code_point   = $byte & 0x1F;
      }
      elsif ( $byte >= 0xE0 && $byte <= 0xEF ) {
        $lower_boundary = 0xA0 if $byte == 0xE0;
        $upper_boundary = 0x9F if $byte == 0xED;
        $bytes_needed   = 2;
        $code_point     = $byte & 0xF;
      }
      elsif ( $byte >= 0xF0 && $byte <= 0xF4 ) {
        $lower_boundary = 0x90 if $byte == 0xF0;
        $upper_boundary = 0x8F if $byte == 0xF4;
        $bytes_needed   = 3;
        $code_point     = $byte & 0x7;
      }
      else {
        $out .= "\x{FFFD}";
      }
      next;
    }
    if ( $byte < $lower_boundary || $byte > $upper_boundary ) {
      # the byte is not consumed: it is read again as the start of what follows
      ( $code_point, $bytes_needed, $bytes_seen ) = ( 0, 0, 0 );
      ( $lower_boundary, $upper_boundary ) = ( 0x80, 0xBF );
      $out .= "\x{FFFD}";
      next;
    }
    $i++;
    ( $lower_boundary, $upper_boundary ) = ( 0x80, 0xBF );
    $code_point = ( $code_point << 6 ) | ( $byte & 0x3F );
    $bytes_seen++;
    next if $bytes_seen != $bytes_needed;
    $out .= chr($code_point);
    ( $code_point, $bytes_needed, $bytes_seen ) = ( 0, 0, 0 );
  }
  return $out;
}

# console.log(message) -- one line on standard output. The port's only caller
# passes one string, whose util.format is the string itself.
sub node_console_log {
  my ( $self, $message ) = @_;
  print {*STDOUT} $message . "\n";
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Lib - 1:1 port of Nunjucks src/lib.js -- foundation utilities and escaping

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A 1:1 port of Nunjucks C<src/lib.js>: the foundation utilities (C<keys>, C<extend>,
C<is_array>, C<async_iter> and the like), the HTML escaping, and the Node.js
C<path>, C<fs> and C<console> functions the loaders call, as lexical POSIX
ports (ADR 0018). Called as class methods. The error classes of C<lib.js> are
L<Text::Nunjucks::Lib::TemplateError> and L<Text::Nunjucks::Lib::Error>.

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
