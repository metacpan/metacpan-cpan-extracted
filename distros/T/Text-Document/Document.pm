
package Text::Document;

$Text::Document::VERSION = '1.08';

use strict;

use v5.6.0;

our @FIELDS = qw( lowercase );
our $COMPRESS_AVAILABLE;
our @KEYS_FOR_NEW = qw( compress lowercase );

BEGIN {
	eval "use Compress::Zlib;";
	if( $@ ){
		$COMPRESS_AVAILABLE = undef;
	} else {
		$COMPRESS_AVAILABLE = 1;
	}
}


sub new
{
	my $class = shift;
	my %self = @_;
	my $self = {
		lowercase	=> 1,
		compress	=> 1,
		terms		=> {},
	};
	foreach my $k ( @KEYS_FOR_NEW ){
		defined( $self{$k} )
			and ($self->{$k} = $self{$k});
	}

	bless $self, $class;
	return $self;
}

sub AddContent
{
	my $self = shift;
	my ($text) = @_;
# clear frequency cache
	$self->{freqs} and delete $self->{freqs};

# parse text fragment
	my @terms = $self->ScanV( $text );

# update word count
	foreach my $w (@terms){
		$self->{terms}->{$w} ++;
	}
	undef $self->{WeightedEuclideanNorm};
	undef $self->{EuclideanNorm};
	return scalar @terms;
}

# number of occurrences of a given term
sub Occurrences
{
	my $self = shift;
	my ($term) = @_;

	return $self->{terms}->{$term};
}

sub ScanV
{
	my $self =  shift;
	my ($text) = @_;
	my @words = split( /[^a-zA-Z0-9]+/, $text );
	@words = grep( /.+/, @words );
	if( $self->{lowercase} ){
		return map( lc($_), @words );
	} else {
		return @words;
	}
}

sub KeywordFrequency
{
	my $self = shift;

	return $self->{freqs} if $self->{freqs};

# all the distinct terms in the doc
	my @terms = $self->Terms();
# total number of terms
	my $sum = 0;
	foreach my $t (@terms) { $sum += $self->{terms}->{$t}; }
# if zero, frequency is not defined
	($sum > 0) or return undef;
# list of [term,frequency] pairs
	my @freqs = map( [$_, $self->{terms}->{$_}/$sum ] , @terms );
# sort by ascending frequency
	@freqs = sort { $a->[1] <=> $b->[1] } @freqs;

# return reference to result
	return $self->{freqs} = \@freqs;
}

# all distinct term names
sub Terms
{
	my $self = shift;
	return keys %{$self->{terms}};
}

# number of common terms divided by total number of terms
sub CommonTermsRatio
{
	my $self = shift;
	my ($other) = @_;
	my @terms = $self->Terms();
	my %terms;
	@terms{@terms} = 1 .. @terms;
	my @oTerms = $other->Terms();
	my (%union);
	@union{@terms} = 1 .. @terms;
	@union{@oTerms} = 1 .. @oTerms;
	my @intersection = map( ( $terms{$_} ? 1 : () ), @oTerms );
	my $unionCardinality = scalar( keys %union );
	($unionCardinality > 0) or return undef;
	return scalar(@intersection) /  $unionCardinality;
}

sub PureASCII
{
	my $self = shift;
	$self->{compress} = 1;
}

sub WriteToString
{
	my $self = shift;

	my $block = join( ',', %{$self->{terms}} );
	my $compressed = undef;
	if( $COMPRESS_AVAILABLE && $self->{compress} ){
		$block = Compress::Zlib::compress( $block );
#		$block = compress( $block );
		$compressed = 1;
	}
	my $header =
		'p='
		. __PACKAGE__
		. ' v='
		. $Text::Document::VERSION
		. ' l='
		. length( $block )
		. ' compress='
		. ($compressed?'1':'0')
		. ' '
		. join( ' ', map( "$_=$self->{$_}", @FIELDS))
		. "\n";

	my $str = $header . $block;

# add 8-char hex-encoded 4-byte checksum at the end of data
	return $str . sprintf( '%08x', unpack( '%32C*', $str ) );
}

sub NewFromString
{
	my ($str) = @_;

	my $self = {};

# verify checksum
# try to be compatible with version 1.03
	my $stored_checksum = unpack( 'N', substr( $str, -4 ));
	my $data_payload = substr( $str, 0, -4 );
	my $computed_checksum = unpack( '%32C*', $data_payload );

	if( $stored_checksum != $computed_checksum ){
		$stored_checksum = hex( substr( $str, -8 ));
		$data_payload = substr( $str, 0, -8 );
		$computed_checksum = unpack( '%32C*', $data_payload );
	}

	if( $stored_checksum != $computed_checksum ){
		die( __PACKAGE__ . '::NewFromString : '
			. 'checksum test failed '
			. $stored_checksum
			. ' != '
			. $computed_checksum
		);
	}

# split data in header and block
	my ($header,$block) = split( /\n/, $data_payload, 2 );

# parse header line
	my %header = split( /[ 	=]+/, $header );

# check that the reading package is the same as the one that wrote
	if( $header{p} ne __PACKAGE__ ){
		die( __PACKAGE__ . '::NewFromString : '
			. "file was not written by "
			. __PACKAGE__
		);
	}

# version must be identical
	if( $header{v} > $Text::Document::VERSION ){
		die( __PACKAGE__ . '::NewFromString : '
			. "Current version is $Text::Document::VERSION"
			. " and the file version is $header{v}"
		);
	}

# size of block must match
	if( $header{l} != length( $block ) ){
		die( __PACKAGE__ . '::NewFromString : '
			. "data size is "
			. length( $block )
			. "instead of $header{l} "
		);
	}

# compressed?
	if( $header{compress} and not($COMPRESS_AVAILABLE) ){
		die( __PACKAGE__ . '::NewFromString : '
			. 'header indicates that data is compressed, '
			. 'but Compress::Zlib is not available'
		);
	}

	if( $header{compress} ){
		$block = Compress::Zlib::uncompress( $block );
#		$block = uncompress( $block );
	}
	
	
	@{$self}{@FIELDS} = @header{ @FIELDS };

# retrieve terms and recurrence count
	%{$self->{terms}} = split( /,/, $block );

	bless $self, $header{p};

	return $self;
}

sub JaccardSimilarity
{
	my $self = shift;
	my ($e) = @_;

	my @inter = map(
		( $self->{terms}->{$_} ?  $_ : () ),
		keys %{$e->{terms}}
	);
	my %union =  %{$self->{terms}};
	my @keyse = keys %{$e->{terms}};
	@union{@keyse} = @keyse;
	if( (my $unionSize = scalar keys %union) > 0 ){
		return scalar(@inter) / $unionSize;
	} else {
		return undef;
	}
}

sub CosineSimilarity
{
	my $self = shift;
	my ($e) = @_;

	my ($Dv,$Ev) = ($self->{terms}, $e->{terms});
	my %union =  %{$self->{terms}};
	my @keyse = keys %{$e->{terms}};
	@union{@keyse} = @keyse;
	my $dotProduct = 0.0;
	map( $dotProduct += 
		(defined($Dv->{$_}) ? $Dv->{$_} : 0.0)
		* (defined($Ev->{$_}) ? $Ev->{$_} : 0.0 ),
		keys %union
	);

	my $nD = $self->EuclideanNorm();
	my $nE = $e->EuclideanNorm();

	if( ($nD==0) || ($nE==0) ){
		return undef;
	} else {
		return $dotProduct / $nD / $nE;
	}
}

sub EuclideanNorm
{
	my $self = shift;
	defined( $self->{EuclideanNorm} ) and return $self->{EuclideanNorm};
	my $sum = 0.0;
	map( $sum += $_*$_, values %{$self->{terms}} );
	return ($self->{EuclideanNorm} = sqrt( $sum ));
}

# this is rather rough
sub WeightedCosineSimilarity
{
	my $self = shift;
	my ($e,$weightFunction,$rock) = @_;

	my ($Dv,$Ev) = ($self->{terms}, $e->{terms});

# compute union
	my %union =  %{$self->{terms}};
	my @keyse = keys %{$e->{terms}};
	@union{@keyse} = @keyse;
	my @allkeys = keys %union;

# weighted D
	my @Dw = map(( defined( $Dv->{$_} )?
		&{$weightFunction}( $rock, $_ )*$Dv->{$_} : 0.0 ),
		@allkeys
	);

# weighted E
	my @Ew = map(( defined( $Ev->{$_} )?
		&{$weightFunction}( $rock, $_ )*$Ev->{$_} : 0.0 ),
		@allkeys
	);

# dot product of D and E
	my $dotProduct = 0.0;
	map( $dotProduct += $Dw[$_] * $Ew[$_] , 0..$#Dw );

# norm of D
	my $nD = 0.0;
	map( $nD += $Dw[$_] * $Dw[$_] , 0..$#Dw );
	$nD = sqrt( $nD );

# norm of E
	my $nE = 0.0;
	map( $nE += $Ew[$_] * $Ew[$_] , 0..$#Ew );
	$nE = sqrt( $nE );

# dot product scaled by norm
	if( ($nD==0) || ($nE==0) ){
		return undef;
	} else {
		return $dotProduct / $nD / $nE;
	}
}

1;


__END__

=head1 NAME

  Text::Document - a text document subject to statistical analysis

=head1 SYNOPSIS

  my $t = Text::Document->new();
  $t->AddContent( 'foo bar baz' );
  $t->AddContent( 'foo barbaz; ' );

  my @freqList = $t->KeywordFrequency();
  my $u = Text::Document->new();
  ...
  my $sj = $t->JaccardSimilarity( $u );
  my $sc = $t->CosineSimilarity( $u );
  my $wsc = $t->WeightedCosineSimilarity( $u, \&MyWeight, $rock );


=head1 DESCRIPTION

C<Text::Document> allows to perform simple
Information-Retrieval-oriented statistics on pure-text documents.

Text can be added in chunks, so that the document may be
incrementally built, for instance by a class like
C<HTML::Parser>.

A simple algorithm splits the text into terms; the algorithm
may be redefined by subclassing and redefining C<ScanV>.

The C<KeywordFrequency> function computes term frequency
over the whole document.

=head1 FORESEEN REUSE

The package may be {re}used either by simple instantiation,
or by subclassing (defining a descendant package).  In the
latter case the methods which are foreseen to be redefined are
those ending with a C<V> suffix.  Redefining other methods
will require greater attention.

=head1 CLASS METHODS

=head2 new

The creator method.  The optional arguments are in the
I<(key,value)> form and allow to specify whether
all keywords are trasformed to lowercase (default) and
whether the string representation (C<WriteToString>)
will be compressed (default).

  my $d = Text::Document->new();
  my $dNotCompressed = Text::Document( compressed => 0 );
  my $dPreserveCase = Text::Document( lowercase => 0 );

=head2 NewFromString

Take a string written by C<WriteToString> (see below)
and create a new C<Text::Document> with the same contents;
call C<die> whenever the restore is impossible or ill-advised,
for instance when the current version of the package is different
from the original one, or the compression library in unavailable.

  my $b = Text::Document::NewFromString( $str );

The return value is a blessed reference; put in another way,
this is an alternative contructor.

The string should have been written by C<WriteToString>; 
you may of course tweak the string contents, but
at this point you're entirely on you own.

=head1 INSTANCE METHODS

=head2 AddContent

Used as

  $d->AddContent( 'foo bar baz foo9' );
  $d->AddContent( 'mary had a little lamb' );

Successive calls accumulate content; there is currently no way
of resetting the content to zero.

=head2 Terms

Returns a list of all distinct terms in the document, in no
particular order.

=head2 Occurrences

Returns the number of occurrences of a given term.

  $d->AddContent( 'foo baz bar foo foo');
  my $n = $d->Occurrences( 'foo' ); # now $n is 3

=head2 ScanV

Scan a string and return a list of terms.

Called internally as:

  my @terms = $self->ScanV( $text );

=head2 KeywordFrequency

Returns a reference list of pairs I<[term,frequency]>, sorted by
ascending frequency.

  my $listRef = $d->KeywordFrequency();
  foreach my $pair (@{$listRef}){
  	my ($term,$frequency) = @{$pair};
	...
  }

Terms in the document are sampled and their frequencies of occurrency
are sorted in ascending order;
finally, the list is returned to the user.

=head2 WriteToString

Convert the document (actually, some parameters
and the term counters) into a string which can be saved and
later restored with C<NewFromString>.

  my $str = $d->WriteToString();

The string begins with a header which encodes the
originating package, its version, the parameters
of the current instance.

Whenever possible, C<Compress::Zlib> is used in order to
compress the bit vector in the most efficient way.
On systems without C<Compress::Zlib>, the bit string is
saved uncompressed.

This method is influenced by C<PureASCII>.

=head2 PureASCII

Ensure that the representation in WriteToString does not contain
characters with ASCII code >= 128. Needed to easily include document
representations into textual databases (e.g. XML files).

=head2 JaccardSimilarity

Compute the Jaccard measure of document similarity, which is defined
as follows: given two documents I<D> and I<E>, let I<Ds> and I<Es> be the set
of terms occurring in I<D> and  I<E>, respectively. Define I<S> as the
intersection of I<Ds> and I<Es>, and I<T> as their union. Then
the Jaccerd  similarity is the the number of  elements
of I<S> divided by the number of elements of I<T>.

It is called as follows:

  my $sim = $d->JaccardSimilarity( $e );

If neither document has any terms the result is undef (a rare evenience).
Otherwise the similarity is a real number between 0.0 (no terms in common)
and 1.0 (all terms in common).

=head2 CosineSimilarity

Compute the cosine similarity between two documents I<D> and
I<E>.

Let I<Ds> and I<Es> be the set
of terms occurring in I<D> and  I<E>, respectively. Define I<T> as the
union of I<Ds> and I<Es>, and let I<ti> be the I<i>-th element of I<T>.

Then the term vectors of I<D> and  I<E> are

  Dv = (nD(t1), nD(t2), ..., nD(tN))
  Ev = (nE(t1), nE(t2), ..., nE(tN))

where nD(ti) is the  number of occurrences of term ti in I<D>,
and nE(ti) the same for I<E>.

Now we are at last ready to define the cosine similarity I<CS>:

  CS = (Dv,Ev) / (Norm(Dv)*Norm(Ev))

Here (... , ...) is the scalar product and Norm is the Euclidean
norm (square root of the sum of squares).

C<CosineSimilarity> is called as

   $sim = $d->CosineSimilarity( $e );

It is C<undef> if either I<D> or I<E> have no occurrence of any term.
Otherwise, it is a number between 0.0 and 1.0. Since term occurrences
are always non-negative, the cosine is obviously always non-negative.

=head2 WeightedCosineSimilarity

Compute the weighted cosine similarity between two documents I<D> and
I<E>.

In the setting of C<CosineSimilarity>, the 
term vectors of I<D> and  I<E> are

  Dv = (nD(t1)*w1, nD(t2)*w2, ..., nD(tN)*wN)
  Ev = (nE(t1)*w1, nE(t2)*w2, ..., nE(tN)*wN)

The weights are nonnegative real values; each term has associated
a weight. To achieve generality, weights may be defined
using a function, like:

  my $wcs = $d->WeightedCosineSimilarity(
  	$e,
	\&function,
	$rock
  );

The C<function> will be called as follows:

  my $weight = function( $rock, 'foo' );

C<$rock> is a 'constant' object used for passing a I<context>
to the function.

For instance, a common way of defining weights is the IDF (inverse
document frequency), which is defined in L<Text::DocumentCollection>.
In this context, you can weigh terms with their IDF as
follows:

  $sim = $c->WeightedCosineSimilarity(
  	$d,
	\&Text::DocumentCollection::IDF,
	$collection
  );

C<WeightedCosineSimilarity> will call

  $collection->IDF( 'foo' );

which is what we expect.

Actually, we should return the square root of IDF, but this
detail is not necessary here.

=head1 AUTHORS

  spinellia@acm.org (Andrea Spinelli)
  walter@humans.net (Walter Vannini)

=head1 HISTORY

  2001-11-02 - initial revision

  2001-11-20 - added WeightedCosineSimilarity, suggested by JP Mc Gowan <jp.mcgowan@ucd.ie>

  2002-02-03 - changed representation of checksum. New method C<PureASCII>.

=head DISCARDED CHOICES

We did not use C<Storable>, because we wanted to fine-tune
compression and version compatibility.  However, this
choice may be easily reversed redefining WriteToString and
NewFromString.

