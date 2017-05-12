package Tie::Hash::Abbrev::BibRefs;

=head1 NAME

Tie::Hash::Abbrev::BibRefs - match bibliographic references to the original titles

=head1 SYNOPSIS

  use Tie::Hash::Abbrev::BibRefs;

  tie my %hash, 'Tie::Hash::Abbrev::BibRefs',
      preprocess => sub { s/\s+[[:upper:]]:.*// },
      stopwords  => [ qw( a and de del der des di
                          et for für i if in la las
                          of on part Part Pt. Sect.
                          the to und ) ],
      exceptions => { jpn => 'japan',
                      natl => 'national' };

  $hash{'Physical Review B'} = '0163-1829';

  print $hash{'Phys. Rev. B: Condens. Matter Mater. Phys.'};
    # will print '0163-1829'

=head1 DESCRIPTION

This module is an attempt to ease the mapping of often abbreviated
bibliographical references to the original titles.

To achieve this, it simplyfies the title according to parameterizable rules and 
stores it as a I<normalized key>.

When accessing the hash, the key given is also L<normalized|/"KEY NORMALIZATION">
and compared to the normalized version of the original title.
In addition, each word (words are separated by whitespace) may be abbreviated by
specifying only the first few letters.

If more than one matching hash entry is found, the values of all matching
entries are compared; as long as they are all
L<eq|perlop/"Equality Operators">ual (or all L<undef|perlfunc/undef>), the
lookup is still considered to be successful.

=head1 KEY NORMALIZATION

The process of normalization is implemented as follows:

=over 4

=item 1.

execute any preprocessing code (see L<example above/SYNOPSIS>), which is
expected to operate on C<$_>.
You can use subroutine references or strings here; strings will be
L<eval()uated|perlfunc/eval>.

=item 2.

split the key into parts (at whitespace).

=item 3.

remove any parts contained in the list of stopwords
(see L<example above|/SYNOPSIS>).

=item 4.

replace any parts contained in the list of exceptions
by their corresponding value.
If the value is L<undef|perlfunc/undef>, the entire part will be removed.
(In the L<example above|/SYNOPSIS>, "Jpn" would be replaced by "japan".)
This lookup is done case-insensitively.

=item 5.

remove any non-word characters at the end of each part or followed by a dash

=back

=cut

use strict;
use vars '$VERSION';

use Carp 'croak';

$VERSION = 0.02;

use constant DATA       => 0;
use constant I          => 1;
use constant PREPROCESS => 2;
use constant STOPWORDS  => 3;
use constant EXCEPTIONS => 4;
use constant DEBUG      => 5;

sub TIEHASH {
    croak 'Odd number of arguments.' unless @_ & 1;
    my $package = shift;
    $package = ref $package if length ref $package;
    my $self = bless [], $package;
    $self->[DATA] = [];
    while (@_) {
        my ( $option, $argument ) = splice @_, 0, 2;
        if ( $option eq 'debug' ) { $self->debug($argument) }
        elsif ( $option =~ /^exceptions?\z/ ) { $self->exceptions($argument) }
        elsif ( $option eq 'preprocess' ) { $self->preprocess($argument) }
        elsif ( $option =~ /^stopwords?\z/ ) {
            $self->stopwords( ref $argument ? @$argument : $argument );
        }
        else { croak qq(Unknown TIEHASH option "$option"!) }
    }
    $self;
}

sub FETCH {
    my ( $self, $key ) = @_;
    if ( defined( my $found = $self->find($key) ) ) { $self->[DATA][$found] }
    else { undef }
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    if (
        defined $self->exact(
            $key, my $pos = $self->pos( my $normkey = $self->normalize($key) )
        )
      )
    {
        $self->[DATA][ $pos + 1 ] = $value;
    }
    else { splice @{ $self->[DATA] }, $pos, 0, $normkey, $value, $key }
}

sub EXISTS {
    my ( $self, $key ) = @_;
    if ( defined $self->find($key) ) { 1 }
    else { '' }
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $pos = $self->pos( my $normkey = $self->normalize($key) );
    if ( defined $self->exact( $key, $pos ) ) {
        ( undef, my $value ) = splice @{ $self->[DATA] }, $pos, 3;
        $self->startover;
        $value;
    }
    else { undef }
}

sub CLEAR {
    my ($self) = @_;
    $self->startover;
    @{ $self->[DATA] } = ();
}

sub FIRSTKEY {
    my ($self) = @_;
    return undef unless @{ $self->[DATA] };
    $self->[ $self->[I] = 2 ];
}

sub NEXTKEY {
    my ( $self, $lastkey ) = @_;
    if ( ( my $i = $self->[I] += 3 ) <= $#{ $self->[DATA] } ) {
        $self->[DATA][$i];
    }
    else {
        $self->startover;
        undef;
    }
}

sub UNTIE { }

sub DESTROY { shift->startover }

=head1 ADDITIONAL METHODS

=head2 debug

turn debug mode on (when given a true value as argument) or off
(when given a false value).
Returns the (possibly new) value.

In debug mode, the L</find> method will print debug messages to STDERR.

=cut

sub debug {
    my $self = shift;
    $self->[DEBUG] = shift if @_;
    $self->[DEBUG];
}

=head2 delete_abbrev

  my @deleted = tied(%hash)->delete_abbrev('foo','bar');

Will delete all elements on the basis of all unambiguous abbreviations given as
arguments and return a (possibly empty) list of all deleted values.

=cut

sub delete_abbrev {
    my $self = shift;
    my @deleted;
    for (@_) {
        next
          unless
          defined( my $pos1 = $self->valid( $_, my $pos = $self->pos($_) ) );
        my $i = 0;
        push @deleted, grep $i++ & 1, splice @{ $self->[DATA] }, $pos,
          3 + $pos1 - $pos;
    }
    $self->startover if @deleted;
    @deleted;
}

=head2 exceptions

get or set the exceptions table for the hash.
Expects hash references or L<undef|perlfunc/undef>, which clears the table.
Returns a reference to the new exception table.

=cut

sub exceptions {
    my $self = shift;
    for (@_) {
        if (defined) {
            while ( my ( $k, $v ) = each %$_ ) {
                $self->[EXCEPTIONS]{ lc $k } = lc $v;
            }
        }
        else { $self->[EXCEPTIONS] = {} }
    }
    $self->[EXCEPTIONS] || {};
}

=head2 preprocess

set up the preprocessing code chain for the hash.
Any code references or strings will be added to the chain,
an L<undef|perlfunc/undef> will clear the chain.

=cut

sub preprocess {
    my $self = shift;
    for (@_) {
        if (defined) { push @{ $self->[PREPROCESS] }, $_ }
        else { @{ $self->[PREPROCESS] } = [] }
    }
    @{ $self->[PREPROCESS] || [] };
}

=head2 stopwords

get or set the /stopwords for the hash.
Any arguments given will be added to the list of stopwords.
An L<C<undef>> as argument will clear the list of stopwords.
The method returns the new list of stopwords (in an unsorted manner).

=cut

sub stopwords {
    my $self = shift;
    for (@_) {
        if (defined) { $self->[STOPWORDS]{$_} = undef }
        else { $self->[STOPWORDS] = {} }
    }
    keys %{ $self->[STOPWORDS] || {} };
}

=head1 INTERNAL METHODS

The following methods should usually not be called "from the outside";
the main intention of ducumenting them is that the author still wants to
understand his own module in case changes will be neccessary later. :o)

=head2 exact

expects a key as first and a L<position|/pos> as second argument.
Returns the position if the given key equals (case-insensitively) the real key
stored at that position or undef if not.

=cut

sub exact {
    my ( $self, $key, $pos ) = @_;
    if ( $pos < $#{ $self->[DATA] } && lc $self->[DATA][ $pos + 2 ] eq lc $key )
    {
        $pos;
    }
    else { undef }
}

=head2 find

This is the central method for lookups, used by L<exists()|perlfunc/exists> and
C<FETCH>.

It expects a key as its only argument.

Upon success, the method returns an array index at which the corresponding value
can be found, or undef otherwise.

=cut

sub find {
    my ( $self, $key ) = @_;
    my $debug = $self->debug;
    my ( $prefix, $pattern, $normkey ) = $self->normalize($key);
    print STDERR <<_ if $debug;
--------------------------------------------------------------------------------
Key:     <$key>
Prefix:  <$prefix>
Pattern: <$pattern>
NormKey: <$normkey>
_
    defined( my $pos = $self->pos($prefix) ) or return undef;
    my $data = $self->[DATA];
    print STDERR 'Starting search at entry #'
      . ( $pos / 3 )
      . (
        $pos ? qq(; the key before that would be: "$data->[$pos-3]"\n) : ".\n" )
      if $debug;
    my $found;
    do {
        print STDERR 'Examining entry #'
          . ( $pos / 3 )
          . qq(: "$data->[$pos]"... )
          if $debug;
        if ( $data->[$pos] =~ $pattern ) {
            if ( lc $data->[ $pos + 2 ] eq lc $key ) {
                print STDERR "exact match.\n" if $debug;
                return $pos + 1;
            }
            unless ( defined $found ) {
                $found = $pos + 1;
                print STDERR qq( matches, value: "$data->[$found]"\n)
                  if $debug;
            }
            elsif (
                defined $data->[$found]
                ? !defined $data->[ $pos + 1 ]
                || $data->[ $pos + 1 ] ne $data->[$found]
                : defined $data->[ $pos + 1 ]
              )
            {
                print STDERR
qq( also matches, but has a different value: "$data->[$pos+1]"\n)
                  if $debug;
                return;
            }
        }
        else { print STDERR "does not match.\n" if $debug }
      } while ( $pos += 3 ) < $#$data
      && $prefix eq substr $data->[$pos], 0, length $prefix;
    print STDERR $pos > $#$data ? "Last element reached.\n"
      : qq("$data->[$pos]" has a different prefix.\n),
      defined $found ? "Search was successful.\n"
      : "Search was NOT successful.\n"
      if $debug;
    $found;
}

=head2 normalize

Given a key as the its only argument,
this method will return the normalized key in scalar
and a three element list in array context, consisting of

=over 4

=item 0.

the L</prefix>

=item 1.

the L</"search pattern"> and

=item 2.

the L</"normalized key">.

=back

=cut

sub normalize {
    my ( $self, $key ) = @_;
    my ( $exceptions, $stopwords ) = @{$self}[ EXCEPTIONS, STOPWORDS ];
    local $_ = $key;
    for my $pp ( $self->preprocess ) {
        if ( ref $pp ) { &$pp }
        else { eval $pp }
    }
    (
        my $normkey =
          join ' ',
        map exists $exceptions->{ +lc }
        ? defined $exceptions->{ +lc } ? $exceptions->{ +lc } : ()
        : lc,
        grep !exists $stopwords->{$_},
        split /\s+|-/
    ) =~ s/\W+(?=\s|-|$)//g;
    return $normkey unless wantarray;
    my ($prefix) = $normkey =~ /^([^\s-]*)/;
    my $pattern = '^'
      . join ( ' ', map quotemeta() . '\S*', split /\s+|-/, $normkey ) . '$';
    $prefix, $] < 5.006 ? $pattern : eval 'qr/$pattern/', $normkey;
}

=head2 pos

expects an (usually L<normalized|/"normalized key">) key as (its only) argument
and returns the position at which this key is stored (if it exists)
or should be sorted (if it does not already exist).

=cut

sub pos {
    my ( $self, $key ) = @_;
    my $data = $self->[DATA];
    my $a    = 0;
    my $b    = @$data;
    while ( $a < $b && $a < $#$data ) {    # perform a binary search
        if ( $data->[ my $c = 3 * int +( $a + $b >> 1 ) / 3 ] lt $key ) {
            $a = $c + 3;
        }
        else { $b = $c }
    }
    $a;
}

=head2 startover

expects no arguments and simply resets the iterator for the hash,
so that the next call to L<each()|perlfunc/each> will return the first key/value
pair again.

=cut

sub startover {
    my ($self) = @_;
    $self->[I] = undef;
}

=head1 BUGS

None known so far.

=head1 AUTHOR

	Martin H. Sluka
	mailto:martin@sluka.de
	http://martin.sluka.de/

=head1 THANKS TO

Dr. Hermann Schier from the Max Planck Institute for Solid State Research
in Stuttgart/Germany for initiating and underwriting the development of this
module and for contribution a lot of ideas.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Tie::Hash::Array>

=cut

1
