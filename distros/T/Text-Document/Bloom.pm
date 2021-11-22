
package Text::Bloom;

use strict;

use Bit::Vector;

use FileHandle;

@Text::Bloom::hashParam = (
	[ 1,		0,	], #identity
	[ 48661,	109441 ],
	[ 13679,	103651 ],
	[ 41851,	33413 ],
	[ 69499,	2399 ],
	[ 55799,	85037 ],
	[ 127051,	73571 ],
	[ 7393,	60821 ],
	[ 123449,	100297 ],
	[ 124309,	87547 ],
	[ 67129,	5531 ],
	[ 72689,	44389 ],
);

BEGIN {
	$Text::Bloom::VERSION = '1.08';

	%Text::Bloom::Radix = ();
	@Text::Bloom::RadixDomain = ();
# previous value was too large for some linux boxes
#	$Text::Bloom::p = 4294967291;
	$Text::Bloom::p = 499979;
	%Text::Bloom::config = (
		d	=> 4,
		size 	=> 65536*2,
		compress=> 1,
	);

#	print __PACKAGE__ . ' v' . $Text::Bloom::VERSION . " ready\n";

	my @domain = 'a' .. 'z';
	push @domain, '0' .. '9';
	@Text::Bloom::RadixDomain = @domain;
	@Text::Bloom::Radix{ @domain } = 0 .. $#domain;
	eval {
		require Compress::Zlib;
	};
	if( $@ ){ $Text::Bloom::config{compress} = undef; }

}


sub new
{
	my $class= shift;
	my %self = @_;

	my $self = {};

	foreach my $key (qw( d size compress ) ){
		if( defined($self{$key}) ){
			$self->{$key} = $self{$key};
		} else {
			$self->{$key} = $Text::Bloom::config{$key};
		}
	}
	bless $self, $class;
	return $self;
}

sub Size
{
	my $self = shift;
	my ($newsize) = @_;
	$newsize and ($self->{size} = $newsize);
	return $self->{size};
}

sub Compute
{
	my $self = shift;
	my @terms = @_;

	my $bv = Bit::Vector->new( $self->{size} );

	foreach my $w (@terms) {
		my $q = $self->QuantizeV( $w );
		foreach my $i (1..$self->{d}){
			my $index = $self->HashV( $i-1, $q );
			if( 0 && $bv->bit_test($index) ){
				print STDOUT ("$w -> $q -> $index"
					. " COLLISION\n");
			}
			$bv->Bit_On( $index );
		}
	}

	my $nTerms = scalar @terms;
	my $nBits = $bv->Norm();

	if( $nBits > 0 ){
		$self->{collisionRatio} = 1.0 - $nBits/$nTerms/$self->{d};
	}

	print STDERR (
		$nTerms
		. ' terms added, bit vector norm is '
		. $nBits
		. ', collision ratio is '
		. $self->{collisionRatio}
		. "\n"
	) unless 1;
	return $self->{bv} = $bv;
}

sub QuantizeV
{
	my $self  = shift;
	my ($term) = @_;

	my @chars = split( //, $term );

	my $q = 0;
	for( my $i=$#chars; $i>=0; $i-- ){
		$q = $q * (scalar( @Text::Bloom::RadixDomain )+1)
			+ $Text::Bloom::Radix{ $chars[$i] } + 1;
		$q %= $Text::Bloom::p;
	}
	return $q;
}

sub HashV
{
	my $self =shift;
	my ($order,$x ) = @_;
	my ($m,$q) =  @{$Text::Bloom::hashParam[$order]};

	my $scrambled = $x * $m + $q;
	$scrambled %= $self->{size};

	return $scrambled;
}

sub WriteToString
{
	my $self = shift;

	return undef unless $self->{bv};

	my $block = $self->{bv}->Block_Read() ;
	if( $self->{compress} ){
		$block = Compress::Zlib::compress( $self->{bv}->Block_Read());
		$block or die(
			__PACKAGE__ . '::WriteToString : '
			. 'cannot compress block'
		);
	}

	my $str = 'p=' . __PACKAGE__
		. ' v='
		. $Text::Bloom::VERSION
		. ' size='
		. $self->{size}
		. ' d='
		. $self->{d}
		. ' compress='
		. ($self->{compress}?1:0)
		. ' l='
		. length( $block )
		. "\n" ;

	$str .= $block;

	$str .= pack( 'L', unpack( '%32C*', $str ));

	return $str;
}

sub WriteToFile
{
	my $self = shift;
	my ($file) = @_;

	my $f = FileHandle->new( '>'  . $file );
	binmode $f;

	$f->print( $self->WriteToString() );
}

sub NewFromString
{
	my ($string) = @_;

	my $self = {};

# verify checksum
	my $stored_checksum = substr( $string, -4 );
	$stored_checksum = unpack( 'L', $stored_checksum );
	$string = substr( $string, 0, -4 );
	my $computed_checksum = unpack( '%32C*', $string );

	if( $stored_checksum ne $computed_checksum ){
		die( __PACKAGE__ . '::NewFromString : '
			. 'checksum test failed '
			. $stored_checksum
			. ' != '
			. $computed_checksum
		);
	}

	# split in two: first line and rest
	my( $header, $block ) = split( /\n/, $string, 2 );


	# parse header line
	my %header = split( /[ 	=]+/, $header );

	# check that the reading package is the same as the one that wrote
	if( $header{p} ne __PACKAGE__ ){
		die( __PACKAGE__ . '::NewFromString : '
			. "file was not written by "
			. __PACKAGE__
			. ". Header is '$header'"
		);
	}

	# version must be identical
	if( $header{v} != $Text::Bloom::VERSION ){
		die( __PACKAGE__ . '::NewFromString : '
			. "Current version is $Text::Bloom::VERSION"
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

	# retrieve header info
	@{$self}{ qw( size d compress ) } = @header{ qw( size d compress ) };

	# if we have to decompress, check that we have the required lib
	if( not( $Text::Bloom::config{compress} ) and ($header{compress}==1) ){
		die( __PACKAGE__ . '::NewFromString : '
			. 'file $file is compressed, but '
			. 'Compress::Zlib is not available.'
		);
	}

	if( $header{compress} ){
		eval {
			$block = Compress::Zlib::uncompress( $block );
		};
		($block and not($@)) or die(
			__PACKAGE__ . '::WriteToString : '
			. 'cannot uncompress block'
		);
	}

	$self->{bv} = Bit::Vector->new( $self->{size} );
	$self->{bv}->Block_Store( $block );

	bless $self, __PACKAGE__;

}

sub NewFromFile
{
	my ($file) = @_;

	my $f = FileHandle->new( $file );
	binmode $f;
	local $/ = undef;
	my $freezed = <$f>;

	return Text::Bloom::NewFromString( $freezed );
}

# similarity  is the  number of common bits
# divided by the number of all  nonzero bits
sub Similarity
{
	my $self = shift;
	my ($other) = @_;

	if( $self->{size} != $other->{size} ){
		die( __PACKAGE__ . '::Similarity : '
			. 'Bloom signatures cannot be compared '
			. "because sizes are $self->{size} and $other->{size}"
		);
	}

	my $union = Bit::Vector->new( $self->{size} );
	my $inter = Bit::Vector->new( $self->{size} );

	$union->Union( $self->{bv}, $other->{bv} );
	$inter->Intersection( $self->{bv}, $other->{bv} );

	my $normUnion = $union->Norm();
	($normUnion == 0) and  return 0;
	my $normInter = $inter->Norm();
	return $normInter / $normUnion;
}

sub GenerateHashes
{
	foreach (0..10){
		my $v = int( $Text::Bloom::config{size} * rand() );
		$v = Text::Bloom::GreatestPrimeLessThan( $v );

		my $vB = int( $Text::Bloom::config{size} * rand() );
		$vB = Text::Bloom::GreatestPrimeLessThan( $vB );

		print "[ $v,\t$vB ],\n";
	}
}

# very naive primality test

sub GreatestPrimeLessThan
{
	my ($number) = @_;

	while( not Text::Bloom::IsPrime( $number ) ){
		$number--;
	}
	return $number;
}

sub IsPrime
{
	my ($number) = @_;

	my $max = int( sqrt( $number ) );

	for( my $i = 2; $i <= $max ; $i++ ){
		if( $number % $i == 0 ){
#			print "$number is divisible by $i\n";
			return undef;
		}
	}

#	print "$number is prime\n";

	return 1;
}

1;

# this line was used to generate  hashParam
# Text::Bloom::GenerateHashes();

__END__

=head1 NAME

  Text::Bloom - Evaluate Bloom signature of a set of terms

=head1 SYNOPSIS

  my $b = Text::Bloom->new();
  $b->Compute( qw( foo bar baz ) );
  my $sig = $b->WriteToString();
  $b->WriteToFile( 'afile.sig' );
  my $b2 = Text::Bloom::NewFromFile( 'afile.sig' );
  my $b3 = Text::Bloom->new();
  $b3->Compute( qw( foo bar barbaz ) );
  my $sim = $b->Similarity( $b2 );
  my $b4 = Text::Bloom::NewFromString( $sig );

=head1 DESCRIPTION

C<Text::Bloom> applies the Bloom filtering technique to
the statistical analysis of documents.

The terms in the document are quantized using a base-36
radix representation; each term thus corresponds to an
integer in the range 0..I<p-1>, where I<p> is a prime,
currently set to the greatest prime less than 2^32.

Each quantized value is mapped to I<d> integers in the range
0..I<size-1>, where I<size> is an integer less than I<p>,
currently 2^17, using a  family of hash functions,
computed by the C<HashV> function.

Each hashed value is used as the index in a large bit vector.
Bits corresponding to terms present in the document are set to
1; all other bits are set to 0.

Of course, collisions may cause the same bit to be set twice,
by different terms. It follows that, if the document contains
I<n> distinct terms, in the resulting bit vector at most
I<n * d> bits are set to 1.

The resulting bit string is a very compact representation of the
presence/absence of terms in the document, and  is therefore
characterised as a I<signature>. Moreover, it does not
depend on a pre-set dictionary of terms.

The signature may be used for:

=over 4

=item *

testing whether a given set of terms is present in the document,

=item *

computing which fraction of terms are common to two documents.

=back

The bit representation may be written to and read from a file.
C<Text::Bloom> prepends a header to the bit stream proper;
moreover, whenever the package C<Compress::Zlib> is available,
the bit vector is compressed, so that disk space requirements
are drastically reduced, especially for small documents.

The hash function is obviously a crucial component of the filter;
the reference implementation uses a radix representation of
strings. Each term must therefore match the regular
expression C</[0-9a-z]+/>.

There are quite a few viable alternatives, which can be pursued
by subclassing and redefining the method C<QuantizeV>.

=head1 FORESEEN REUSE

The package may be {re}used either by simple instantiation,
or by subclassing (defining a descendant package).  In the
latter case the methods which are foreseen to be redefined are
those ending with a C<V> suffix.  Redefining other methods
will require greater attention.

=head1 CLASS METHODS

=head2 new

The constructor. No arguments are required.

  $b = Text::Bloom->new();

=head2 NewFromString

Take a string written by C<WriteToString> (see below)
and create a new C<Text::Bloom> with the same contents;
call C<die> whenever the restore is impossible or ill-advised,
for instance when the current version of the package is different
from the original one, or the compression library in unavailable.

  my $b = Text::Bloom::NewFromString( $str );

The return value is a blessed reference; put in another way,
this is an alternative contructor.

The string should have been written by C<WriteToString>; 
you may of course tweak the string contents, but
at this point you're entirely on you own.

=head2 NewFromFile

Utility function that reads a binary file and performs a C<NewFromString>
on its content; see its counterpart, C<WriteToFile>.

  my $b2 = Text::Document::NewFromFile( 'foo.sig' );

=head1 INSTANCE METHODS

=head2 Size

Set and get the size of the filter, in bits. The default size
is currently 128K.

  print 'size is ' . $b->Size() . "\n";
  $b->Size( 65536 );

The C<Size> method must be called before the C<Compute> method
in order to have effect.

=head2 Compute

Compute the Bloom signature from the given set of words
and store it internally.

  $b->Compute( qw( foo bar baz foobar bazbaz ) );

Makes use of the C<QuantizeV> method.

=head2 QuantizeV

Convert a term into an integer; must return
an integer in the range 0 .. C<$Text::Bloom::p-1>.

It is called as

  my $hash = $b->QuantizeV( $term );

The current version is designed for strings matching
C</[a-z0-9]+/>. Other characters do not cause errors,
but degrade the hash function performance.

This function is a likely candidate for redefinition.

=head2 HashV

Convert an integer to a (smaller) integer, according
to one of a class of similar functions.

It is internally called as:

  my $index = $b->HashV( $order, $value );

The C<$value> must belong  to the  interval
0..C<$Text::Bloom::p-1>, while the index  must
lie in 0..I<size-1>. C<$order> is
a small integer from 0 to I<d-1>.

The default implementation is

  index = m[order] * value + q[order]   (mod size) 

the values of I<m> and I<q> are taken from the array
C<@Text::Bloom::hashParam>; the form of the  function
is taken from [2].

=head2 WriteToString

Convert the Bloom signature into a string which can be saved and
later restored with C<NewFromString>. C<Compute> must have
been called previously.

  my $str = $b->WriteToString();

The string begins with a header which encodes the
originating package, its version, the parameters
of the current instance.

Whenever possible, C<Compress::Zlib> is used in order to
compress the bit vector in the most efficient way.
On systems without C<Compress::Zlib>, the bit string is
saved uncompressed.

=head2 WriteToFile

These convenience functions just call their String counterparts
and read/write the file specified in the argument.

  $b->WriteToFile( 'foo.sig' );

=head1 AUTHORS

  spinellia@acm.org (Andrea Spinelli)
  walter@humans.net (Walter Vannini)

=head1 BIBLIOGRAPHY

=over 4

=item [1]

Burton H. Bloom, "Space/time trade-offs in hash coding with allowable errors",
I<Communications of the ACM>, B<13>, 7, July 1970, pages 422-426. (available
electronically from ACM Digital Library).

=item [2]

M. V. Ramakrishna, "Practical Performance of Bloom FIlters
and Parallel Free-Text Searching", 
I<Communications of the ACM>, B<32>, 10, October 1989, pages 1237-1239.
(available electronically from ACM Digital Library).

=back

=head1 BUGS

On Win32 we have experienced some instabilities when dealing
with a large number of signatures; in this case Perl crashes
without apparent explanation. The main suspect is  Bit::Vector,
but without any evidence.

=head1 HISTORY

  2001-11-02 - initial revision

  2002-02-04 - reduced prime p to pacify some linux boxes
