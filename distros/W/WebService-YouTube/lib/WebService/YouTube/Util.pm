#
# $Id: Util.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube::Util;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use Carp;
use LWP::UserAgent;
use URI::Escape qw(uri_escape uri_escape_utf8);
use Encode ();

sub rss_uri {
    my ( $class, $type, $arg ) = @_;

    if ( $type ne 'global' && $type ne 'tag' && $type ne 'user' ) {
        croak "type of $type is not supported";
    }

    if ( Encode::is_utf8($arg) ) {
        $arg = uri_escape_utf8($arg);
    }
    else {
        $arg = uri_escape($arg);
    }

    if ( $type eq 'user' ) {
        $arg = lc $arg . '/videos';
    }
    return "http://www.youtube.com/rss/$type/$arg.rss";
}

sub rest_uri {
    my ( $class, $dev_id, $method, $fields ) = @_;

    my $query = q{};
    if ($fields) {
        foreach my $key ( keys %{$fields} ) {
            my $value = $fields->{$key};
            if ( Encode::is_utf8($value) ) {
                $value = uri_escape_utf8($value);
            }
            else {
                $value = uri_escape($value);
            }
            $query .= sprintf '&%s=%s', $key, $value;
        }
    }
    return
      "http://www.youtube.com/api2_rest?dev_id=$dev_id&method=$method$query";
}

sub get_video_uri {
    my ( $class, $video, $args ) = @_;

    if ( !$video ) {
        return;
    }

    $args->{ua} ||= LWP::UserAgent->new;

    my ( $video_id, $video_uri );
    if ( ref $video ) {
        $video_id  = $video->id;
        $video_uri = $video->url;
    }
    else {
        $video_id = $video;
    }
    $video_uri ||= "http://youtube.com/?v=$video_id";

    my $res = $args->{ua}->get($video_uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }

    my $content = $res->content;
    if ( $content =~ m{"/player2\.swf\?([^"]+)",\s*"movie_player"}msx ) {
        return "http://youtube.com/get_video.php?$1";
    }
    if ( $content =~ m{\bt\b[^:]*:\s*(['"])(.+?)\1}msx ) {
        return "http://youtube.com/get_video.php?video_id=$video_id&t=$2";
    }
    if ( $content =~ m{class="errorBox"[^>]*>\s*([^<]+?)\s*<}msx ) {
        carp "$video_id: $1";
        return;
    }
    carp "$video_id: got a page but it is invalid page\n$content";
    return;
}

sub get_video {
    my ( $class, $video, $args ) = @_;

    if ( !$video ) {
        return;
    }

    $args->{ua} ||= LWP::UserAgent->new;

    my $video_uri = $class->get_video_uri( $video, $args );
    if ( !$video_uri ) {
        return;
    }
    my $res = $args->{ua}->get($video_uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    return $res->content;
}

1;

__END__

=head1 NAME

WebService::YouTube::Util - Utility for WebService::YouTube

=head1 VERSION

This document describes WebService::YouTube::Util version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube::Util;
    
    # Get an URI of RSS
    my $uri = WebService::YouTube::Util->rss_uri( 'global', 'recently_added' );
    
    # Get an URI of REST API
    my $uri = WebService::YouTube::Util->rest_uri( $dev_id,
                                                   'youtube.videos.list_by_tag',
                                                   { tag => 'monkey' }
                                                 );
    
    # Get a downloadable URI
    my $uri = WebService::YouTube::Util->get_video_uri('rdwz7QiG0lk');
    
    # Get a video which type is .flv
    my $content = WebService::YouTube::Util->get_video('rdwz7QiG0lk');

=head1 DESCRIPTION

This is an utility for L<WebService::YouTube>.

=head1 SUBROUTINES/METHODS

=head2 rss_uri( $type, $arg )

Returns a URI of RSS.
$type should be 'global' or 'tag' or 'user'.
$arg is required when $type is 'tag' or 'user'.

=head2 rest_uri( $dev_id, $method, \%fields )

Returns a URI of REST API.
$dev_id is your developer ID of YouTube.
$method is a method name like a 'youtube.*.*'.
%fields can contain optional parameter.

=head2 get_video_uri( $video, \%args )

Returns a downloadable URI of $video.
$video should be a video ID or a L<WebService::YouTube::Video> object.
%args can contain some optional arguments.

=over

=item ua

L<LWP::UserAgent> object

=back

=head2 get_video( $video, \%args )

Returns a downloaded content of $video.
$video should be a video ID or a L<WebService::YouTube::Video> object.
%args can contain some optional arguments.

=over

=item ua

L<LWP::UserAgent> object

=back

=head1 DIAGNOSTICS

=over

=item type of ... is not supported

No such RSS. The type should be 'global' or 'tag' or 'user'.

=item got a page but it is invalid page

Maybe, YouTube is being maintained. :-)

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube::Util requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<WebService::YouTube>, L<LWP::UserAgent>, L<URI::Escape>

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
