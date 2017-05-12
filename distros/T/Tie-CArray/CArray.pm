package Tie::CArray;
#
#   "Better to do it in Perl than C."  - from C::Dynalib.pm
#
#   "Better do it in C than in Perl."  - Tie::CArray.pm
#
use strict;
local $^W = 1;
use Carp;
use vars qw( $VERSION @ISA );
require DynaLoader;
$VERSION = sprintf("%d.%02d", q$Revision: 0.15 $ =~ /(\d+)\.(\d+)/);
@ISA = qw( DynaLoader );

=head1 NAME

Tie::CArray - Space-efficient, typed, external C Arrays (Alpha)

=head1 SYNOPSIS

    use Tie::CArray;
    $dblarr = new Tie::CDoubleArray(10000);

    @values = (0..10000);
    $dblarr = new Tie::CIntArray(10000,\@values);
    ref $dblarr eq 'Tie::CIntArray' and
      $dblarr->set(0,1) and
      $dblarr->get(0) == 1;

    tie @array, 'Tie::CDoubleArray', 10000, \@values;
    print $array[0], join ', ', @dbl[1..20];

=head1 DESCRIPTION

Several XS classes and methods to deal with typed, space-efficient
C arrays are provided. Range checked and tieable.

There are hand-optimized, fast XS versions for the three basic C-types
array of I<INT>, I<DOUBLE> and I<STRING> and some sequential aggregate types
int[2][], int[3][], int[4][], double[2][] and double[3][].

This roughly reflects to:

    CArray
        CIntArray               int[]
            CInt2Array          int[][2]
            CInt3Array          int[][3]
            CInt4Array          int[][4]
        CDoubleArray            double[]
            CDouble2Array       double[][2]
            CDouble3Array       double[][3]
        CStringArray            *char[]

Typed C arrays need about three times less space then untyped perl arrays.
Such as various computional geometry modules dealing with 10.000 - 200.000
double[3]. Modification is done in-place and preferably in bulk.

It might also be easier to write XSUBs by converting the data to CArray's
before, pass this pointer to the C func, and handle the results in Perl
then.

The Fetch/Store operations with tied arrays copy the scalars to perl
and back, so it shouldn't be abused for BIG data.

Perl's safemalloc/safefree is used.

=head1 EFFICIENT GROW

CArray's are efficiently growable, which is needed for several
algorithms, such as placing extra sentinels at the end, adding
three points for a super-triangle for Delaunay triangulation, ...

Extra space is always allocated to fit nicely into the page boundary,
defined by the system granularity.
For now it's 2048, half of the usual 4096, but this can be tweaked (e.g. for
many small arrays) in the C function freesize().

=cut
bootstrap Tie::CArray $VERSION;

# Preloaded methods go here.
package Tie::CArray;
require 5.006;
use Tie::Array;
use strict;
use vars qw(@ISA);
use Carp;
@ISA = qw(Tie::Array);

# Mandatory methods defined only for the abstract class Tie::CArray,
# in terms of the autoloaded spezialized methods

=pod

=head1 CLASS METHODS

=over 4

=item new ( size, [ template, [ values ]] )

The new method is provided for all classes, the optional arrayref initarg
applies only to the base C<Array> classes, not the aggregate.

The constructor creates a new C<Tie::CArray> object. For the C<Array>
classes the second optional argument is used to initialize it with an
array. The second argument may also be used by a seperate init call.
If the optionally provided values arrayref is shorter that the
allocated size, the rest will stay uninitialized.

    $D = new Tie::CDoubleArray( 1000, ,[0..999] );

=cut

# the whole rawclass issue is gone.
# only needed for Tie::CArray and the aggregate classes
# 0.12 added templates
sub new {
  no strict 'refs';
  my $class = shift;
  # Tie::CArray::new as virtual baseclass needs an additional second type arg.
  $class = shift if $class eq 'Tie::CArray';
  my $size  = shift;
  # the Tie::CArray arg initializer not, we have copy instead
  confess "usage: new $class (size, [template, [values]])"
      if $size =~ /\D/;
  my $template = shift;
  my $initval = shift;
  $class =~ /(.*)(\d)(.*)/;
  if ($2) {
    $initval
        ? bless( &{$1 . $3 . '::new'}($size * $2, $initval), $class)
        : bless( &{$1 . $3 . '::new'}($size * $2), $class);
  } else {
    $initval
        ? bless( &{$class . '::new'}($size, $initval), $class)
        : bless( &{$class . '::new'}($size), $class);
  }
}

=pod

=item len ()

The len method returns the length of the array, 1+ the index of the
last element. To enlarge the array grow() should be used.

    $D  = new Tie::CDoubleArray(5000);
    for my $j (0 .. $D->len-1) { $D->set($_, 0.0)); }
    $D->len; # => 5000

=item get ( index )

get returns the value at the given index, which will be scalar or a list.
Croaks with "index out of range" on wrong index.

    $I = new Tie::CIntArray(2,[0,1]);
    print $I->get(1); # => 1
    print $I->get(2);
      => croak "index out of range"

    $I2 = new Tie::CInt2Array(2,[[0,1]]);
    print $I->get(0); # => (0 1)

=item set ( index, value )

The set method is provided for all classes.
It changes the value at the given index.
The value should be either a scalar or an arrayref.
Croaks with "index out of range" on wrong index.
Returns nothing.

    $I = new Tie::CIntArray(100);
    map { $I->set($_,$i[$_]) } (0..99);
    $I->set(99,-1);
    $I->set(100);
      => "index out of range"

    $I2 = Tie::CInt2Array->new(2);
    $I2->set(0, [1,0]);
    $I2->set(1, [0,1]);

=item list ()

Returns the content of the flat array representation as arrayref.

=item init ( ARRAYREF )

Initializes the array with the values from the arrayref.
Returns nothing.

This is the same as the second new argument.
If the provided values arrayref is shorter that the allocated size,
the rest will stay uninitialized.

  $I = Tie::CIntArray::new(100) ;
  $I->init( [0..99] );

=item grow ( n )

Adds room for n elements to the array. These elements must be initialized
extra with set.
To support faster grow() a certain number of already pre-allocated items
at the end of the array will be used. (see free)
Returns nothing.

=item delete ( index )

Deletes the item at the given index. free is incremented and the remaining
array items are shifted.
Returns nothing.

=item get_grouped_by ( size, index )

Returns a list of subsequent values.
It returns a list of size indices starting at size * index.
This is useful to abuse the unstructured array as typed array of the
same type, such as *double[3] or *int[2].

But this is normally not used since fast get methods are provided for the
sequential classes, and those methods can be used on flat arrays as well.
(Internally all sequential arrays are flat).

  Tie::CInt3Array::get($I,0) == $I->get_grouped_by(3,0)

$ptr->get_grouped_by(2,4) returns the 4-th pair if the array is seen
as list of pairs.

  $ptr->get_grouped_by(3,$i) => (ptr[i*3] ptr[i*3+1] ptr[i*3+2] )

=cut

# support for structured data, such as typedef int[3] Triangle
# returns the i-th slice of length by
sub get_grouped_by ($$$) {     #22.11.99 13:14
  my $self = shift;
  my $by   = shift;
  my $i    = shift;
  $i *= $by;
  map { $self->get($i++) } (1 .. $by);
}

# c++ like slice operator: start, size, stride
# => list of size items with stride interim offsets, matrix rows and cols
sub slice ($$$;$) {
  my $self  = shift;
  my $start = shift;
  my $size  = shift;
  my $stride = shift || 1;
  # absolute offsets
  map { $self->get($_) }
      map { $start + ($_ * $stride) }
          (0 .. $size-1);
}

# SPLICE this, offset, length, LIST
# TIEARRAY perl slice operator
sub SLICE ($$$;$) {
  my $self    = shift;
  my $offset  = shift;
  my $length  = shift;
  my @LIST    = @_;
  if (@_) {
	# store
    map { $self->set($offset + $_, $LIST[$_]) }
		(0 .. $length-1);
  } else {
	# fetch
    map { $self->get($offset + $_) } (0 .. $length-1);
  }
}

=pod

=item slice ( start, size, [ stride=1 ] )

C++ like slice operator on a flat array. - In contrast to get_grouped_by()
which semantics are as on a grouped array.

Returns a list of size items, starting at start,
with interim offsets of stride which defaults to 1.
This is useful to return columns or rows of a flat matrix.

  $I = new Tie::CIntArray (9, [0..8]);
  $I->slice ( 0, 3, 3 ); # 1st column
    => (0 3 6)
  $I->slice ( 0, 3, 1 ); # 1st row
    => (0 1 2)
  $I->get_grouped_by(3, 0);
    => (0 1 2)

=item isort ( [ cmpfunc ] )

"Indirect sort" (numerically ascending only for now)

Returns a fresh sorted index list of integers (0 .. len-1) resp. a
CIntArray object in scalar context.

The optional cmpfunc argument is not yet implemented.

=cut

#03.12.99 12:00 init
sub isort {
    sort { $_[0]->get($a) <=> $_[0]->get($b) }
		 (0 .. $_[0]->len()-1);
}

=pod

=item nreverse ()

"Reverse in place". (The name comes from lisp, where `n' denotes the
destructive version).
Destructively swaps all array items. Returns nothing.

To perform a copying reverse define

sub reverse { nreverse($_[0]->copy()) }

=back

=head1 SOME SEQUENTIAL CLASSES and CONVERSION

To mix and change parallel and sequential data structures, some sequential
types (int[2],int[3],int[4],double[2],double[3]) are derived from their
base classes with fast, hand-optimized get and set methods to return and
accept lists instead of scalars.

The input argument must be an arrayref, the result will be an array in list
context and an arrayref in scalar context.

Conversion

The Arrays for Int2, Int3, Int4, Double2 and Double3
can also be converted from and to parallel base arrays with fast XS methods.
Parallel arrays are sometimes preferred over structured arrays, but delete/
insert of structures in parallel arrays is costly.

  # three parallel CIntArray's
  $X = new Tie::CIntArray(1000);
  $Y = new Tie::CIntArray(1000);
  $Z = new Tie::CIntArray(1000);

  # copy to one sequential *int[3], new memory
  $I = $X->ToInt3($Y,$Z);

  # or to an existing array
  $I = new Tie::CIntArray(3000);
  $I = $X->ToInt3($Y,$Z,$I);

  # copies back with allocating new memory
  ($X, $Y, $Z) = $I->ToPar();

  # copies back with reusing some existing memory (not checked!)
  ($X, $Y, $Z) = $I->ToPar($X,$Z);  # Note: I3 will be fresh.

=over 4

=item ToPar ( SeqArray, [ Tie::CArray,... ] )

This returns a list of Tie::CArray objects, copied from the sequential
object to plain parallel CArray objects. This is a fast slice.

  *int[2] => (*int, *int)

  Tie::CInt2Array::ToPar
  Tie::CInt3Array::ToPar
  Tie::CInt4Array::ToPar
  Tie::CDouble2Array::ToPar
  Tie::CDouble3Array::ToPar

If the optional CArray args are given the memory for the returned objects are
not new allocated, the space from the given objects is used instead.

=item To$Type$Num ( CArray, ..., [ CArray ] )

This returns a sequential CArray object copied from the parallel objects
given as arguments to one sequential CArray. This is a fast map.

  *int, *int => *int[2]

  Tie::CIntArray::ToInt2
  Tie::CIntArray::ToInt3
  Tie::CIntArray::ToInt4
  Tie::CDoubleArray::ToDouble2
  Tie::CDoubleArray::ToDouble3

If the last optional CArray arg is defined the memory for the returned
object is not new allocated, the space from the given object is used instead.

=back

=head1 ARBITRARY STRUCTURED ARRAYS, PACK-STYLE TEMPLATES (not yet)

Some special sequential arrays are hand-optimized for speed but can hold only
limited data types (int[2] .. double[3]).

To support arbitrary structured arrays a second template argument may be
provided which must be a arrayref of a hash, where its keys name the accessor
and the values pack-style letters.

This does not work yet!

   tie @A, 'Tie::CArray', 200,
                [ x => 'd',
                  y => 'd',
                  z => 'd',
                  attr => [ age   => 'i',
                            dirty => 'i',
                            owner => 's' ],
                  refcount => 'i' ];
  $A->init ...

  for (my $i = 0; $i < @A; $i++) {
    printf("x,y,z: (%d %d %d),\nattr: (age=%d, dirty=%d, owner=%s)\nrefcount=%d",
           $A[$i]->{x}, $A[$i]->{y}, $A[$i]->{z},
           $A[$i]->{attr}->{age}, $A[$i]->{attr}->{dirty}, $A[$i]->{attr}->{owner},
           $A[$i]->{refcount}
          );
  }

  tie @utmp, 'Tie::CArray', 100,
        [ ut_type => 's',
          ut_pid  => 'i',
          ut_line    => 'a12',
          ut_id      => 'a4',
          ut_user    => 'a32',
          ut_host    => 'a256',
          ut_exit    => [ # struct exit_status
                          e_termination => 's',
                          e_exit        => 's' ],
          ut_session => 'l',
          ut_tv      => [ # struct timeval
                          tv_sec  => 'l'
                          tv_usec => 'l' ],
          ut_addr_v6 => 'l4',
          pad        => 'a20' ];

The following subset of L<pack()|perlfunc/"pack"> template letters is supported:

=over 4

=item i

signed integer (default)

=item I

unsigned integer

=item c

signed character (one byte integer)

=item c

unsigned character (one byte integer)

=item s

signed short integer

=item S

unsigned short integer

=item n

unsigned short integer in network byte order

=item l

signed long integer

=item L

unsigned long integer

=item N

unsigned long integer in network byte order

=item q

signed long long integer (long long/int64)

(only if the system has quads and perl was compiled for 64 bit)

=item Q

unsigned long long integer (unsigned long long/uint64)

(only if the system has quads and perl was compiled for 64 bit)

=item L

unsigned long integer

=item f

float

=item d

double

=item aI<N>

fixed-length, null-padded ASCII string of length I<N>

=item AI<N>

fixed-length, space-padded ASCII string of length I<N>

=item ZI<N>

fixed-length, null-terminated ASCII string of length I<N>

=back

=head1 INTERNAL METHODS

=over 4

=item DESTROY ()

This used to crash on certain DEBUGGING perl's, but seems
to be okay now.
Returns nothing.

=item Tie::CArray::itemsize ( )

=item Tie::CStringArray::itemsize ( [index] )

Returns the size in bytes per item stored in the array. This is only
used internally to optimize memory allocation and the free list.

A CStringArray object accepts the optional index argument, which returns the
string length at the given index. Without argument it returns the size in
bytes of a char * pointer (which is 4 on 32 bit systems).

=item copy ()

Returns a freshly allocated copy of the array with the same contents.

=item _freelen ()

Internal only.
Returns the number of free elements at the end of the array.
If grow() needs less or equal than free elements to be added,
no new room will be allocated.

This is primarly for performance measures.

=back

=cut

# the specialized Array classes go here
# the Ptr classes are defined in the XS
package Tie::CIntArray;
use strict;
use integer;
use vars qw(@ISA);
use Carp;
@ISA = qw( Tie::CArray );

package Tie::CDoubleArray;
use strict;
no integer;
use vars qw(@ISA);
use Carp;
@ISA = qw( Tie::CArray );

package Tie::CStringArray;
use strict;
use vars qw(@ISA);
use Carp;
@ISA = qw( Tie::CArray );

# These will be autoloaded after testing.
# Autoload methods go after __END__, and are processed by the autosplit program.

# Base aggregate class, purely virtual.
# get and set via get_grouped_by was 24 times slower than the XS version
# now. This is for the not so time-critical functions.
package Tie::CArray::CSeqBase;
use vars qw(@ISA);
@ISA = qw( Tie::CArray );
use Carp;

sub by   {  $_[0] =~ /(\d)/;
            return $1; }
sub base {  $_[0] =~ /^(Tie::.*)\d(.*)/;
            return $1 . $2; }

# size of item in bytes. this should be exported by the XS
# last resort, normally not needed
sub itemsize {
    my $class = ref($_[0]) || $_[0];
    $class =~ /^Tie::(.*)\d/;
    if ($1 eq 'CInt')       { $class->by * 4; }
    elsif ($1 eq 'CDouble') { $class->by * 8; }
    else                    { 0 }
}

sub len ()  { $_[0]->SUPER::len  / $_[0]->by };
sub free () { $_[0]->SUPER::free / $_[0]->by };

sub new ($$;$) {
    my $class = shift;
    my $n     = shift;
    my $init  = shift;
    croak "cannot call new Tie::CArray::CSeqBase"
        if $class eq 'Tie::CArray::CSeqBase';
    warn "cannot initialize Tie::CArray::CSeqBase: ignored" if $init;
    bless ($class->base->new($n * $class->by), $class);
}

# 24 times faster XSUB versions provided
#sub get ($$){
#    my ($self,$i, $class) = @_;
#    $class = ref $self;
#    my $by = $self->by();
#    bless ($self,$self->base);  # downgrade to flat
#    my @array = $self->get_grouped_by( $by, $i );
#    bless ($self,$class);       # upgrade it back
#    return @array;
#}
#sub set ($$$){
#    my ($self,$i,$val,$class) = @_;
#    $class = ref $self;
#    my $by = $self->by; $i *= $by;
#    $self = bless ($self,$self->base);
#    my @array = map { $self->set( $i++, $val->[$_] ) } (0 .. $by);
#    $self = bless ($self,$class);
#    return @array;
#}

# the aggregate classes: just override the base methods
package Tie::CInt2Array;
use vars qw(@ISA);
@ISA = qw( Tie::CArray::CSeqBase Tie::CIntArray );

package Tie::CInt3Array;
use vars qw(@ISA);
@ISA = qw( Tie::CArray::CSeqBase Tie::CIntArray );

package Tie::CInt4Array;
use vars qw(@ISA);
@ISA = qw( Tie::CArray::CSeqBase Tie::CIntArray );

package Tie::CDouble2Array;
use vars qw(@ISA);
@ISA = qw( Tie::CArray::CSeqBase Tie::CDoubleArray );

package Tie::CDouble3Array;
use vars qw(@ISA);
@ISA = qw( Tie::CArray::CSeqBase Tie::CDoubleArray );

#
############################################################################

=pod

=head1 TIEARRAY METHODS

B<Not tested yet!>

=over 4

=item tie (var, type, size)

After tying a array variable to an C<Tie::CArray> class the variable can
be used just as any normal perl array.

  tie @array, 'Tie::CDoubleArray', 200;
  print $array[200];
    => croak "index out of range"

=back

=cut

# The TIEARRAY stuff should be autoloaded (after testing)
package Tie::CArray;

sub TIEARRAY  { $_[0]->new(@_) }
#sub FETCH     { $_[0]->get(@_) }
#sub FETCHSIZE { $_[0]->len()  }
#sub STORE     { $_[0]->set(@_) }

# mandatory if elements can be added/deleted
# Note: we have a fast grow and delete method now
#sub STORESIZE {
#  no strict 'refs';
#  my $self = shift;
#  my $newsize  = shift;
#  my $size     = $self->len();
#  my $rawclass = $self->rawclass();
#  # or $self->PTR->set()
#  my $setfunc  = \&{"${rawclass}\:\:set"}();
#  my $arrayptr = $self->PTR();
#  if ($newsize > $size) {
#    my $new      = $self->new($size);
#    my $newarray = $new->PTR();
#    my $getfunc  = \&{"${rawclass}\:\:get"}();
#    # or $self->PTR->get()
#    for my $i (0 .. $size-1) {
#      &$setfunc($newarray, $i, &$getfunc($arrayptr,$i));
#    }
#    # or $self->PTR->DESTROY()
#    $self->DESTROY();
#    return $new;
#  } else {
#    for my $j ($newsize .. $size-1) { &$setfunc($arrayptr, $j, 0); }
#    $self->len($newsize);
#    return $self;
#  }
#}

1;
__END__

=pod

=head1 SEE ALSO

L<perlxs(1)>, L<perlfunc/tie>, L<Tie::Array(3)>, L<Geometry::Points(3)>,
L<C::Dynalib::Poke(3)>, L<Tie::MmapArray(3)>

=head1 TODO

Not all pack letters are implemented yet.

=head1 AUTHOR

Reini Urban <rurban@x-ray.at>

Andrew Ford wrote the arbitrary structure code.

=head1 COPYRIGHT

Copyright (c) 1999 Reini Urban.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 WARNING

The author makes B<NO WARRANTY>, implied or otherwise, about the
suitability of this software for safety or security purposes.

CArrays are now always ranged checked which cannot be turned off, so it's
not that dangerous anymore to read or write to not-owned memory areas.

The author shall not in any case be liable for special, incidental,
consequential, indirect or other similar damages arising from the use
of this software.

Your mileage will vary. If in any doubt B<DO NOT USE IT>. You've been warned.

=head1 BUGS

There are certainly some. Not fully tested yet.
Tests for copy, grow, delete, tie are pending.
Also some more conversion tests, esp. with double and degenerate
(grow, cut) cases.

=over

=item 1

realloc() in string_set() with DEBUGGING perl fails sometimes.

=item 2

An implicit DESTROY invocation sometimes asserts a DEBUGGING perl,
regardless if PERL_MALLOC or the WinNT msvcrt.dll malloc is used.
(5.00502 - 5.00558)
Esp. on perl shutdown, when freeing the extra objects at the second GC.

This became much better in 0.08 than in previous versions.

=back

This is alpha, not fully tested yet!

=head1 VERSION

$Revision 0.13 $ $Date 2008-01-20 $

=cut
