
package Text::DocumentCollection;

use strict;
use warnings;
use Text::Document;

use DB_File;

use v5.6.0;

$Text::DocumentCollection::VERSION = 1.08;

sub new
{
	my $class = shift;
	my %self = @_;
	my $self = \%self;
	bless $self, $class;

	defined( $self->{file} ) or die( __PACKAGE__ . '::new : '
		. "keyword 'file' is mandatory"
	);

	my %persistent;

	(tie %persistent, 'DB_File', $self->{file}) or die( __PACKAGE__
		. '::new : '
		. "Cannot tie persistent hash: $!"
	);

	$self->{pdocs} = \%persistent;

	return $self;
}

sub NewFromDB
{
	my $self = Text::DocumentCollection::new(@_);
	while( my @kv = each %{$self->{pdocs}} ){
		$self->{docs}->{$kv[0]} =
			Text::Document::NewFromString( $kv[1] );
	}
	return $self;
}

sub Add
{
	my $self = shift;
	my ($key,$doc) = @_;

	if( defined( $self->{docs}->{$key} ) ){
		die( __PACKAGE__ . '::Add : '
			. "document `$key' is already in this collection"
		);
	}

	$self->{docs}->{$key} = $doc;

	delete $self->{IDF};

	$self->{pdocs}->{$key} = $doc->WriteToString();

	return $doc;
}

sub Delete
{
	my $self = shift;
	my ($key) = @_;

	if( not defined( $self->{docs}->{$key} ) ){
		return undef;
	}
	delete $self->{docs}->{$key};
	delete $self->{pdocs}->{$key};
	return 1;
}

sub EnumerateV
{
	my $self = shift;
	my ($callback,$rock) = @_;

	my @result = ();
	while( my @kv = each %{$self->{docs}} ){
		my @l = &{$callback}( $self, $kv[0], $kv[1], $rock );
		push @result, @l;
	}
	return @result;
}

sub IDF_Help
{
	my $self = shift;
	my ($key,$doc,$term) = @_;

	my $o = $doc->Occurrences( $term );
	$self->{_idf_n}++;
	if( $o and ($o>0) ){
		$self->{_idf_dt}++;
	}
}

sub IDF
{
	my $self = shift;
	my ($term) = @_;

	defined( $self->{IDF}->{$term} ) and return $self->{IDF}->{$term};
	$self->{_idf_n} = 0;
	$self->{_idf_dt} = 0;
	$self->EnumerateV( \&Text::DocumentCollection::IDF_Help, $term );
	if( $self->{_idf_dt} <= 0 ){
		warn( "term $term does not occur in any document" );
		return $self->{IDF}->{$term} = 0.0;
	}
	$self->{IDF}->{$term} =
		log( $self->{_idf_n} / $self->{_idf_dt} ) / log(2.0);

#	print "IDF($term) = $self->{IDF}->{$term}\n";
	return $self->{IDF}->{$term} ;
}

1;

__END__

=head1 NAME

  Text::DocumentCollection - a collection of documents

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS METHODS

=head2 new

The constructor; arguments must be passed as maps
from keys to values. The key C<file> is mandatory.

  my $c = Text::DocumentCollection->new( file => 'coll.db' );

Documents from the collection are saved as in the  specified file,
which is  currently handled by a C<DB_File> hash.

=head1 INSTANCE METHODS

=head2 Add

Add a document to the collection, tagging it with
a unique key.

  $c->Add( $key, $doc );

C<Add> C<die>s if the key is already present.

To change an existing key, use C<Delete> and then C<Add>.

=head2 Delete

Discard a document from the collection.

=head2 NewFromDB

Loads the collection from the given DB file:

  my $c = Text::DocumentCollection->NewFromDB( file => 'coll.db' );

The file must be either empty or created by a former invocation
of C<new> or C<NewFromDB>, followed by any number of C<Add>
and/or C<Delete>.

Currently, all documents in  the  collection are  revived
(by calling C<NewFromString>). This poses performance problems
for huge collections; a caching mechanism would be an option
in this case.

=head2 IDF

Inverse Term frequency of a given term.

The definition we used is, given a term I<t>, a set of documents
I<DOC> and the binary relationship I<has-term>:

  IDF(t) = log2( #DOC / #{ d in DOC | d has-term t } )

The logarithm is in base 2, since this is related to an
information measurement, and # is the cardinality operator.

=head2 EnumerateV

Enumerates all the document in the collection. Called as:

  my @result = $c->EnumerateV( \&Callback, 'the rock' );

The function C<Callback> will be called on each element
of the collection as:

  my @l = CallBack( $c, $key, $doc, $rock );

where C<$rock> is the second argument to C<Callback>.

Since C<$c> is the first argument, the callback may be
an instance method of C<Text::DocumentCollection>.

The final result is obtained by concatenating all the
partial results (C<@l> in the example above).  If you do
not want a result, simply return the empty list ().

There is no particular order of enumeration, so there
is no particular order in which results are concatenated.

=head1 AUTHORS

  spinellia@acm.org
  walter@humans.net
