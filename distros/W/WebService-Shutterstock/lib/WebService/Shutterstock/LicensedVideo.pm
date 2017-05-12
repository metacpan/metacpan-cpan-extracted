package WebService::Shutterstock::LicensedVideo;
{
  $WebService::Shutterstock::LicensedVideo::VERSION = '0.006';
}

# ABSTRACT: Allows for interogating and saving a licensed video from the Shutterstock API

use strict;
use warnings;
use Moo;

use WebService::Shutterstock::LicensedMedia;
with 'WebService::Shutterstock::LicensedMedia';

my @attrs = qw(video_id thumb_large_url allotment_charge);
foreach my $attr(@attrs){
	has $attr => (is => 'ro');
}


sub BUILDARGS {
	my $args = shift->SUPER::BUILDARGS(@_);
	$args->{download_url} = $args->{download}->{url};
	$args->{thumb_large_url} = $args->{thumb_large}->{url};
	return $args;
}


1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::LicensedVideo - Allows for interogating and saving a licensed video from the Shutterstock API

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	my $licensed_video = $subscription->license_video(video_id => 11234, size => 'lowres');

	# retrieve the bytes of the file
	my $jpg_bytes = $licensed_video->download;

	# or, save the file to a valid filename
	$licensed_video->download(file => '/my/videos/my-video.mpg');

	# or, specify the directory and the filename will reflect what the server specifies
	# (typically as something like shutterstock_11234.mpg)
	my $path_to_file = $licensed_video->download(directory => '/my/videos');

=head1 ATTRIBUTES

=head2 video_id

=head2 thumb_large_url

=head2 allotment_charge

=head2 download_url

=head1 METHODS

=head2 download

Downloads a licensed video.  If no arguments are specified, the raw bytes
of the file are returned.  You can also specify a file OR a directory
(one or the other) to save the file instead of returning the raw bytes
(as demonstrated in the SYNOPSIS).

If a C<directory> or C<file> option is given, the path to the saved file
is returned.

B<WARNING:> files will be silently overwritten if an existing file of
the same name already exists.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
