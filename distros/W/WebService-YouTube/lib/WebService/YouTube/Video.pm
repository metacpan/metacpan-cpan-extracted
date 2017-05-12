#
# $Id: Video.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube::Video;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw(
      author
      channel_list
      comment_count
      comment_list
      description
      id
      length_seconds
      rating_avg
      rating_count
      recording_country
      recording_date
      recording_location
      tags
      thumbnail_url
      title
      update_time
      upload_time
      url
      view_count
      )
);

1;

__END__

=head1 NAME

WebService::YouTube::Video - Video class for YouTube.

=head1 VERSION

This document describes WebService::YouTube::Video version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube::Video;
    my $video = WebService::YouTube::Video->new( { ... } );

=head1 DESCRIPTION

This is a video class for YouTube.

=head1 SUBROUTINES/METHODS

=head2 new(\%fields)

Creates and returns a new WebService::YouTube::Video object.
%fields can contain parameters enumerated in L</ACCESSORS> section.

=head2 ACCESSORS

=over

=item id

=item author

=item comment_count

=item description

=item length_seconds

=item rating_avg

=item rating_count

=item tags

=item thumbnail_url

=item title

=item upload_time

=item url

=item view_count

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube::Video requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<WebService::YouTube>, L<Class::Accessor::Fast>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-youtube@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-YouTube>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Hironori Yoshida <yoshida@cpan.org>

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
