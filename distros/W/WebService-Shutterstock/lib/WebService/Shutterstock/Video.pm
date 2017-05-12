package WebService::Shutterstock::Video;
{
  $WebService::Shutterstock::Video::VERSION = '0.006';
}

# ABSTRACT: Represent the set of information about a Shutterstock video as returned by the API

use strict;
use warnings;

use Moo;
use WebService::Shutterstock::DeferredData qw(deferred);

use WebService::Shutterstock::HasClient;
with 'WebService::Shutterstock::HasClient';


has id => ( is => 'ro', required => 1, init_arg => 'video_id' );

deferred(
	qw(
		categories
		description
		keywords
		aspect_ratio_common
		aspect
		duration
		sizes
		model_release
		r_rated
		submitter_id
		web_url
		is_available
	),
	sub {
		my $self   = shift;
		my $client = $self->client;
		$client->GET( sprintf( '/videos/%s.json', $self->id ) );
		my $data = $client->process_response(404 => sub {
			return { is_available => 0 };
		});
		$data->{is_available} = 1 if $data->{video_id} && $self->id == $data->{video_id};
		return $data;
	}
);

sub size {
	my $self = shift;
	my $size = shift;
	return exists($self->sizes->{$size}) ? $self->sizes->{$size} : undef;
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Video - Represent the set of information about a Shutterstock video as returned by the API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $video = $shutterstock->video(12345);
	printf(
		"Video %d (%dx%d) - %s\n",
		$video->id,
		$video->size('sd_original')->{width},
		$video->size('sd_original')->{height},
		$video->description
	);
	print "Categories:\n";
	foreach my $category ( @{ $video->categories } ) {
		printf( " - %s (%d)\n", $category->{category}, $category->{category_id} );
	}

=head1 DESCRIPTION

This module serves as a proxy class for the data returned from a URL
like L<http://api.shutterstock.com/videos/12345.json>.  Please look
at that data structure for a better idea of exactly what each of the attributes
in this class contains.

=head1 ATTRIBUTES

=head2 id

The ID of this video on the Shutterstock system

=head2 categories

ArrayRef of category names and IDs.

=head2 description

=head2 keywords

ArrayRef of keywords describing this video

=head2 aspect_ratio_common

The aspect ratio in string form (i.e "4:3")

=head2 aspect

The aspect ratio of this video in decimal form (i.e. 1.3333)

=head2 duration

Length of the video in seconds

=head2 r_rated

Boolean

=head2 sizes

Returns a HashRef of information about the various sizes for the image.

=head2 model_release

=head2 submitter_id

ID of the submitter who uploaded the video to Shutterstock.

=head2 web_url

A URL for the main page on Shutterstock's site for this video.

=head1 METHODS

=head2 is_available

Boolean

=head2 size

Returns details for a specific size.  Some sizes provide dimensions,
format, FPS and file size (lowres_mpeg, sd_mpeg, sd_original). Other sizes
provide a URL for a video or still preview (thumb_video, preview_video,
preview_image).

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
