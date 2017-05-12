package WebService::Shutterstock::SearchResults;
{
  $WebService::Shutterstock::SearchResults::VERSION = '0.006';
}

# ABSTRACT: Class representing a single page of search results from the Shutterstock API

use strict;
use warnings;
use Moo;
use WebService::Shutterstock::SearchResult::Image;
use WebService::Shutterstock::SearchResult::Video;

use WebService::Shutterstock::HasClient;
with 'WebService::Shutterstock::HasClient';

sub BUILD { shift->_results_data } # eagar loading



has type => (
	is => 'ro',
	required => 1,
	isa => sub {
		die 'invalid type (expected "image" or "video")' unless $_[0] eq 'image' or $_[0] eq 'video';
	}
);

has query => (
	is       => 'ro',
	required => 1,
	isa      => sub { die "query must be a HashRef" unless ref $_[0] eq 'HASH' }
);
has _results_data => ( is => 'lazy' );

sub _build__results_data {
	my $self = shift;
	my $client = $self->client;
	$client->GET(sprintf('/%ss/search.json', $self->type), $self->query);
	return $client->process_response;
}


sub page        { return shift->_results_data->{page} }
sub count       { return shift->_results_data->{count} }
sub sort_method { return shift->_results_data->{sort_method} }


sub results {
	my $self = shift;
	my $item_class = $self->type eq 'image' ? 'WebService::Shutterstock::SearchResult::Image' : 'WebService::Shutterstock::SearchResult::Video';
	return [
		map {
			$self->new_with_client( $item_class, %$_ );
		}
		@{ $self->_results_data->{results} || [] }
	];
}


sub iterator {
	my $self = shift;
	my $count = $self->count;
	my $search_results = $self;
	my $batch;
	my $batch_i = my $i = my $done = 0;
	return sub {
		return if $i >= $count;
		my $item;
		if(!$batch){
			$batch = $search_results->results;
		} elsif($batch_i >= @$batch){
			$batch_i = 0;
			eval {
				$search_results = $search_results->next_page;
				$batch = $search_results->results;
				1;
			} or do {
				warn $@;
				$done = 1;
			};
		}
		return if !$batch || $done;

		$item = $batch->[$batch_i];
		$i++;
		$batch_i++;
		return $item;
	};
}


sub next_page {
	my $self = shift;
	my $query = { %{ $self->query } };
	$query->{page_number} ||= 0;
	$query->{page_number}++;
	return WebService::Shutterstock::SearchResults->new( client => $self->client, query => $query, type => $self->type );
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::SearchResults - Class representing a single page of search results from the Shutterstock API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');

	# grab results a page at a time
	my $results = $search->results;
	my $next_results = $search->next_page;

	# or use an iterator
	my $iterator = $search->iterator;
	while(my $result = $iterator->()){
		# ...
	}

=head1 ATTRIBUTES

=head2 query

A HashRef of the arguments used to perform the search.

=head2 type

Indicates whether these are "image" or "video" search results.

=head2 page

The current page of the search results (0-based).

=head2 count

The total number of search results.

=head2 sort_method

The sort method used to perform the search.

=head1 METHODS

=head2 results

Returns an ArrayRef of L<WebService::Shutterstock::SearchResult::Image>
or L<WebService::Shutterstock::SearchResult::Video> objects for this
page of search results (based on the C<type> of this set of search
results).

=head2 iterator

Returns an iterator as a CodeRef that will return results in order until
all results are exhausted (walking from one page to the next as needed).

See the L<SYNOPSIS> for example usage.

=head2 next_page

Retrieves the next page of search results (represented as a
L<WebService::Shutterstock::SearchResults> object).  This is just a shortcut
for specifying a specific C<page_number> in the arguments to the
L<search|WebService::Shutterstock/search> method.

=for Pod::Coverage BUILD _results_data

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
