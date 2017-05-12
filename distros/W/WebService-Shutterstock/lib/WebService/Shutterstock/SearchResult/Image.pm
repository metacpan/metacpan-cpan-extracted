package WebService::Shutterstock::SearchResult::Image;
{
  $WebService::Shutterstock::SearchResult::Image::VERSION = '0.006';
}

# ABSTRACT: Class representing a single image search result from the Shutterstock API

use strict;
use warnings;
use Moo;

use WebService::Shutterstock::HasClient;
use WebService::Shutterstock::SearchResult::Item;

with 'WebService::Shutterstock::HasClient', 'WebService::Shutterstock::SearchResult::Item';


has photo_id => ( is => 'ro' ); # sic, should be image_id to be consistant I think

has thumb_small => ( is => 'ro' );
has thumb_large => ( is => 'ro' );
has preview     => ( is => 'ro' );


sub image {
	my $self = shift;
	return $self->new_with_client( 'WebService::Shutterstock::Image', image_id => $self->photo_id );
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::SearchResult::Image - Class representing a single image search result from the Shutterstock API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $search = $shutterstock->search(searchterm => 'butterfly');
	my $results = $search->results;
	foreach my $result(@$results){
		printf "%d: %s\n", $result->photo_id, $result->description;
		print "Tags: ";
		print join ", ", @{ $result->image->keywords };
		print "\n";
	}

=head1 DESCRIPTION

An object of this class provides information about a single search result.  When executing a search, an array
of these objects is returned by the L<WebService::Shutterstock::SearchResults/"results"> method.

=head1 ATTRIBUTES

=head2 photo_id

The image ID for this search result.

=head2 thumb_small

A HashRef containing a height, width and URL for a "small" thumbnail of this image. 

=head2 thumb_large

A HashRef containing a height, width and URL for a "large" thumbnail of this image. 

=head2 preview

A HashRef containing a height, width and URL for a watermarked preview of this image. 

=head2 web_url

The L<http://www.shutterstock.com> link for this image.

=head2 description

An abbreviated description of this search result.

=head1 METHODS

=head2 image

Returns a L<WebService::Shutterstock::Image> object for this search result.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
