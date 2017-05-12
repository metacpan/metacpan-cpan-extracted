# $Id: $ $Revision: $ $Source: $ $Date: $

package WWW::Search::ISBNDB;

use strict;
use warnings;

use LWP::UserAgent;
use WWW::Search qw(generic_option);
use WWW::SearchResult;
use XML::Simple;

use vars qw(@ISA $VERSION);

@ISA = qw(WWW::Search);
$VERSION = '0.3';

sub url_encode {
    my ($encode ) = @_;
    if (! $encode) { return; }
    $encode =~ s/([^A-Za-z0-9\-_.!~*'() ])/ uc sprintf "%%%02x",ord $1 /xmeg;
    $encode =~ tr/ /+/;
    return $encode;
}

sub native_setup_search {
	my($self, $query) = @_;
	if (! $self->{'key'}) { die 'No license key given to WWW::Search::ISBDB!'; }
	$self->{'_offset'} = 0;
	$self->{'_query'} = $query;
	return 1;
}

sub native_retrieve_some {
	my ($self) = @_;
	
	# HACK: Consider better url encoding.
    my $query = url_encode( $self->{'_query'} );

	my %args = (
		'access_key' => $self->{'key'},
		'index1' => $self->{'_type'} || 'combined',
		'value1' => $self->{'_query'},
		'results' => 'details+subjects+texts',
	);
	
	my $url = 'http://isbndb.com/api/books.xml?'.( join q{&},  map { $_ . q{=} . $args{$_} } keys %args );

	my $ua = LWP::UserAgent->new(
		'agent' => "W3SearchISBNDB/$VERSION",
	);
	my $response = $ua->get( $url );

	if (! $response->is_success ) { return; }
	my $content = $response->content;
	if ( $content ) {
		my $xs = new XML::Simple();
		my $ref = $xs->XMLin("$content" );
		foreach my $book ( @{ $ref->{'BookList'}{'BookData'} }) {
			my $hit = WWW::SearchResult->new();
			$hit->{'book_id'} = $book->{'book_id'};
			$hit->{'isbn'} = $book->{'isbn'};
			$hit->{'language'} = $book->{'Details'}{'language'} || q{};
			$hit->{'summary'} = $book->{'Summary'} || q{};
			$hit->{'titlelong'} = $book->{'TitleLong'} || q{};
			$hit->{'notes'} = $book->{'Notes'} || q{};
			$hit->title( $book->{'Title'} );
			$hit->url( 'http://isbndb.com/search-all.html?kw=' . $book->{'isbn'} );
			push @{$self->{cache}}, $hit;
		}
	}

	return;
}

1;
__END__

=pod

=head1 NAME

WWW::Search::ISBNDB - Search for book information on isbndb.com

=head1 SYNOPSIS

This module creates an easy to use interface for searching books on isbndb.com.

  use WWW::Search;  
  my $search = WWW::Search->new('ISBNDB', key => 'abcd1234');
  $search->native_query('born in blood');
  my $result = $search->next_result();
  while (my $result = $search->next_result() ) {
	print "$result->title ($result->{'isbn'} - $result->{'book_id})\n";
	print " -- $result->{'titlelong'}\n";
	print "  '$result->{'summary'}'\n";
  }

=head1 DETAILS

=head2 native_setup_search

This prepares the search by checking for a valid developer key. A developer key can be obtained at isbndb.com and is free.

=head2 native_retrieve_some

The logic behind this module is very simple. First we prepare the search
query that includes the access_key, search type, search value and display
options and fetch the page with L<LWP::UserAgent>. Once we have the results, 
we use L<XML::Simple> to sift through them and populate a L<WWW::SearchResult>
object.

Note that because of the complexity of the search result, it does not have all
of the default WWW::SearchResult fields. The extra fields are contained within
the object hash and consist of the following:

  book_id
  idbn
  language
  summary
  titlelong
  notes

=head2 url_encode

=head1 AUTHOR

Nick Gerakines, C<< <nick@socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-search-isbndb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-ISBNDB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to isbndb.com for the data that powers this module.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
