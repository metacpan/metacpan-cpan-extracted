package WARC::Fields;						# -*- CPerl -*-

use strict;
use warnings;

use Carp;
use Encode;
use Scalar::Util;

our @ISA = qw();

use WARC; *WARC::Fields::VERSION = \$WARC::VERSION;

=head1 NAME

WARC::Fields - WARC record headers and application/warc-fields

=head1 SYNOPSIS

  require WARC::Fields;

  $f = new WARC::Fields;
  $f = $record->fields;			# get WARC record headers
  $g = $f->clone;			# make writable copy

  $g->set_readonly;			# make read-only

  $f->field('WARC-Type' => 'metadata');	# set
  $value = $f->field('WARC-Type');	# get

  $fields_text = $f->as_string;		# get WARC header lines for display
  $fields_block = $f->as_block;		# format for WARC file

  tie @field_names, ref $f, $f;		# bind ordered list of field names

  tie %fields, ref $f, $f;		# bind hash of field names => values

  $entry = $f->[$num];			# tie an anonymous array and access it
  $value = $f->{$name};			# likewise with an anonymous tied hash

  $name = "$entry";			# tied array returns objects
  $value = $entry->value;		# one specific value
  $offset = $entry->offset;		# N of M with same name

  foreach (keys %{$f}) { ... }		# iterate over names, in order

=cut

use overload '@{}' => \&_as_tied_array, '%{}' => \&_as_tied_hash;
use overload fallback => 1;

# This implementation uses column-oriented storage, with an array as the
#  underlying object and constants to select array offsets.
#
# The NAMES and VALUES columns are always valid, but the MVOFF and INDEX
#  positions may be undefined and are lazily rebuilt when needed.

use constant { NAMES => 0, VALUES => 1, MVOFF => 2,
		 INDEX => 3, IS_RO => 4, C_TA => 5, C_TH => 6 };
use constant OBJECT_INDEX => qw/NAMES VALUES MVOFF INDEX IS_RO/;
use constant OBJECT_INIT => undef, undef, undef, undef, 0, undef, undef;

sub DESTROY { my $ob = shift;
	      untie @{$$ob->[C_TA]} if defined $$ob->[C_TA];
	      untie %{$$ob->[C_TH]} if defined $$ob->[C_TH];
	      our $_total_destroyed;	$_total_destroyed++ }

# NAMES:	array of field names, exactly as written
# VALUES:	array of field values
# MVOFF:	array of offsets for multiple-valued fields
# INDEX:	hash of case-folded field names to array of row numbers
# IS_RO:	boolean:  TRUE if this object is read-only

# C_TA:		cache: tied array for array dereference
# C_TH:		cache: tide hash for hash dereference

sub _rebuild_INDEX {
  my $self = shift;
  my %idx = ();

  for (my $i = 0; $i < @{$$self->[NAMES]}; $i++) {
    push @{$idx{lc $$self->[NAMES][$i]}}, $i;
  }

  $$self->[INDEX] = \%idx;
}

sub _update_INDEX {
  my $self = shift;	# INDEX slot must be valid
  my $base = shift;	# row number where an insertion or removal was made
  my $count = shift;	# how many rows were inserted (+) or removed (-)

  my %done = ();

  for (my $i = ($base < 0) ? 0 : $base; $i < @{$$self->[NAMES]}; $i++) {
    my $key = lc $$self->[NAMES][$i];
    next if $done{$key};
    @{$$self->[INDEX]{$key}} =
      map { $_ + ($_ > $base ? $count : 0) } @{$$self->[INDEX]{$key}};
    $done{$key}++;
  }
}

sub _rebuild_MVOFF {
  my $self = shift;

  my @mvoff = ();#(undef) x scalar @{$$self->[NAMES]};
  my %cidx = (); # counted index; references to unique entries

  foreach my $name (@{$$self->[NAMES]}) {
    my $key = lc $name;
    if (not defined $cidx{$key}) {
      # first time this key is seen
      push @mvoff, undef;
      $cidx{$key} = \$mvoff[$#mvoff];
    } elsif (ref $cidx{$key} eq 'SCALAR') {
      # second time this key is seen
      push @mvoff, 1;
      ${$cidx{$key}} = 0;	# replace undefined value
      $cidx{$key} = 2;		# prepare counter
    } else {
      # third or later time this key is seen
      push @mvoff, $cidx{$key}++;
    }
  }

  $$self->[MVOFF] = \@mvoff;
}

sub _dbg_dump {
  my $self = shift;

  my @mvoff = (' ') x @{$$self->[NAMES]};
  @mvoff = map { defined $_ ? $_ : 'U' }
    @{$$self->[MVOFF]}[0 .. $#{$$self->[NAMES]}]
      if defined $$self->[MVOFF];
  my @widths = map {length} qw/ROW MVO NAME/;

  foreach my $row (0 .. $#{$$self->[NAMES]}) {
    $widths[0] = length $row if length $row > $widths[0];
    $widths[1] = length $mvoff[$row] if length $mvoff[$row] > $widths[1];
    $widths[2] = length $$self->[NAMES][$row]
      if length $$self->[NAMES][$row] > $widths[2];
  }

  my $out = sprintf ' %4$*1$s %5$*2$s %6$*3$s  %7$s', @widths,
    qw/ ROW MVO NAME VALUE /;
  $out .= "\n".('=' x length $out)."\n";
  $out .= join "\n", map
    { sprintf ' %4$*1$d %5$*2$s %6$*3$s%7$1s %8$s', @widths,
	($_, $mvoff[$_], $$self->[NAMES][$_],
	 (defined $$self->[VALUES][$_] ? ':' : ' '),
	 (defined $$self->[VALUES][$_] ? $$self->[VALUES][$_] : '*deleted*')) }
      0 .. $#{$$self->[NAMES]};

  return $out;
}

# From RFC2616:
#	CTL	        = <any US-ASCII control character
#			   (octets 0 - 31) and DEL (127)>
#	LWS		= [CRLF] 1*( SP | HT )
#	separators	= "(" | ")" | "<" | ">" | "@"
#			| "," | ";" | ":" | "\" | <">
#			| "/" | "[" | "]" | "?" | "="
#			| "{" | "}" | SP | HT
my $PARSE_RE__LWS =		qr/(?:\015\012)?[ \t]+/;
my $PARSE_RE__separator =	qr[[][)(><}{@,;:/"\\?=[:space:]]];
my $PARSE_RE__not_separator =	qr[[^][)(><}{@,;:/"\\?=[:space:]]];

# From WARC specification:
#	field-name = token
#	token = 1*<any US-ASCII character
#		   except CTLs or separators>
my $PARSE_RE__token = qr/[!#$%'*+-.0-9A-Z^_`a-z|~]+/;

=head1 DESCRIPTION

The C<WARC::Fields> class encapsulates information in the
"application/warc-fields" format used for WARC record headers.  This is a
simple key-value format closely analogous to HTTP headers, however
differences are significant enough that the C<HTTP::Headers> class cannot
be reliably reused for WARC fields.

Instances of this class are usually created as member variables of the
C<WARC::Record> class, but can also be returned as the content of WARC
records with Content-Type "application/warc-fields".

Instances of C<WARC::Fields> retrieved from WARC files are read-only and
will croak() if any attempt is made to change their contents.

This class strives to faithfully represent the contents of a WARC file,
while providing a simple interface to answer simple questions.

=head2 Multiple Values

Most WARC headers may only appear once and with a single value in valid
WARC records, with the notable exception of the WARC-Concurrent-To header.
C<WARC::Fields> neither attempts to enforce nor relies upon this
constraint.  Headers that appear multiple times are considered to have
multiple values.  When iterating a tied hash, all values of a recurring
header are collected and returned with the B<first> occurrence of its key.

Multiple values are returned from the C<field> method and tied hash
interface as array references, and are set by passing in an array
reference.  Existing rows are reused where possible when updating a field
with multiple values.  If the new array reference contains fewer items
(including the special case of replacing multiple values with a single
value) excess rows are deleted.  If the new array reference requires
additional rows to be inserted, they are inserted immediately after the
last existing row for a field, with the same name case as that row.

Precise control of the layout is available using the tied array interface,
but the ordering of the header rows is not constrained in the WARC
specification.

=head2 Field Name Mangling

As with C<HTTP::Headers>, the '_' character is converted to '-' in field
names unless the first character of the name is ':', which cannot itself
appear in a field name.  Unlike C<HTTP::Headers>, the leading ':' is
stripped off immediately and the name stored otherwise exactly as given.
The C<field> method and tied hash interface allow this convenience feature.
The field names exposed via the tied array interface are reported
B<exactly> as they appear in the WARC file.

Strictly, "X-Crazy-Header" and "X_Crazy_Header" are two B<different>
headers that the above convenience mechanism conflates.  The solution is
simple: if (and only if) a header field B<already exists> with the B<exact>
name given, it is used, otherwise C<s/_/-/g> occurs and the name is
rechecked for another exact match.  If no match is found, case is folded
and a third check performed.  If a match is found, the existing header is
updated, otherwise a new header is created with character case as given.

The WARC specification specifically states that field names are
case-insensitive, accordingly, "X-Crazy-Header" and "X-CRAZY-HeAdEr" are
considered the same header for the C<field> method and tied hash interface.
They will appear exactly as given in the tied array interface, however.

=cut

# This function handles two different canonicalizations:
#  (1) case folding as required by the WARC specification
#  (2) convenience translation s/_/-/g,
#     (2a) suppressed if m/^:/, which is removed
#     (2b) overridden by an exact match
# To make this work:
#  --- all keys in INDEX are case-folded
#  --- all keys in NAMES preserve case
#  --- existing keys are case-folded by this function
#  --- new keys translate s/_/-/g but preserve case
sub _find_key {
  my $self = shift;	# INDEX slot must be valid
  my $k = shift;
  my $key; ($key = $k) =~ s/^://;
  my $pad = $key;
  my $is_quoted = ($k =~ m/^:/);

  # exact case-folded match?
  return lc $key if defined $$self->[INDEX]{lc $key};

  # case-folded match after s/_/-/g?
  $pad =~ s/_/-/g;
  return lc $pad if defined $$self->[INDEX]{lc $pad} && !$is_quoted;

  # not found ==> a new key will be made
  return $is_quoted ? $key : $pad;
}

# called only if there is no or one current value
sub _set_single_value {
  my $self = shift;	# INDEX slot must be valid
  my $key = shift;	# as returned from _find_key
  my $value = shift;

  croak "attempt to modify read-only object" if $$self->[IS_RO];

  unless (defined $$self->[INDEX]{lc $key}) {
    # insert new key
    push @{$$self->[NAMES]}, $key;	# preserve original key
    $key = lc $key;			# fold key case
    push @{$$self->[INDEX]{$key}}, $#{$$self->[NAMES]};
  }

  $$self->[VALUES][$$self->[INDEX]{$key}[0]] = $value;
}

sub _key_multiple_value_p {
  my $self = shift;	# INDEX slot must be valid
  my $key = shift;	# as returned from _find_key

  # For this to be true, the key must already exist, which means that
  # _find_key has case-folded it already.
  return (defined $$self->[INDEX]{$key}
	  && 1 < scalar @{$$self->[INDEX]{$key}})
}

# called in all cases where multiple values are involved
sub _set_multiple_value {
  my $self = shift;	# INDEX slot must be valid
  my $key = shift;	# as returned from _find_key
  my $value_aref = shift;

  croak "attempt to modify read-only object" if $$self->[IS_RO];

  my $cur_count = (defined $$self->[INDEX]{$key}
		   && scalar @{$$self->[INDEX]{$key}});
  my $new_count = scalar @$value_aref;

  unless ($cur_count) {
    # insert new key
    push @{$$self->[NAMES]}, $key;	# preserve original key
    push @{$$self->[VALUES]}, undef;	# prepare slot
    $key = lc $key;			# fold key case
    push @{$$self->[INDEX]{$key}}, $#{$$self->[NAMES]};
    $cur_count = 1;			# account for the added slot
  }
  # $key is always case-folded at this point

  # adjust table to accommodate new number of values
  if ($cur_count > $new_count) {
    # remove extra rows
    foreach my $extra_row (reverse sort
			   splice @{$$self->[INDEX]{$key}}, $new_count) {
      splice @{$$self->[NAMES]}, $extra_row, 1;
      splice @{$$self->[VALUES]}, $extra_row, 1;
      _update_INDEX($self, $extra_row, -1);
    }
    # special case:  removing a field entirely
    if ($new_count == 0) {
      # This is here to catch a hypothetical bug before data is corrupted.
      die "stray INDEX entries left after removing field"
	# uncoverable branch true
	unless scalar @{$$self->[INDEX]{$key}} == 0;
      delete $$self->[INDEX]{$key};
    }
  } elsif ($cur_count < $new_count) {
    # add more rows
    my $last_row = $$self->[INDEX]{$key}[-1];
    my $new_rows = $new_count - $cur_count;
    _update_INDEX($self, $last_row, $new_rows);
    splice @{$$self->[NAMES]}, 1+$last_row, 0,
      (($$self->[NAMES][$last_row]) x $new_rows);
    splice @{$$self->[VALUES]}, 1+$last_row, 0, ((undef) x $new_rows);
    push @{$$self->[INDEX]{$key}}, 1+$last_row .. $last_row+$new_rows;
  } # otherwise, $cur_count == $new_count
  $$self->[MVOFF] = undef unless $cur_count == $new_count;
  # there are always $new_count rows with $key at this point

  for (my $i = 0; $i < $new_count; $i++)
    { $$self->[VALUES][$$self->[INDEX]{$key}[$i]] = $value_aref->[$i] }
}

=head2 Methods

=over

=item $f = WARC::Fields-E<gt>new

Construct a new C<WARC::Fields> object.  Initial contents can be passed as
key-value pairs to this constructor and will be added in the given order.

Repeating a key or supplying an array reference as a value assigns multiple
values to a key.  To reduce the risk of confusion, only quoting with a
leading ':' overrides the convenience feature of applying C<s/_/-/g> when
constructing a C<WARC::Fields> object.  The exact match rules used when
setting values on an existing object do not apply here.

Field names given when constructing a WARC::Fields object are otherwise
stored exactly as given, with case preserved, even when other names that
fold to the same string have been given earlier in the argument list.

=cut

sub new {
  my $class = shift;
  my $ob = [OBJECT_INIT];
  my $k; my $v;

  # explicitly initialize NAMES and VALUES to allow as_string and as_block
  # methods to be called on empty objects
  $ob->[NAMES] = [];
  $ob->[VALUES] = [];

  while (($k, $v) = splice @_, 0, 2) {
    croak "key without value" unless defined $v;

    if ($k =~ m/^:/) { $k =~ s/^:// } else { $k =~ s/_/-/g }

    croak "reference to field with no name" unless $k =~ m/./;
    croak "reference to invalid field name" if $k !~ m/^$PARSE_RE__token$/o;

    if (ref $v eq 'ARRAY') {
      foreach my $value (@$v) {
	push @{$ob->[NAMES]}, $k;
	push @{$ob->[VALUES]}, $value;
	push @{$ob->[INDEX]{lc $k}}, $#{$ob->[NAMES]};
      }
    } else {
      push @{$ob->[NAMES]}, $k;
      push @{$ob->[VALUES]}, $v;
      push @{$ob->[INDEX]{lc $k}}, $#{$ob->[NAMES]};
    }
  }

  {our $_total_newly_constructed;	$_total_newly_constructed++}
  bless \ $ob, $class;
}

=item $f-E<gt>clone

Copy a C<WARC::Fields> object.  A copy of a read-only object is writable.

=cut

sub clone {
  my $self = shift;
  my $new = [OBJECT_INIT];

  $new->[NAMES] = [@{$$self->[NAMES]}];
  $new->[VALUES] = [@{$$self->[VALUES]}];
  $new->[MVOFF] = [@{$$self->[MVOFF]}] if defined $$self->[MVOFF];
  $new->[INDEX] = {map {$_ => [@{$$self->[INDEX]{$_}}]}
		   keys %{$$self->[INDEX]}} if defined $$self->[INDEX];

  {our $_total_newly_cloned;		$_total_newly_cloned++}
  bless \ $new, ref $self;
}

=item $f-E<gt>field( $name )

=item $f-E<gt>field( $name =E<gt> $value )

=item $f-E<gt>field( $n1 =E<gt> $v1, $n2 =E<gt> $v2, ... )

Get or set the value of one or more fields.  The field name is not case
sensitive, but C<WARC::Fields> will preserve its case if a new entry is
created.

Setting a field to C<undef> effectively deletes that field, although it
remains visible in the tied array interface and will retain its position if
a new value is assigned.  Setting a field to an empty array reference
removes that field entirely.

=cut

sub field {
  my $self = shift;

  _rebuild_INDEX($self) unless defined $$self->[INDEX];

  my $k; my $v; my $have_value_arg = scalar @_ > 1;
  while (($k, $v) = splice @_, 0, 2) {
    my $key = $self->_find_key($k);

    croak "reference to field with no name" unless $key =~ m/./;
    croak "reference to invalid field name" if $key !~ m/^$PARSE_RE__token$/o;

    if (not $have_value_arg) {
      # get a value
      return undef unless defined $$self->[INDEX]{$key};
      return $$self->[VALUES][$$self->[INDEX]{$key}[0]]
	unless $self->_key_multiple_value_p($key);
      return [grep {defined $_}
	      map {$$self->[VALUES][$_]} @{$$self->[INDEX]{$key}}];
    } # otherwise set a value
    elsif (UNIVERSAL::isa($v, 'ARRAY'))
      { $self->_set_multiple_value($key, $v) }
    elsif ($self->_key_multiple_value_p($key))
      # has multiple values, but now only setting a single value
      { $self->_set_multiple_value($key, [$v]) }
    else
      { $self->_set_single_value($key, $v) }
    $have_value_arg = scalar @_ > 1;
  }
  return ();	# return nothing
  # Note that setting one or more fields and then getting a field is
  # possible as a side-effect of this organization, but is explicitly NOT
  # supported.  That trick is NOT part of the stable API.
}

=item $f = WARC::Fields-E<gt>parse( $text )

=item $f = WARC::Fields-E<gt>parse( from =E<gt> $fh )

=item $f = parse WARC::Fields from =E<gt> $fh

Construct a new C<WARC::Fields> object, reading initial contents from the
provided text string or filehandle.

The C<parse> method throws an exception if it encounters input that it does
not understand.

If the C<parse> method encounters a field name with a leading ':', which
implies an empty name and is not allowed, the leading ':' is silently
dropped from the line and parsing retried.  If the line is not valid after
this change, the C<parse> method throws an exception.  This feature is in
keeping with the general principle of "be liberal in what you accept" and
is a preemptive workaround for a predicted bug in other implementations.

=cut

sub parse {
  my $class = shift;
  my $text = shift;
  my $rd;

  if ($text eq 'from') {
    $rd = shift;
  } else {
    # This fails iff perl was built without PerlIO, which is non-default.
    # uncoverable branch true
    open $rd, '<', \$text or die "failure opening stream on variable: $!";
  }

  my @names = ();
  my @values = ();
  my %idx = ();
  my $at_end = 0;

  local *_;
  while (<$rd>) {
    s/[\015\012]+$//;
    if (m/^:?($PARSE_RE__token):\s+(.*)$/o)	# $1 -- name	$2 -- value
      { push @names, $1; push @values, $2; push @{$idx{lc $1}}, $#names }
    elsif (m/^\s+(\S.*)$/)			# $1 -- continued value
      { $values[$#values] .= ' '.$1 }
    elsif (m/^$/) { $at_end = 1; last }
    else { croak "unrecognized input:  $_" }
  }

  carp "end-of-input before end marker" unless $at_end;

  @values = map {Encode::decode_utf8($_)} @values;

  my $ob = [OBJECT_INIT];
  $ob->[NAMES] = \@names;
  $ob->[VALUES] = \@values;
  $ob->[INDEX] = \%idx;

  {our $_total_newly_parsed;		$_total_newly_parsed++}
  bless \ $ob, $class;
}

=item $f-E<gt>as_block

=item $f-E<gt>as_string

Return the contents as a formatted WARC header or application/warc-fields
block.  The C<as_block> method uses network line endings and UTF-8 as
specified for the WARC format, while the C<as_string> method uses the local
line endings and does not perform encoding.

=cut

sub _as_text {
  my $self = shift;
  my $newline = shift;
  my $out = '';

  for (my $i = 0; $i < @{$$self->[NAMES]}; $i++) {
    next unless defined $$self->[VALUES][$i];
    $out .= $$self->[NAMES][$i] . ': ' . $$self->[VALUES][$i] . $newline;
  }

  return $out;
}

sub as_block	{ Encode::encode('UTF-8', _as_text(shift, WARC::CRLF)) }
sub as_string	{ _as_text(shift, "\n") }

=item $f-E<gt>set_readonly

Mark a C<WARC::Fields> object read-only.  All methods that modify the
object will croak() if called on a read-only object.

=cut

sub set_readonly {
  my $self = shift;

  $$self->[IS_RO] = 1;
}

=back

=head2 Tied Array Access

The order of fields can be fully controlled by tying an array to a
C<WARC::Fields> object and manipulating the array using ordinary Perl
operations.  The C<splice> and C<sort> functions are likely to be useful
for reordering array elements if desired.

C<WARC::Fields> will croak() if an attempt is made to set a field name with
a leading ':' using the tied array interface.

=cut

sub TIEARRAY {
  my $class = shift;
  my $ob = shift;

  # This method must ignore the given class to allow the "empty subclass"
  #  test to pass.  If a subclass really wants, an override for TIEARRAY
  #  itself can call SUPER::TIEARRAY and re-bless the returned reference
  #  into the desired class.
  $WARC::Fields::TiedArray::_total_tied++;
  bless \ $ob, 'WARC::Fields::TiedArray';
}

{
  package WARC::Fields::TiedArray::Entry;

  use Carp;

  BEGIN { $WARC::Fields::TiedArray::Entry::{$_} = $WARC::Fields::{$_}
	    for WARC::Fields::OBJECT_INDEX; }

  use constant { NAME => 0, VALUE => 1, TABLE => 2, ROW => 3 };

  use overload '""' => 'name', fallback => 1;

=pod

The tied array interface accepts simple string values but returns objects
with additional information.  The returned object has an overloaded string
conversion that yields the name for that entry but additionally has
C<value> and C<offset> methods.

An entry object is bound to a slot in its parent C<WARC::Fields> object,
but will be copied if it is assigned to another slot in the same or another
C<WARC::Fields> object.

Due to complex aliasing rules necessary for array slice assignment to work
for permuting rows in the table, entry objects must be short-lived.
Storing the object read from a tied array and attempting to use it after
modifying its parent C<WARC::Fields> object produces unspecified results.

=over

=item $entry = $array[$n]

=item $entry = $f-E<gt>[$n]

The tied array C<FETCH> method returns a "entry object" instead of the name
itself.

=cut

sub _new {
  my $class = shift;
  my $table = shift;
  my $row = shift;

  bless [$$table->[NAMES][$row], $$table->[VALUES][$row],
	 $table, $row], $class;
}

=item $name = "$entry"

=item $name = $entry-E<gt>name

=item $name = "$f-E<gt>[$n]"

=item $name = $f-E<gt>[$n]-E<gt>name

The C<name> method on a entry object returns the field name.
String conversion is overloaded to call this method.

=cut

sub name { (shift)->[NAME] }

=item $value = $entry-E<gt>value

=item $value = $array[$n]-E<gt>value

=item $value = $f-E<gt>[$n]-E<gt>value

=item $entry-E<gt>value( $new_value )

=item $array[$n]-E<gt>value( $new_value )

=item $f-E<gt>[$n]-E<gt>value( $new_value )

The C<value> method on a entry object returns the field value for this
particular entry.  Only a single scalar is returned, even if multiple
entries share the same name.

If given an argument, the C<value> method replaces the value for this
particular entry.  The argument will be coerced to a string.

=cut

sub value {
  my $self = shift;

  if (scalar @_ == 0) {	# get this value
    return $self->[VALUE];
  } else {		# update this value
    croak "attempt to modify read-only object" if ${$self->[TABLE]}->[IS_RO];
    my $newval = shift;
    ${$self->[TABLE]}->[VALUES]->[$self->[ROW]] = $self->[VALUE] = "$newval";
    return ();		# and return nothing
  }
}

=item $offset = $entry-E<gt>offset

=item $offset = $array[$n]-E<gt>offset

=item $offset = $f-E<gt>[$n]-E<gt>offset

The C<offset> method on a entry object returns the position of this entry
amongst multiple entries with the same field name.  These positions are
numbered from zero and are identical to the positions in the array
reference returned for this entry's field name from the C<field> method or
the tied hash interface.

=cut

sub offset {
  my $self = shift;
  $self->[TABLE]->_rebuild_MVOFF unless defined ${$self->[TABLE]}->[MVOFF];
  return ${$self->[TABLE]}->[MVOFF]->[$self->[ROW]];
}

=back

=cut

}

{
  package WARC::Fields::TiedArray::LooseEntry;

  use Carp;

  BEGIN { $WARC::Fields::TiedArray::LooseEntry::{$_} = $WARC::Fields::{$_}
	    for WARC::Fields::OBJECT_INDEX; }

  use constant { NAME => 0, VALUE => 1 };

  BEGIN { our @ISA = qw(WARC::Fields::TiedArray::Entry) }

  # This is a special type of "entry object" that is not associated with a
  #  table row, returned from POP, SHIFT, and SPLICE when needed.

  sub _new {
    my $class = shift;
    my $name = shift;
    my $value = shift;

    bless [$name, $value], $class;
  }

  sub name { return (shift)->[NAME] }

  sub value {
    my $self = shift;

    if (scalar @_ == 0)	# get
      { return $self->[VALUE] }
    else		# set
      { croak "Loose array entries are read-only." }
  }

  sub offset { return undef }
}

{
  package WARC::Fields::TiedArray;

  use Carp;

  BEGIN { $WARC::Fields::TiedArray::{$_} = $WARC::Fields::{$_}
	    for WARC::Fields::OBJECT_INDEX; }

  # The underlying object is a reference to a WARC::Fields object.

  sub FETCH {
    my $self = shift;
    my $row = shift;
    return (ref($self).'::Entry')->_new($$self, $row);
  }

  sub STORE {
    my $self = shift;
    my $row = shift;
    my $name = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    $self->STORESIZE($row + 1) if $#{$$$self->[NAMES]} < $row;

    if (UNIVERSAL::isa($name, ref($self).'::Entry')) {
      # copy entry
      croak "attempt to set invalid name"
	if $name->name !~ m/^$PARSE_RE__token$/o;
      $$$self->[NAMES]->[$row] = $name->name;
      $$$self->[VALUES]->[$row] = $name->value;
    } else {
      # set name
      croak "attempt to set invalid name"
	if "$name" !~ m/^$PARSE_RE__token$/o;
      $$$self->[NAMES]->[$row] = "$name";
    }
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
  }

  sub FETCHSIZE {
    my $self = shift;
    return scalar @{$$$self->[NAMES]};
  }

  sub STORESIZE {
    my $self = shift;
    my $count = shift;

    croak "attempt to modify read-only object"
      if $$$self->[IS_RO] && $count != $self->FETCHSIZE();

    if ($count > $self->FETCHSIZE()) {
      my $needed = $count - $self->FETCHSIZE();
      push @{$$$self->[NAMES]}, ('X-Undefined-Field-Name') x $needed;
      push @{$$$self->[VALUES]}, (undef) x $needed;
    } elsif ($count < $self->FETCHSIZE()) {
      splice @{$$$self->[NAMES]}, $count;
      splice @{$$$self->[VALUES]}, $count;
      $$$self->[INDEX] = undef;
    } else { return } # no actual change
  }

  sub EXTEND {
    # do nothing
  }

  sub EXISTS {
    my $self = shift;
    my $row = shift;
    return defined $$$self->[VALUES]->[$row];
  }

  sub DELETE {
    my $self = shift;
    my $row = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    my $old_value = $$$self->[VALUES]->[$row];
    $$$self->[VALUES]->[$row] = undef;
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return $old_value;
  }

  sub CLEAR {
    my $self = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    $$$self->[NAMES] = [];
    $$$self->[VALUES] = [];
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return undef;
  }

  sub PUSH {
    my $self = shift;

    croak "attempt to modify read-only object"
      if $$$self->[IS_RO] && scalar @_;

    foreach my $item (@_) {
      my $name; my $value;
      if (UNIVERSAL::isa($item, ref($self).'::Entry'))
	{ $name = $item->name; $value = $item->value }
      else
	{ $name = "$item"; $value = undef }
      croak "attempt to set invalid name" if $name !~ m/^$PARSE_RE__token$/o;
      push @{$$$self->[NAMES]}, $name;
      push @{$$$self->[VALUES]}, $value;
    }
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return scalar @{$$$self->[NAMES]};
  }

  sub POP {
    my $self = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    my $ret = WARC::Fields::TiedArray::LooseEntry->_new
      (pop @{$$$self->[NAMES]}, pop @{$$$self->[VALUES]});
    pop @{$$$self->[MVOFF]} if defined $$$self->[MVOFF];
    $$$self->[INDEX] = undef;

    return $ret;
  }

  sub SHIFT {
    my $self = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    my $ret = WARC::Fields::TiedArray::LooseEntry->_new
      (shift @{$$$self->[NAMES]}, shift @{$$$self->[VALUES]});
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;

    return $ret;
  }

  sub UNSHIFT {
    my $self = shift;

    croak "attempt to modify read-only object"
      if $$$self->[IS_RO] && scalar @_;

    foreach my $item (@_) {
      my $name; my $value;
      if (UNIVERSAL::isa($item, ref($self).'::Entry'))
	{ $name = $item->name; $value = $item->value }
      else
	{ $name = "$item"; $value = undef }
      croak "attempt to set invalid name" if $name !~ m/^$PARSE_RE__token$/o;
      unshift @{$$$self->[NAMES]}, $name;
      unshift @{$$$self->[VALUES]}, $value;
    }
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return scalar @{$$$self->[NAMES]};
  }

  sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    $offset = 0 unless defined $offset;
    $length = $self->FETCHSIZE() - $offset unless defined $length;

    return () unless ($length != 0 || scalar @_);

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    my @new_names = (); my @new_values = (); my @old_names; my @old_values;

    foreach my $item (@_) {
      if (UNIVERSAL::isa($item, ref($self).'::Entry')) {
	push @new_names,  $item->name;
	push @new_values, $item->value;
      } else {
	push @new_names, "$item";
	push @new_values, undef;
      }
    }

    croak "attempt to set invalid name"
      if grep { $_ !~ m/^$PARSE_RE__token$/o } @new_names;

    @old_names  = splice @{$$$self->[NAMES]},  $offset, $length, @new_names;
    @old_values = splice @{$$$self->[VALUES]}, $offset, $length, @new_values;

    my @ret = ();

    for (my $i = 0; $i < scalar @old_names; $i++)
      { push @ret, WARC::Fields::TiedArray::LooseEntry->_new
	  ($old_names[$i], $old_values[$i]) }

    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return @ret;
  }

  sub UNTIE { our $_total_untied;	$_total_untied++ }

  sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }
}

=head2 Tied Hash Access

The contents of a C<WARC::Fields> object can be easily examined by tying a
hash to the object.  Reading or setting a hash key is equivalent to the
C<field> method, but the tied hash will iterate keys and values in the
order in which each key B<first> appears in the internal table.

Like the tied array interface, the tied hash interface returns magical
objects that internally refer back to the parent C<WARC::Fields> object.
These objects remain valid if the underlying C<WARC::Fields> object is
changed, but further use may produce surprising and unspecified results.

The use of magical objects enables the values in a tied hash to B<always>
be arrays, even for keys that do not exist (the array will have zero
elements) or that have only one value (the array will have a string
conversion that produces that one value).  This allows a tied hash to
support autovivification of an array value just as Perl's own hashes do.

=cut

sub TIEHASH {
  my $class = shift;
  my $ob = shift;

  # This method must ignore the given class to allow the "empty subclass"
  #  test to pass.  If a subclass really wants, an override for TIEHASH
  #  itself can call SUPER::TIEHASH and re-bless the returned reference
  #  into the desired class.
  $WARC::Fields::TiedHash::_total_tied++;
  bless \ $ob, 'WARC::Fields::TiedHash';
}

{
  package WARC::Fields::TiedHash::ValueArray;

  use Carp;

  BEGIN { $WARC::Fields::TiedHash::ValueArray::{$_} = $WARC::Fields::{$_}
	    for WARC::Fields::OBJECT_INDEX; }

  use constant { TABLE => 0, KEY => 1, KEYc => 2 }; # KEYc -- canonical KEY

  sub TIEARRAY {
    my $class = shift;
    my $table = shift;
    $table->_rebuild_INDEX unless defined $$table->[INDEX];
    my $key = $table->_find_key(shift);	# needs INDEX

    { our $_total_tied;			$_total_tied++ }
    bless [$table, $key, lc $key], $class;
  }

  sub FETCH {
    my $self = shift;
    my $offset = shift;

    $self->[TABLE]->_rebuild_INDEX unless defined ${$self->[TABLE]}->[INDEX];

    my $row = ${$self->[TABLE]}->[INDEX]{$self->[KEYc]}[$offset];
    return defined $row ? ${$self->[TABLE]}->[VALUES][$row] : undef;
  }

  sub STORE {
    my $self = shift;
    my $offset = shift;
    my $value = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object" if $$T->[IS_RO];

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    $self->STORESIZE($offset + 1)
      if not defined $$T->[INDEX]{$self->[KEYc]}
	or $#{$$T->[INDEX]{$self->[KEYc]}} < $offset;

    $$T->[VALUES][$$T->[INDEX]{$self->[KEYc]}[$offset]] = "$value";
  }

  sub FETCHSIZE {
    my $self = shift;

    $self->[TABLE]->_rebuild_INDEX unless defined ${$self->[TABLE]}->[INDEX];

    return scalar @{${$self->[TABLE]}->[INDEX]{$self->[KEYc]}}
      if defined ${$self->[TABLE]}->[INDEX]{$self->[KEYc]};
    return 0; # otherwise:  key does not exist
  }

  sub STORESIZE {
    my $self = shift;
    my $count = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object"
      if $$T->[IS_RO] && $count != $self->FETCHSIZE();

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    my @new = ();
    @new = @{$$T->[VALUES]}[@{$$T->[INDEX]{$self->[KEYc]}}]
      if defined $$T->[INDEX]{$self->[KEYc]};
    if ($count > $self->FETCHSIZE())
      { push @new, (undef) x ($count - $self->FETCHSIZE()) }
    elsif ($count < $self->FETCHSIZE())
      { @new = @new[0..($count-1)] }
    else { return } # no actual change
    $T->field($self->[KEY] => \@new);
  }

  sub EXTEND {
    # do nothing
  }

  sub EXISTS {
    my $self = shift;
    my $offset = shift;

    $self->[TABLE]->_rebuild_INDEX unless defined ${$self->[TABLE]}->[INDEX];

    return exists ${$self->[TABLE]}->[INDEX]{$self->[KEYc]}[$offset];
  }

  sub DELETE {
    my $self = shift;
    my $offset = shift;

    croak "attempt to modify read-only object" if ${$self->[TABLE]}->[IS_RO];

    $self->[TABLE]->_rebuild_INDEX unless defined ${$self->[TABLE]}->[INDEX];

    my $row = ${$self->[TABLE]}->[INDEX]{$self->[KEYc]}[$offset];
    my $old_value = ${$self->[TABLE]}->[VALUES][$row];
    ${$self->[TABLE]}->[VALUES][$row] = undef;
    return $old_value;
  }

  sub CLEAR {
    my $self = shift;

    croak "attempt to modify read-only object" if ${$self->[TABLE]}->[IS_RO];

    $self->[TABLE]->field($self->[KEY] => []);
  }

  sub PUSH {
    my $self = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object"
      if $$T->[IS_RO] && scalar @_;

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    if (defined $$T->[INDEX]{$self->[KEYc]}) {
      # key exists ==> extend table efficiently
      my $last_row = $$T->[INDEX]{$self->[KEYc]}[-1];
      my $new_rows = scalar @_;
      splice @{$$T->[NAMES]}, 1+$last_row, 0,
	(($$T->[NAMES][$last_row]) x $new_rows);
      splice @{$$T->[VALUES]}, 1+$last_row, 0, map {"$_"} @_;
      $T->_update_INDEX($last_row, $new_rows);
      push @{$$T->[INDEX]{$self->[KEYc]}}, 1+$last_row .. $last_row+$new_rows;
    } else {
      # make key ==> use existing setter
      $T->_set_multiple_value($self->[KEY], [map {"$_"} @_]);
    }
    $$T->[MVOFF] = undef;
  }

  sub POP {
    my $self = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object" if $$T->[IS_RO];

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    return undef unless defined $$T->[INDEX]{$self->[KEYc]};

    my $rem_row = $$T->[INDEX]{$self->[KEYc]}[-1];
    my $value = $$T->[VALUES][$rem_row];

    splice @{$$T->[NAMES]}, $rem_row, 1;
    splice @{$$T->[VALUES]}, $rem_row, 1;
    splice @{$$T->[MVOFF]}, $rem_row, 1 if defined $$T->[MVOFF];
    $T->_update_INDEX($rem_row, -1);
    pop @{$$T->[INDEX]{$self->[KEYc]}};
    # special case:  popped last value
    delete $$T->[INDEX]{$self->[KEYc]}
      if scalar @{$$T->[INDEX]{$self->[KEYc]}} == 0;

    return $value;
  }

  sub SHIFT {
    my $self = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object" if $$T->[IS_RO];

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    return undef unless defined $$T->[INDEX]{$self->[KEYc]};

    my $rem_row = $$T->[INDEX]{$self->[KEYc]}[0];
    my $value = $$T->[VALUES][$rem_row];

    splice @{$$T->[NAMES]}, $rem_row, 1;
    splice @{$$T->[VALUES]}, $rem_row, 1;
    $$T->[MVOFF] = undef;
    $T->_update_INDEX($rem_row, -1);
    shift @{$$T->[INDEX]{$self->[KEYc]}};
    # special case:  shifted last value
    delete $$T->[INDEX]{$self->[KEYc]}
      if scalar @{$$T->[INDEX]{$self->[KEYc]}} == 0;

    return $value;
  }

  sub UNSHIFT {
    my $self = shift;

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object"
      if $$T->[IS_RO] && scalar @_;

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    if (defined $$T->[INDEX]{$self->[KEYc]}) {
      # key exists ==> extend table efficiently
      my $first_row = $$T->[INDEX]{$self->[KEYc]}[0];
      my $new_rows = scalar @_;
      splice @{$$T->[NAMES]}, $first_row, 0,
	(($$T->[NAMES][$first_row]) x $new_rows);
      splice @{$$T->[VALUES]}, $first_row, 0, map {"$_"} @_;
      $T->_update_INDEX($first_row - 1, $new_rows);
      unshift @{$$T->[INDEX]{$self->[KEYc]}},
	$first_row .. $first_row-1+$new_rows;
    } else {
      # make key ==> use existing setter
      $T->_set_multiple_value($self->[KEY], [map {"$_"} @_]);
    }
    $$T->[MVOFF] = undef;
  }

  sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;

    $offset = 0 unless defined $offset;
    $length = $self->FETCHSIZE() - $offset unless defined $length;

    return () unless ($length != 0 || scalar @_);

    my $T = $self->[TABLE];

    croak "attempt to modify read-only object" if $$T->[IS_RO];

    $T->_rebuild_INDEX unless defined $$T->[INDEX];

    my @new = ();
    @new = @{$$T->[VALUES]}[@{$$T->[INDEX]{$self->[KEYc]}}]
      if defined $$T->[INDEX]{$self->[KEYc]};
    my @old = splice @new, $offset, $length, map {"$_"} @_;
    $self->[TABLE]->field($self->[KEY] => \@new);

    return @old;
  }

  sub UNTIE { our $_total_untied;	$_total_untied++ }

  sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }
}

{
  package WARC::Fields::TiedHash::Value;

  # This package is a magical array that appears to be a string if it has
  # only one value, otherwise string conversion gives the usual
  # nearly-useless debugging value.

  # The actual underlying array is a tied array that forwards mutating
  # operations to the original WARC::Fields object.

  use overload '""' => '_as_string', fallback => 1;

  use Scalar::Util qw/refaddr reftype/;

  sub _new {
    my $class = shift;
    my $parent = shift;
    my $key = shift;

    my @values;
    tie @values, (ref($parent).'::ValueArray'), $$parent, $key;

    bless \@values, $class;
  }

  sub _as_string {
    my $self = shift;

    return scalar @$self == 1
      ? $self->[0] : sprintf ('%s(0x%x)', reftype $self, refaddr $self);
  }

  sub DESTROY { untie @{(shift)} }
}

{
  package WARC::Fields::TiedHash;

  use Carp;

  BEGIN { $WARC::Fields::TiedHash::{$_} = $WARC::Fields::{$_}
	    for WARC::Fields::OBJECT_INDEX; }

  # The underlying object is a reference to a WARC::Fields object.

  sub FETCH {
    my $self = shift;
    my $key = shift;
    croak "reference to invalid field name" if $key !~ m/^$PARSE_RE__token$/o;
    return (ref($self).'::Value')->_new($self, $key);
  }

  sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    $$self->field($key => $value);
  }

  sub DELETE {
    my $self = shift;
    my $key = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    $$self->field($key => []);
  }

  sub CLEAR {
    my $self = shift;

    croak "attempt to modify read-only object" if $$$self->[IS_RO];

    $$$self->[NAMES] = [];
    $$$self->[VALUES] = [];
    $$$self->[MVOFF] = undef;
    $$$self->[INDEX] = undef;
    return undef;
  }

  sub EXISTS {
    my $self = shift;
    my $key = shift;

    $$self->_rebuild_INDEX unless defined $$$self->[INDEX];
    return exists $$$self->[INDEX]->{$$self->_find_key($key)};
  }

  sub FIRSTKEY {
    my $self = shift;

    return $$$self->[NAMES][0];
  }

  sub NEXTKEY {
    my $self = shift;
    my $from_key = shift;

    $$self->_rebuild_INDEX unless defined $$$self->[INDEX];

    my $i;
    for ($i = $$$self->[INDEX]{$$self->_find_key($from_key)}[0] + 1;
	 defined $$$self->[NAMES][$i] and
	 $i != $$$self->[INDEX]{$$self->_find_key($$$self->[NAMES][$i])}[0];
	 $i++) {}
    return $$$self->[NAMES][$i];
  }

  sub SCALAR {
    my $self = shift;
    return scalar @{$$$self->[NAMES]};
  }

  sub UNTIE { our $_total_untied;	$_total_untied++ }

  sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }
}

=head2 Overloaded Dereference Operators

The C<WARC::Fields> class provides overloaded dereference operators for
array and hash dereferencing.  The overloaded operators provide an
anonymous tied array or hash as needed, allowing the object itself to be
used as a reference to its tied array and hash interfaces.  There is a
caveat, however, so read on.

=cut

sub _as_tied_array {
  # To avoid confusing bugs due to typos producing overloaded dereferences
  #  instead of intended accesses to the internal object, this feature
  #  cannot be used from within this module.
  if (scalar caller =~ m/^WARC::Fields/) {
    local $Carp::CarpLevel = 1;
    confess "overloaded array dereference in internal code"
  }

  my $self = shift;

  return $$self->[C_TA] if defined $$self->[C_TA];

  my @array; $$self->[C_TA] = \@array;
  Scalar::Util::weaken ${tie @array, ref $self, $self};
  return $$self->[C_TA];
}

sub _as_tied_hash {
  # To avoid confusing bugs due to typos producing overloaded dereferences
  #  instead of intended accesses to the internal object, this feature
  #  cannot be used from within this module.
  if (scalar caller =~ m/^WARC::Fields/) {
    local $Carp::CarpLevel = 1;
    confess "overloaded hash dereference in internal code"
  }

  my $self = shift;

  return $$self->[C_TH] if defined $$self->[C_TH];

  my %hash; $$self->[C_TH] = \%hash;
  Scalar::Util::weaken ${tie %hash, ref $self, $self};
  return $$self->[C_TH];
}

=head3 Reference Count Trickery with Overloaded Dereference Operators

To avoid problems, the underlying tied object is a reference to the parent
object.  For ordinary use of C<tie>, this is a strong reference, however,
the anonymous tied array and hash are cached in the object to avoid having
to C<tie> a new object every time the dereference operators are used.

To prevent memory leaks due to circular references, the overloaded
dereference operators tie a I<weak> reference to the parent object.  The
tied aggregate always holds a strong reference to its object, but when the
dereference operators are used, that inner object is a I<weak> reference to
the actual C<WARC::Fields> object.

The caveat is thus: do not attempt to save a reference to the array or hash
produced by dereferencing a C<WARC::Fields> object.  The parent
C<WARC::Fields> object must remain in scope for as long as any anonymous
tied aggregates exist.

=cut

1;
__END__

=head1 CAVEATS

Do not save references to the anonymous tied aggregates returned by
dereferencing a C<WARC::Fields> object.

Do not save references to the entries read from tied aggregates unless the
C<WARC::Fields> object is read-only.  Modifications may or may not be
reflected in previously constructed entry objects and hash value arrays and
the exact behavior may change without warning or notice.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<HTTP::Headers>, L<Scalar::Util> for C<weaken>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
