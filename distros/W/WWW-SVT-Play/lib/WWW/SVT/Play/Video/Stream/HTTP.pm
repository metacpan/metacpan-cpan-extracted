package WWW::SVT::Play::Video::Stream::HTTP;

# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

WWW::SVT::Play::Video::Stream::HTTP, HTTP class representing a stream

=head1 SYNOPSIS

 use WWW::SVT::Play::Video;

 my $svtp = WWW::SVT::Play::Video->new($url);
 my $stream = $svtp->stream(protocol => 'HTTP');

=head1 DESCRIPTION

=cut

use warnings FATAL => 'all';
use strict;
use parent 'WWW::SVT::Play::Video::Stream';

our $VERSION = 0.12;
use Carp;

=head2 is_http

Is stream using HTTP protocol? Yes.

=cut

sub is_http { 1 }

=head2 download

Download this stream using rtmpdump. This forks a new process and
depends on the external program "rtmpdump". Takes the following
named parameters:

=over

=item * output, filename to which the stream should be downloaded to

=item * force, stream should be downloaded even if filename exists

=back

=cut

sub download {
	my $self = shift;
	my %args = @_;

	if (not defined $args{output}) {
		carp "No output filename specified. Can't download.";
		return;
	}

	if (-e $args{output} and not $args{force}) {
		carp "Output file already exists";
		return;
	}

	if ($args{output} =~ /'/) {
		# FIXME: I'm lazy. The ' really should be treated correctly.
		#        I think there is a CPAN module for this.
		carp "I hate ' characters in filenames. Try wihtout it.";
		return;
	}

	system("curl -L -o '$args{output}' '$self->{url}'");
}

=head2 bitrate

Get the bitrate information for this RTMP stream.

=cut

sub bitrate {
	my $self = shift;
	return $self->{bitrate};
}

=head1 COPYRIGHT

Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
