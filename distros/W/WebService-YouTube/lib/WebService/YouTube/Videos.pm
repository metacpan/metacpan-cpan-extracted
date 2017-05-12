#
# $Id: Videos.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube::Videos;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use Carp;
use LWP::UserAgent;
use WebService::YouTube::Util;
use WebService::YouTube::Video;
use XML::Simple;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(dev_id ua));

sub new {
    my ( $class, @args ) = @_;

    my $self = $class->SUPER::new(@args);
    if ( !$self->dev_id ) {
        croak 'dev_id is required';
    }
    if ( !$self->ua ) {
        $self->ua( LWP::UserAgent->new );
    }
    return $self;
}

sub parse_xml {
    my ( $self, $xml ) = @_;

    my $ut_response = XMLin( $xml, ForceArray => [qw(comment channel video)] );

    if ( !$ut_response ) {
        carp 'invalid XML';
        return;
    }

    if ( $ut_response->{status} ne 'ok' ) {

=begin comment

See L<http://youtube.com/dev_error_codes> and each B<API Function Reference>

=end comment

=cut

        carp(
            sprintf "status: %s\ncode: %d\ndescription: %s",
            $ut_response->{status},
            $ut_response->{error}->{code},
            $ut_response->{error}->{description}
        );
        return;
    }

    if ( exists $ut_response->{video_list} ) {
        my $video_list = $ut_response->{video_list}->{video};
        my @videos;
        foreach my $video_id ( keys %{$video_list} ) {
            my $video =
              WebService::YouTube::Video->new( $video_list->{$video_id} );
            $video->id($video_id);
            push @videos, $video;
        }
        return @videos;
    }

    if ( exists $ut_response->{video_details} ) {
        my $video =
          WebService::YouTube::Video->new( $ut_response->{video_details} );
        return $video;
    }

    carp( sprintf '%s: unknown response at %s',
        [ keys %{$ut_response} ]->[0], $ut_response );
    return;
}

sub get_details {
    my ( $self, $video_id ) = @_;

    if ( ref $video_id ) {
        $video_id = $video_id->id;
    }
    my $uri =
      WebService::YouTube::Util->rest_uri( $self->dev_id,
        'youtube.videos.get_details', { video_id => $video_id } );
    my $res = $self->ua->get($uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    my $video = $self->parse_xml( $res->content );
    if ( !$video ) {
        return;
    }
    $video->id($video_id);
    return $video;
}

sub list_by_tag {
    my ( $self, $tag, $fields ) = @_;

    my $uri = WebService::YouTube::Util->rest_uri(
        $self->dev_id,
        'youtube.videos.list_by_tag',
        {
            tag => $tag,
            %{ $fields || {} }
        }
    );
    my $res = $self->ua->get($uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    return $self->parse_xml( $res->content );
}

sub list_by_user {
    my ( $self, $user ) = @_;

    my $uri =
      WebService::YouTube::Util->rest_uri( $self->dev_id,
        'youtube.videos.list_by_user', { user => $user } );
    my $res = $self->ua->get($uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    return $self->parse_xml( $res->content );
}

sub list_featured {
    my $self = shift;

    my $uri = WebService::YouTube::Util->rest_uri( $self->dev_id,
        'youtube.videos.list_featured' );
    my $res = $self->ua->get($uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    return $self->parse_xml( $res->content );
}

1;

__END__

=head1 NAME

WebService::YouTube::Videos - Perl interfece to youtube.videos.*

=head1 VERSION

This document describes WebService::YouTube::Videos version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube::Videos;
    
    my $api = WebService::YouTube::Videos->new( { dev_id => YOUR_DEV_ID } );
    
    # Call API youtube.videos.list_featured
    my @videos = $api->list_featured;
    foreach my $video (@videos) {
        # $video->isa('WebService::YouTube::Video');
    }
    
    # Call other APIs
    my @videos = $api->list_by_user($user);
    my @videos = $api->list_by_tag($tag);
    
    my $video = $api->get_details($video_id);
    
    # Parse XML
    my @video = $api->parse_xml($xml);    # when $xml contains <video_list>
    my $video = $api->parse_xml($xml);    # when $xml contains <video_details>

=head1 DESCRIPTION

This is a Perl interface to YouTube REST API.

See B<Developer APIs> L<http://youtube.com/dev> and B<Developer API -- REST Interface> L<http://youtube.com/dev_rest> for details.

=head1 SUBROUTINES/METHODS

=head2 new(\%fields)

Creates and returns a new WebService::YouTube::Videos object.
%fields can contain parameters enumerated in L</ACCESSORS> section.

=head2 parse_xml($xml)

Parses XML and returns the result.
$xml should be an object that L<XML::Simple> can understand.

=head2 get_details( $video_id )

Returns a L<WebService::YouTube::Video> object.
$video_id is an ID of the video which you want to get details.

See L<http://youtube.com/dev_api_ref?m=youtube.videos.get_details> for details.

=head2 list_by_tag( $tag, \%fields )

Returns an array of L<WebService::YouTube::Video> object.
$tag is a keyword string separated by a space.
%fields can contain the optional parameters.

=over

=item page

1 <= page

=item per_page

per_page <= 100 (default 20)

=back

See L<http://youtube.com/dev_api_ref?m=youtube.videos.list_by_tag> for details.

=head2 list_by_user( $user )

Returns an array of L<WebService::YouTube::Video> object.
$tag is a keyword string separated by a space.
%fields can contain optional parameters.

See L<http://youtube.com/dev_api_ref?m=youtube.videos.list_by_user> for details.

=head2 list_featured( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/dev_api_ref?m=youtube.videos.list_featured> for details.

=head2 ACCESSORS

=head3 dev_id

Developer ID

=head3 ua

L<LWP::UserAgent> object

=head1 DIAGNOSTICS

=over

=item dev_id is required

Developer ID is required when you call API of YouTube.

=item invalid XML

The XML is not a YouTube's XML.

=item unknown response

The ut_response is neither <video_list> nor <video_details>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube::Videos requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Class::Accessor::Fast>, L<LWP::UserAgent>, L<XML::Simple>, L<WebService::YouTube::Util>, L<WebService::YouTube::Video>

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
