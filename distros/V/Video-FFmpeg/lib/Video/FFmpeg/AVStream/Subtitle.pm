package Video::FFmpeg::AVStream::Subtitle;

our $VERSION = '0.47';

our @ISA = ('Video::FFmpeg::AVStream');

1;

__END__
=head1 NAME

Video::FFmpeg::AVStream::Subtitle - Retrieve video properties common to all types of streams

=head1 SYNOPSIS

  See Video::FFmpeg

=head1 METHODS

The Video::FFmpeg::AVStream::Video

=head2 The Video::FFmpeg::AVStream class

=head3 codec

name of the codec

=head3 codec_type

returns one of "audio", "video", "subtitle", "data", "attachment", "data", or "unknown"

=head3 lang

returns the stream's language

=head2 The Video::FFmpeg::AVStream::Subtitle class

This class has no methods

=head1 DESCRIPTION

Video::FFmpeg is a factory class for working with video files. Video::FFmpeg utilises FFmpeg's libavformat, and provides a basic interface.

=head2 EXPORT

None by default.


=head1 SEE ALSO

=over 4

=item L<Video::FFmpeg>

=item L<Video::FFmpeg::AVFormat>

=item L<Video::FFmpeg::AVStream>

=item L<Video::FFmpeg::AVStream::Audio>

=item L<Video::FFmpeg::AVStream::Video>

=item L<Video::FFmpeg::AVStream::Subtitle>

=item L<html://www.seattlenetworks.com/perl/FFmpeg>

=back

=head1 TODO

=head1 AUTHOR

Max Vohra, E<lt>max@seattlenetworks.comE<gt> L<html://www.seattlenetworks.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Max Vohra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
