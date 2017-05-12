package Test::LectroTest::Generator;
{
  $Test::LectroTest::Generator::VERSION = '0.5001';
}

use strict;
use warnings;

use Carp;

BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    my @gens     = qw( &Int &Bool &Char &String &List &Hash
                       &Float &Elements &Unit );
    my @combs    = qw( &Paste &OneOf &Frequency &Sized &Each
                       &Apply &Map
                       &Concat &Flatten &ConcatMap &FlattenMap );
    my @specials = qw( &Gen) ;

    @ISA         = qw(Exporter);
    @EXPORT      = ();
    @EXPORT_OK   = ( @gens, @combs, @specials);
    %EXPORT_TAGS = ( common      => [@gens]
                   , combinators => [@combs]
                   , all         => [@gens, @combs, @specials] );
}

our @EXPORT_OK;

=head1 NAME

Test::LectroTest::Generator - Random value generators and combinators

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

 use Test::LectroTest::Generator qw(:common :combinators);

 my $int_gen = Int;
 my $pct_gen = Int( range=>[0,100] );
 my $flt_gen = Float( range=>[0,1] );
 my $bln_gen = Bool;
 my $chr_gen = Char( charset=>"a-z" );
 my $str_gen = String( charset=>"A-Z0-9", length=>[3,] );
 my $ary_gen = List( Int(sized=>0) );
 my $hsh_gen = Hash( $str_gen, $pct_gen );
 my $uni_gen = Unit( "e" );  # always returns "e"
 my $elm_gen = Elements("e1", "e2", "e3", "e4");

 for my $sizing_guidance (1..100) {
     my $i = $int_gen->generate( $sizing_guidance );
     print "$i ";
 }
 print "\n";

 # generates single digits
 my $digit_gen  = Elements( 0..9 );  # or Int(range=>[0,9],sized=>0)

 # generates SSNs like "910-77-2236"
 my $ssn_gen    = Paste( Paste( ($digit_gen) x 3 ),
                         Paste( ($digit_gen) x 2 ),
                         Paste( ($digit_gen) x 4 ),
                         glue => "-"                );

 # print 10 SSNs
 print( map {$ssn_gen->generate($_)."\n"} 1..10 );

 my $english_dist_vowel_gen =
     Frequency( [8.167,Unit("a")], [12.702,Unit("e")],
                [6.996,Unit("i")], [ 7.507,Unit("o")],
                [2.758,Unit("u")] );
     # Source: http://www.csm.astate.edu/~rossa/datasec/frequency.html

=head1 DESCRIPTION

This module provides random value generators for common data types and
provides an interface and tools for creating your own generators.  It
also provides generator combinators that can be used to create
more-complex generators by combining simple ones.


A generator is an object having a method C<generate>, which takes a
single argument, I<size> and returns a new random value.  The
generated value is always a scalar.  Generators that produce data
structures return references to them.

=head2 Sizing guidance

The C<generate> method interprets its I<size> argument as guidance
about the complexity of the value it should create.  Typically,
smaller I<size> values result in smaller generated numbers and shorter
generated strings and lists.  Some generators, for which sizing
doesn't make sense, ignore sizing guidance altogether; those that do
use sizing guidance can be told to ignore it via the B<sized>
modifier.

The purpose of sizing is to allow LectroTest to generate simple values
at first and then, as testing progresses, to slowly ramp up the
complexity.  In this way, counterexamples for obvious problems
will be easier for you to understand.

=cut



#==============================================================================
# modifier defaults


our %defaults = (
    Int    => { range => [-32768  , 32767  ], sized => 1 },
    Float  => { range => [-32768.0, 32767.0], sized => 1 },
    List   => { length => undef },
    Char   => { charset => "\x00-\x7f", },
    String => { },
    Paste  => { glue => "" },
);

#==============================================================================
# methods

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub generate {
    my ($self, $size) = @_;
    return scalar $self->{generator}->($size);
}

#==============================================================================
# helpers

sub _defargs {
    my $gen_name = shift;
    shift while ref($_[0]);  # skip template, if any
    return { %{$defaults{$gen_name}}, @_  };
}

sub _template {
    my $tmpl = [];
    push @$tmpl, shift while ref($_[0]);
    return $tmpl;
}


#==============================================================================
# plain old functions

sub Gen(&) {
    my ($genfn) = @_;
    return Test::LectroTest::Generator->new(generator=>$genfn);
}

=pod

=head2 Generators

The following functions create fully-formed generators, ready to use.
These functions are exported into your code's namespace if you ask for
C<:generators> or C<:all> when you C<use> this module.

Each generator has a C<generate> method that you can call to extract
a new, random value from the generator.

=over 4

=item Int

    my $gen = Int( range=>[0,9], sized=>0 );

Creates a generator for integer values, by default in the range [-32768,32767],
inclusive, but this can be changed via the optional B<range> modifier.

=over 4

=item Int( range=>[I<low>, I<high>] )

Causes the generated values to be constrained to the range [I<low>,
I<high>], inclusive.  By default, the range is [-32768, 32767].

B<Note:> If your range is empty (i.e., I<low> E<gt> I<high>),
LectroTest will complain.

B<Note:> If zero is not within the range you provide, sizing makes no
sense because the intersection of your range and the sizing range can
be empty, and thus you must turn off sizing with C<sized=E<gt>0>.
If you forget, LectroTest will complain.


=item Int( sized=>I<bool> )

If true (the default), constrains the absolute value of the generated
integers to the sizing guidance provided to the C<generate> method.
Otherwise, the generated values are constrained only by the range.

=back



=cut

sub Int(@) {
    my $args = _defargs("Int", @_);
    my ($sized, $rlo, $rhi) = ($args->{sized}, map int, @{$args->{range}});
    croak "range=>[$rlo,$rhi] is empty" if $rlo > $rhi;
    if (!$sized) {
        # if unsized, use this simpler generator
        my $span = $rhi - $rlo + 1;
        return Gen {
            return $rlo + int(rand($span));
        };
    }
    # otherwise, provide a sizing-capable generator
    croak "the given range=>[$rlo,$rhi] does not contain zero "
        . "and cannot be used with a sized generator"
        if 0 < $rlo || 0 > $rhi;
    return Gen {
        my ($lo, $hi) = ($rlo, $rhi);
        my $size = shift;
        if (defined $size) {
            $size = int( $size + 0.5 );
            $lo = -$size if -$size > $lo;
            $hi =  $size if  $size < $hi;
        }
        return $lo + int(rand($hi - $lo + 1));
    };
}

=pod

=item Float

    my $gen = Float( range=>[-2.0,2.0], sized=>1 );

Creates a generator for floating-point values, by default in the range
[-32768.0,32768.0), but this can be changed via the optional B<range> modifier.
By default Float generators are sized.

=over 4

=item Float( range=>[I<low>, I<high>] )

Causes the generated values to be constrained to the range [I<low>,
I<high>).  By default, the range is [-32768.0,32768.0).  (Note that
the I<high> value itself can never be generated, but values
infinitesimally close to it can.)


B<Note:> If your range is empty (i.e., I<low> E<gt> I<high>),
LectroTest will complain.

B<Note:> If zero is not within the range you provide, sizing makes no
sense because the intersection of your range and the sizing range can
be empty, and thus you must turn off sizing with C<sized=E<gt>0>.
If you forget, LectroTest will complain.

=item Float( sized=>I<bool> )

If true (the default), constrains the absolute value of the generated
values to the sizing guidance provided to the C<generate> method.
Otherwise, the generated values are constrained only by the range.

=back

=cut

sub Float(@) {
    my $args = _defargs("Float", @_);
    my ($sized, $rlo, $rhi) = ($args->{sized}, @{$args->{range}});
    croak "range=>[$rlo,$rhi] is empty" if $rlo > $rhi;
    if (!$sized) {
        # if unsized, use this simpler generator
        my $span = $rhi - $rlo;
        return Gen {
            return $rlo + rand($span);
        };
    }
    # otherwise, provide a sizing-capable generator
    croak "the given range [$rlo,$rhi] does not contain zero "
        . "and cannot be used with a sized generator"
        if $rlo > 0 || 0 > $rhi;
    return Gen {
        my ($lo, $hi) = ($rlo, $rhi);
        my $size = shift;
        if (defined $size) {
            $lo = -$size if -$size > $lo;
            $hi =  $size if  $size < $hi;
        }
        return $lo + rand($hi - $lo);
    };
}

=pod

=item Bool

    my $gen = Bool;

Creates a generator for boolean values: 0 for false, 1 for true.
The generator ignores sizing guidance.

=cut

sub Bool(@) {
    return Int( @_, range=>[0,1], sized=>0 );
}

=pod

=item Char

    my $gen = Char( charset=>"A-Za-z0-9_" );

Creates a generator for characters.  By default the characters are in
the ASCII range [0,127], inclusive, but this behavior can be changed
with the B<charset> modifier:

=over 4

=item Char( charset=>I<cset> )

Characters will be drawn from the character set given by the
character-set specification I<cset>.  The syntax of I<cset> is
similar the Perl C<tr> built-in and is a string comprised of
characters and character ranges:

=over 4

=item I<c>

Adds the character I<c> to the set.

=item I<c>-I<d>

Adds the characters in the range I<c> through I<d> (inclusive) to the
set.  Note: If I<c> is lexicographically greater than I<d>, the range
is empty, and no characters will be added to the set.

=back

Examples:

=over 4

=item charset=>"abcdwxyz"

The characters "a", "b", "c", "d", "w", "x", "y", and "z" are in the set.

=item charset=>"a-dx-z"

Shorter version of the previous example.

=item charset=>"\x00-\x7f"

The ASCII character set.

=item charset=>"-_A-Za-z0-9"

The character set contains "-", "_", upper- and lower-case
ASCII letters, and the digits 0-9.  Notice that the dash must
occur first so that it is not misinterpreted as denoting
a range of characters.

=back

=back

=cut

sub _to_range($) {
    my ($lo, $hi) = @{shift()}[0,1];
    [ map {chr} ord$lo .. ord $hi ]
}

sub _parse_charset($) {
    local ($_) = @_;
    my @ranges;
    while (/(.)(?:-(.))?/sg) {
        push @ranges, [$1, defined $2 ? $2 : $1];
    }
    [ sort keys %{{ map {($_,1)} map {@{_to_range($_)}} @ranges }} ]
}

sub Char(@) {
    my $cset = _defargs("Char", @_)->{charset};
    return Elements( @{ _parse_charset($cset) } )
}

=pod

=item List(I<elemgen>)

    my $gen = List( Bool, length=>[1,10] );

Creates a generator for lists (which are returned as array refs).  The
elements of the lists are generated by the generator given as
I<elemgen>.  The lengths of the generated lists are constrained by
sizing guidance at the time of generation.  You can override the
default sizing behavior using the optional B<length> modifier:

When the list generator calls the element generator, it divides the
sizing guidance by the length of the list.  For example, if the list
being generated will have 7 elements, when the list generator calls
the element generator to generate each element, it will scale the
sizing guidance by 1/7.  In this way the sizing guidance provides
a rough constraint on the total number of elements produced,
regardless of the depth of the list structure being generated.

=over 4

=item List( ..., length=>I<N> )

Generated lists are exactly length I<N>.

=item List( ..., length=>[I<M>,] )

Generated lists are at least length I<M>.  (Maximum length is
constrained by sizing factor.)

=item List( ..., length=>[I<M>,I<N>] )

Generated lists are of length between I<M> and I<N>, inclusive.
Sizing guidance is ignored.

=back

B<Advanced Note:> If more than one I<elemgen> is given, they will be
used in turn to create successive elements. In this case, the length
of the list will be multiplied by the number of generators given.  For
example, providing two generators will create double-length lists.

=cut


sub List(@) {
    my $template = _template(@_);
    my $builder = sub {
        my ($len, $size) = @_;
        my $subsize = defined $size ? $size / ($len+1) : 1;
        my @list;
        foreach (1..$len) {
            foreach my $generator (@$template) {
                push @list, $generator->generate($subsize);
            }
        }
        return \@list;
    };

    # return generator customized for length specification

    my $lenspec = _defargs("List", @_)->{length};

    # case 0: length=>undef
    if ( ! defined $lenspec ) {
        $lenspec = [0,];  # convert into case 2
    }
    # case 1: length=>N
    if ( ! ref($lenspec) ) {
        my $n = $lenspec;
        croak "length=>$n can't be < 0" if $n < 0;
        return Gen {
            return $builder->($lenspec, @_);
        }
    }
    # case 2: length=>[M,]
    elsif ( ref($lenspec) eq 'ARRAY' && @$lenspec == 1 ) {
        my ($m) = @$lenspec;
        croak "length=>[$m,] can't be < 0" if $m < 0;
        return Gen {
            my ($size) = @_;
            return $builder->( $m >= $size
                                 ? $m
                                 : $m + int(rand($size - $m + 1)),
                               @_);
        };
    }
    # case 3: length=>[M,N]
    elsif ( ref($lenspec) eq 'ARRAY' && @$lenspec == 2 ) {
        my ($m,$n) = @$lenspec;
        croak "length=>[$m,$n]) is invalid" if $m > $n || $m < 0;
        return Gen {
            return $builder->( $m + int(rand($n - $m + 1)), @_ )
        };
    }
    # case 4: bad length specification
    else {
        croak "length specification length=>$lenspec is bad";
    }
}

=pod

=item Hash(I<keygen>, I<valgen>)

    my $gen = Hash( String( charset=>"A-Z", length=>3 ),
                    Float( range=>[0.0, 100.0] );

Creates a generator for hashes (which are returned as hash refs).  The
keys of the hash are generated by the generator given as I<keygen>,
and the values are generated by the generator I<valgen>.

The Hash generator takes an optional B<length> modifier that
specifies the desired hash length (= number of keys):

=over 4

=item Hash( ..., length=>I<length-spec> )

Specifies the desired length of the generated hashes, using the same
I<length-spec> syntax as for the List generator.  Note that the
generated hashes may be smaller than expected because of key
collision.

=back

=cut

sub Hash(@) {
    croak "Hash(keygen,valgen,...) requires two generators"
        unless @{_template(@_)} == 2;
    my $listgen = List(@_);
    return Gen {
        return { @{$listgen->generate(@_)} }
    };
}

=pod

=item String

    my $gen = String( length=>[3,], charset=>"A-Z" );

Creates a generator for strings.  By default the strings will
be drawn from the ASCII character set (0 through 127) and
be of length constrained by the sizing factor.  Both defaults
can be changed using modifiers:

=over 4

=item String( charset=>I<cset> )

Characters will be drawn from the character set given by the
character-set specification I<cset>.  The syntax of I<cset> is
similar the Perl C<tr> operator and is a string comprised of
characters and character ranges.  See Char for a full
description.

=item String( length=>I<length-spec> )

Specifies the desired length of generated strings, using the same
I<length-spec> syntax as for the List generator.

=back

=cut

sub String(@) {
    my $args = _defargs("String", @_);
    my ($cset, $length) = @$args{qw(charset length)};
    my $lcgen = List(Char(defined $cset ? (charset=>$cset) : ()),
                     defined $length ? (length=>$length) : ());
    return Gen {
        join "", @{$lcgen->generate(@_)};
    }
}

=pod

=item Elements(I<e1>, I<e2>, ...)

    my $gen = Elements( "alpha", "beta", "gamma" );

Creates a generator that chooses among the given elements I<e1>, I<e2>,
... with equal probability.  Each call to the C<generate> method will
return one of the element values.  Sizing guidance has no effect on
this generator.

B<Note:> This generator builder does not accept modifiers.  If you
pass any, they will be interpreted as elements to be added to the pool
from which the generator randomly selects, which is probably not
what you want.

=cut

sub Elements(@) {
    croak "Elements(e...) must be given at least one element" unless @_;
    return OneOf( map {Unit($_)} @_ );
}

=pod

=item Unit(I<e>)

    my $gen = Unit( "alpha" );

Creates a generator that always returns the value I<e>.  Not too
useful on its own but can be handy as a building block for combinators
to chew on.  Naturally, sizing guidance has no effect on this
generator.

B<Note:> This generator builder does not accept modifiers.

=cut

sub Unit($) {
    my ($e) = @_;
    return Gen {
        return $e;
    }
}


=pod

=back






=head2 Generator combinators

The following combinators allow you to build more complicated
generators from simpler ones.  These combinators are exported into
your code's namespace if you ask for C<:combinators> or C<:all> when
you C<use> this module.


=over 4

=item Paste(I<gens>..., glue=>I<str>)

    my $gen = Paste( (String(charset=>"0-9",length=>4)) x 4,
                     glue => " " );
    # gens credit-card numbers like "4592 9459 9023 1369"

    my $lgen = Paste( List( String(charset=>"0-9",length=>4)
                          , length=>4 ), glue => " " );
    # another way of doing the same

Creates a combined generator that generates values by joining the
values generated by each of the supplied sub-generators I<gens>.
(Generated list values will have their elements "flattened" into the
rest of the generated results before joining.) The resulting string is
returned.

The values are joined using the given glue string I<str>.  If no
B<glue> modifier is provided, the default glue is the empty string.

The sizing guidance given to the combined generator will
be passed unchanged to each of the sub-generators.

=cut

sub Paste(@) {
    my @gens = @{_template(@_)};
    my $glue = _defargs("Paste", @_)->{glue};
    Apply( sub { join $glue, map @$_, @_ }, Flatten(@gens) );
}

=pod

=item OneOf(I<gens>...)

    my $gen = OneOf( Unit(0), List(Int,length=>3) );
    # generates scalar 0 or a 3-element list of integers

Creates a combined generator that generates each value by selecting at
random (with equal probability) one of the sub-generators in I<gens>
and using that generator to generate the output value.

The sizing guidance given to the combined generator will be passed
unchanged to the selected sub-generator.

B<Note:> This combinator does not accept modifiers.

=cut


sub OneOf(@) {
    my $gens  = \@_;
    my $igen  = Int(sized=>0,range=>[0, @_-1]);
    return Gen {
        return $gens->[$igen->generate]->generate(@_);
    }
}

=pod

=item Frequency([I<freq1>, I<gen1>], [I<freq2>, I<gen2>], ...)

    my $gen = Frequency( [50, Unit("common"     )],
                         [35, Unit("less common")],
                         [15, Unit("uncommon"   )] );
    # generates one of "common", "less common", or
    # "uncommon" with respective probabilities
    # 50%, 35%, and 15%.

Creates a combined generator that generates each value by selecting at
random one of the generators I<gen1> or I<gen2> or ... and using that
generator to generate the output value.  Each generator is selected
with probability proportional to its associated frequency.  (If all of
the given frequencies are the same, the Frequency combinator
effectively becomes OneOf.)  The frequencies can be any non-negative
numerical values you want and will be normalized to a 0-to-1 scale
internally.  At least one frequency must be greater than zero.

The sizing guidance given to the combined generator will be passed
unchanged to the selected sub-generator.

B<Note:> This combinator does not accept modifiers.

=cut

sub Frequency(@) {
    my @freqs = map {$_->[0]} @_;
    my @gens  = map {$_->[1]} @_;
    if ((my @baddies = grep {$_ < 0} @freqs)) {
        croak "frequencies must be non-negative; got $baddies[0]";
    }
    my $total = 0;
    $total += $_ foreach @freqs;
    unless ($total) {
        croak "at least one frequency must be greater than zero";
    }
    @freqs = map {$_/$total} @freqs;  # normalize to [0,1] scale
    $total = 0;
    $_ = $total += $_ for (@freqs);   # turn into cumulative freqs
    $freqs[-1] = 1;                   # just in case of round-off error
    return Gen {
        my $r = rand;
        my $i = 0;
        $i++ while $freqs[$i] < $r;
        return $gens[$i]->generate(@_);
    }
}

=pod

=item Each(I<gens>...)

    my $gen = Each( Unit(1), Unit("X") );
    # always generates [ 1, "X" ]

Creates a generator that returns a list (array ref) whose
successive elements are the successive values generated
by the given generators I<gens>.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> This combinator does not accept modifiers.

(Note for technical buffs: C<Each(...)> is exactly equivalent to
C<List(..., length=E<gt>1)>).

=cut

sub Each(@) {
    return List( @_, length=>1 );
}


=pod

=item Apply(I<fn>, I<gens>...)

    my $gen = Apply( sub { $_[0] x $_[1] }
                   , Unit("X"), Unit(4) );
    # always generates "XXXX"

Creates a generator that applies the given function I<fn> to arguments
generated from each of the given sub-generators I<gens> and returns
the resulting value.  Each sub-generator contributes one value, and
the values are passed to I<fn> as arguments in the same order as the
sub-generators were given to Apply.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> The function I<fn> is always evaluated in scalar context.
If you need to generate an array, return it as an array reference.

B<Note:> This combinator does not accept modifiers.


=cut

sub Apply(&@) {
    my $f = shift;
    my $g = Each( @_ );
    return Gen {
        scalar $f->( @{$g->generate(@_)} )
    };
}

=pod

=item Map(I<fn>, I<gens>...)

    my $gen = Map( sub { "X" x $_[0] }
                 , Unit(4), Unit(3), Unit(0) );
    # always generates [ "XXXX", "XXX", "" ]

Creates a generator that applies the given function I<fn> to the
values generated by the given generators I<gen> one at a time and
returns a list (array ref) whose elements are each of the successive
results.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> The function I<fn> is always evaluated in scalar context.
If you need to generate an array, return it as an array reference.

B<Note:> This combinator does not accept modifiers.

=cut

sub _Map {
    my $f = shift;
    my $g = Each( @_ );
    return Gen {
        [ map { scalar $f->($_) } @{ $g->generate(@_) } ]
    };
}

sub Map(&@) {
    _Map(@_);
}

=pod

=item Concat(I<gens>...)

    my $gen = Concat( List( Unit(1),   length=>3 )
                    , List( Unit("x"), length=>1 ) );
    # always generates [1, 1, 1, "x"]

Creates a generator that concatenates the values generated by each of
its sub-generators, resulting in a list (which is returned as a array
reference).  The values returned by the sub-generators are expected to
be lists (array refs).  If a sub-generator returns a scalar value, it
will be treated like a single-element list that contains the value.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> If a sub-generator returns something other than a list or
scalar, you will get a run-time error.

B<Note:> This combinator does not accept modifiers.

=cut

# we'll use this helper in Flatten and ConcatMap (and Paste)

sub _concat(@) {
    [ map { ref($_) ? @{$_} : ($_) } @_ ];
}

sub Concat(@) {
    Apply( \&_concat, @_ );
}


=pod

=item Flatten(I<gens>...)

    my $gen = Flatten( Unit( [[[[[[ 1 ]]]]]] ) );
    # generates [1]

Flatten is just like Concat except that it recursively flattens any
sublists generated by the generators I<gen> and then concatenates them
to generate a final a list of depth one, regardless of the depth
of any sublists.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> If a sub-generator returns something other than a list or
scalar, you will get a run-time error.

B<Note:> This combinator does not accept modifiers.

=cut

sub _flatten(@);
sub _flatten(@) {
    _concat map { ref($_) ? _flatten(@$_) : ($_) } @_ ;
}

sub Flatten(@) {
    Apply( \&_flatten, @_ );
}

=pod

=item ConcatMap(I<fn>, I<gens>)

    sub take_odds { my $x = shift;
                    $x % 2 ? [$x] : [] }
    my $gen = ConcatMap( \&take_odds
                       , Unit(1), Unit(2), Unit(3) );
    # generates [1, 3]

Creates a generator that applies the function I<fn> to each of the
values generated by the given generators I<gen> in turn, and then
concatenates the results.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> The function I<fn> is always evaluated in scalar context.
If you need to generate an array, return it as an array reference.

B<Note:> If a sub-generator returns something other than a list or
scalar, you will get a run-time error.

B<Note:> This combinator does not accept modifiers.

=cut

sub ConcatMap(&@) {
    my $g = _Map( @_ );
    return Gen {
        _concat @{ $g->generate( @_ ) };
    };
}


=pod

=item FlattenMap(I<fn>, I<gens>)

    my $gen = FlattenMap( sub { [ ($_[0]) x 3 ] }
                        , Unit([1]), Unit([[2]]) );
    # generates [1, 1, 1, 2, 2, 2]

Creates a generator that applies the function I<fn> to each of the
values generated by the given generators I<gen> in turn, and then
flattens and concatenates the results.

The sizing guidance given to the combined generator will be passed
unchanged to each sub-generator.

B<Note:> The function I<fn> is always evaluated in scalar context.
If you need to generate an array, return it as an array reference.

B<Note:> If a sub-generator returns something other than a list or
scalar, you will get a run-time error.

B<Note:> This combinator does not accept modifiers.

=cut

sub FlattenMap(&@) {
    my $g = _Map( @_ );
    return Gen {
        _flatten @{ $g->generate( @_ ) };
    };
}


=pod

=item Sized(I<fn>, I<gen>)

    my $gen = Sized { 2 * $_[0] } List(Int);
        # ^ magnify sizing guidance by factor of two
    my $gen2 = Sized { 10 } Int;
        # ^ use constant guidance of 10

Creates a generator that adjusts sizing guidance by passing it through
the function I<fn>. Then it calls the generator I<gen> with the
adjusted guidance and returns the result.

B<Note:> This combinator does not accept modifiers.

=cut

sub Sized(&$) {
    my ($sizer, $gen) = @_;
    return Gen {
        return $gen->generate($sizer->(@_));
    };
}

=pod

=back

=head2 Rolling your own generators

You can create your own generators by creating any object that
has a C<generate> method.  Your method should accept as its
first argument sizing guidance I<size> and, if it makes sense,
adjust the complexity of the values it generates accordingly.

The easiest way to create a generator is by using the magic function
C<Gen>.  It promotes a block of code into a generator.  For example,
here's a home-brew generator for times in ctime(3) format that
is built on top of an Int generator:

  use Test::LectroTest::Generator qw( :common Gen );

  my $time_gen = Int(range=>[0, 2_147_483_647], sized=>0);
  my $ctime_gen = Gen {
      scalar localtime $time_gen->generate( @_ );
  };

  print($ctime_gen->generate($_), "\n") for 1..5;
  # Fri Jun  2 18:13:21 1978
  # Thu Mar 28 00:55:51 1974
  # Wed Mar 26 06:41:09 2025
  # Sun Sep 11 15:39:44 2016
  # Fri Dec 26 00:39:31 1975

Alternatively, we could build the generator using the Apply
combinator:

  my $ctime_gen2 = Apply { localtime $_[0] } $time_gen;


B<Note:> C<Gen> is not exported into your code's namespace by default.
If you want to use it, you must import it by name or import C<:all>
when you use this module.

=cut

1;



=head1 EXAMPLES

Here are some examples to consider.


=head2 Simple examples

 use strict;
 use Test::LectroTest::Generator qw(:common);

 show("Ints (sized by default)", Int);

 show("Floats (sized by default)", Float);

 show("Percentages (unsized)",
      Int( range=>[0,100], sized=>0 ));

 show("Lists (sized by default) of Ints (unsized) in [0,10]",
      List( Int( sized=>0, range=>[0,10] ) ));

 show("Uppercase-alpha identifiers at least 3 chars long",
      String( length=>[3,], charset=>"A-Z" ));


 show("Hashes (sized by default) of form AAA=>Digit",
      Hash( String( length=>3, charset=>"A-Z" ),
            Int( sized=>0, range=>[0,9] ) ));

 sub show {
     print "\n", shift(), "\n";
     my ($gen) = @_;
     for (1..10) {
         my $val = $gen->generate($_);
         printf "Size %2d:  ", $_;
         if (ref $val eq "HASH") {
             my @pairs = map {"$_=>$val->{$_}"} keys %$val;
             print "{ @pairs }";
         }
         elsif (ref $val eq "ARRAY") {
             print "[ @$val ]"
         }
         else {
             print $val;
         }
         print "\n";
     }
 }

=head2 Advanced examples

For these examples we use C<Data::Dumper> to inspect the data
structures we generate.  Also, we import not only the common generator
constructors (like Int) but also the generic Gen constructor, which
lets us build generators out of blocks on the fly.

    use Data::Dumper;
    use Test::LectroTest::Generator qw(:common Gen);

First, here's a recipe for building a list of lists of integers:

    my $loloi_gen = List( List( Int(sized=>0) ) );
    print Dumper($loloi_gen->generate(10));

You may want to run the example several times to get a feel
for the distribution of the generated output.

Now, a more complicated example.  Here we build sized trees of
random depth using a recursive set of generators.

    my $tree_gen = do {
        my $density = 0.5;
        my $leaf_gen = Int( sized=>0 );
        my $tree_helper = \1;
        my $branch_gen = List( Gen { $$tree_helper->generate(@_) } );
        $tree_helper = \Gen {
            my ($size) = @_;
            return rand($size) < $density
                ? $leaf_gen->generate($size)
                : $branch_gen->generate($size + 1);
        };
        $$tree_helper;
    };

    print Dumper($tree_gen->generate(30));

We define a tree as either a leaf or a branch, and we randomly decide
between the two at each node in the growing tree.  Leaves are just
integers and become more likely when the sizing guidance diminishes
(which happens as we go deeper).  The code uses C<$density> as a
control knob for leaf density.  (Try re-running the above code after
changing the value of C<$density>.  Try 0, 1, and 2.)  Branches,
on the other hand, are lists of trees.  Because branches generate
trees, and trees generate branches, we use a reference trick
to set up the mutually recursive relationship.  This we encapsulate
within a B<do> block for tidiness.


=head1 SEE ALSO

L<Test::LectroTest> gives a quick overview of automatic,
specification-based testing with LectroTest.


=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 INSPIRATION

The LectroTest project was inspired by Haskell's
QuickCheck module by Koen Claessen and John Hughes:
http://www.cs.chalmers.se/~rjmh/QuickCheck/.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-13 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
