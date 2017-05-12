package WebService::Shutterstock::SearchResult::Video;
{
  $WebService::Shutterstock::SearchResult::Video::VERSION = '0.006';
}

# ABSTRACT: Class representing a single video search result from the Shutterstock API

use strict;
use warnings;
use Moo;

use WebService::Shutterstock::HasClient;
use WebService::Shutterstock::SearchResult::Item;

with 'WebService::Shutterstock::HasClient', 'WebService::Shutterstock::SearchResult::Item';



sub BUILDARGS {
	my $class = shift;
	my $args = $class->SUPER::BUILDARGS(@_);
	$args->{thumb_video} ||= $args->{sizes}->{thumb_video};
	$args->{preview_video} ||= $args->{sizes}->{preview_video};
	$args->{preview_image_url} ||= $args->{sizes}->{preview_image}->{url};
	return $args;
}

has video_id => ( is => 'ro' ); # sic, should be image_id to be consistant I think

has thumb_video => ( is => 'ro' );
has preview_video => ( is => 'ro' );
has preview_image_url => ( is => 'ro' );

has submitter_id => ( is => 'ro' );
has duration => ( is => 'ro' );
has aspect_ratio_common => ( is => 'ro' );
has aspect => ( is => 'ro' );


sub video {
	my $self = shift;
	return $self->new_with_client( 'WebService::Shutterstock::Video', %$self );
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::SearchResult::Video - Class representing a single video search result from the Shutterstock API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $search = $shutterstock->search_video(searchterm => 'butterfly');
	my $results = $search->results;
	foreach my $result(@$results){
		printf "%d: %s\n", $result->video_id, $result->description;
		print "Tags: ";
		print join ", ", @{ $result->video->keywords };
		print "\n";
	}

=head1 DESCRIPTION

An object of this class provides information about a single search result.  When executing a search, an array
of these objects is returned by the L<WebService::Shutterstock::SearchResults/"results"> method.

=head1 ATTRIBUTES

=head2 video_id

The video ID for this search result.

=head2 thumb_video

A HashRef containing a webm and mp4 URL for a "thumbnail" size of this video.

=head2 preview_video

A HashRef containing a webm and mp4 URL for a "preview" size of this video.

=head2 preview_image_url

An URL for a watermarked preview of this image. 

=head2 web_url

The L<http://footage.shutterstock.com> link for this image.

=head2 description

An abbreviated description of this search result.

=head2 submitter_id

The ID for the submitter of this video.

=head2 duration

Length of this video in seconds.

=head2 aspect_ratio_common

Aspect ratio as a string (i.e. "16:9").

=head2 aspect

Aspect ratio as a float (i.e. 1.7778).

=head1 METHODS

=head2 video

Returns a L<WebService::Shutterstock::Video> object for this search result.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
