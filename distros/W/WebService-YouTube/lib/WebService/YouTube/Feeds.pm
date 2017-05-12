#
# $Id: Feeds.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube::Feeds;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use Carp;
use HTTP::Date;
use LWP::UserAgent;
use WebService::YouTube::Util;
use WebService::YouTube::Video;
use XML::Simple;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(ua));

BEGIN {
    my @global_rss = qw(
      recently_added
      recently_featured
      top_favorites
      top_rated
      most_discussed_month
      most_discussed_today
      most_discussed_week
      top_viewed
      top_viewed_month
      top_viewed_today
      top_viewed_week
    );

    foreach my $global_rss (@global_rss) {
        my $class = __PACKAGE__;
        no strict qw(refs);    ## no critic (ProhibitNoStrict)
        *{"${class}::$global_rss"} = sub {
            my $self = shift;
            return $self->_process( global => $global_rss );
        };
    }
}

sub new {
    my ( $class, @args ) = @_;

    my $self = $class->SUPER::new(@args);
    if ( !$self->ua ) {
        $self->ua( LWP::UserAgent->new );
    }
    return $self;
}

sub parse_rss {
    my ( $self, $rss ) = @_;

    # hack for a problem caused by control code.
    $rss =~ s/(=KjYe06lbN7U[^\x03]+)\x03/$1/gmsx;

    my $result = XMLin( $rss, NSExpand => 1 );

    # These are different between each RSS.
    if ( !$result->{channel}->{link} ) {
        carp qq{!$result->{channel}->{link}};
    }
    if ( !$result->{channel}->{title} ) {
        carp qq{!$result->{channel}->{title}};
    }
    if ( !$result->{channel}->{description} ) {
        carp qq{!$result->{channel}->{description}};
    }

    my $mrss = 'http://search.yahoo.com/mrss/';    # namespace

    # extract data
    my @videos;
    foreach my $item ( @{ $result->{channel}->{item} } ) {
        my $author = $item->{"{$mrss}credit"};
        my $url    = $item->{"{$mrss}player"}->{url};
        ( my $id = $url ) =~ s/^.+\?v=//msx;
        my $title          = $item->{"{$mrss}title"};
        my $length_seconds = $item->{enclosure}->{length};
        my $upload_time    = str2time( $item->{pubDate} );
        my $tags           = $item->{"{$mrss}category"}->{content};
        my $thumbnail_url  = $item->{"{$mrss}thumbnail"}->{url};

        my $description_xhtml = $item->{description};
        my ($description) =
          $description_xhtml =~ m{.+<p>\s+(.+?)\s+</p>\s+<p>}msx;

        my $thumbnail_width  = $item->{"{$mrss}thumbnail"}->{width};
        my $thumbnail_height = $item->{"{$mrss}thumbnail"}->{height};

        # assertion
        if ( $item->{"{$mrss}category"}->{label} ne 'Tags' ) {
            carp qq{$item->{"{$mrss}category"}->{label} ne 'Tags'};
        }
        if ( $item->{enclosure}->{url} ne "http://youtube.com/v/$id.swf" ) {
            carp
              qq{$item->{enclosure}->{url} ne "http://youtube.com/v/$id.swf"};
        }
        if ( $item->{enclosure}->{type} ne 'application/x-shockwave-flash' ) {
            carp
              qq{$item->{enclosure}->{type} ne 'application/x-shockwave-flash'};
        }
        if ( $item->{author} ne "rss\@youtube.com ($author)" ) {
            carp qq{$item->{author} ne "rss\@youtube.com ($author)"};
        }
        if ( $item->{title} ne $title ) {
            carp qq{$item->{title} ne $title};
        }
        if ( $item->{guid}->{isPermaLink} ne 'true' ) {
            carp qq{$item->{guid}->{isPermaLink} ne 'true'};
        }
        if ( $item->{guid}->{content} ne $url ) {
            carp qq{$item->{guid}->{content} ne $url};
        }
        if ( $item->{link} ne $url ) {
            carp qq{$item->{link} ne $url};
        }

        my $video = WebService::YouTube::Video->new(
            {
                author         => $author,
                id             => $id,
                title          => $title,
                length_seconds => $length_seconds,
                rating_avg     => undef,
                rating_count   => undef,
                description    => $description,
                view_count     => undef,
                upload_time    => $upload_time,
                comment_count  => undef,
                tags           => $tags,
                url            => $url,
                thumbnail_url  => $thumbnail_url,
            }
        );
        push @videos, $video;
    }
    return @videos;
}

sub tag {
    my ( $self, $tag ) = @_;

    return $self->_process( tag => $tag );
}

sub user {
    my ( $self, $user ) = @_;

    return $self->_process( user => $user );
}

sub _process {
    my ( $self, $type, $arg ) = @_;

    my $uri = WebService::YouTube::Util->rss_uri( $type, $arg );
    my $res = $self->ua->get($uri);
    if ( !$res->is_success ) {
        carp $res->status_line;
        return;
    }
    return $self->parse_rss( $res->content );
}

1;

__END__

=head1 NAME

WebService::YouTube::Feeds - Perl interfece to YouTube RSS Feeds

=head1 VERSION

This document describes WebService::YouTube::Feeds version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube::Feeds;
    
    my $feeds = WebService::YouTube::Feeds->new( { ua => '...' } );
    
    my @videos = $feeds->tag($tag);
    my @videos = $feeds->user($user);
    my @videos = $feeds->recently_added;
    my @videos = $feeds->recently_featured;
    my @videos = $feeds->top_favorites;
    my @videos = $feeds->top_rated;
    my @videos = $feeds->most_discussed_month;
    my @videos = $feeds->most_discussed_today;
    my @videos = $feeds->most_discussed_week;
    my @videos = $feeds->top_viewed;
    my @videos = $feeds->top_viewed_month;
    my @videos = $feeds->top_viewed_today;
    my @videos = $feeds->top_viewed_week;

=head1 DESCRIPTION

This is a Perl interface to YouTube RSS Feeds.

See B<About RSS> L<http://youtube.com/rssls> for details.

=head1 SUBROUTINES/METHODS

=head2 new( \%fields )

Creates and returns a new WebService::YouTube::Feeds object.
%fields can contain parameters enumerated in L</ACCESSORS> section.

=head2 parse_rss($rss)

Parses RSS and returns the result.
$rss should be an object that L<XML::Simple> can understand.

=head2 tag( $tag )

Returns an array of L<WebService::YouTube::Video> object.
$tag is a keyword string separated by a space.

See L<http://youtube.com/rssls> for details.

=head2 user( $user )

Returns an array of L<WebService::YouTube::Video> object.
$user is an username.

See L<http://youtube.com/rssls> for details.

=head2 recently_added( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 recently_featured( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_favorites( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_rated( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 most_discussed_month( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 most_discussed_today( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 most_discussed_week( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_viewed( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_viewed_month( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_viewed_today( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 top_viewed_week( )

Returns an array of L<WebService::YouTube::Video> object.

See L<http://youtube.com/rssls> for details.

=head2 ACCESSORS

=head3 ua

L<LWP::UserAgent> object

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube::Feeds requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<HTTP::Date>, L<LWP::UserAgent>, L<XML::Simple>, L<WebService::YouTube::Util>, L<WebService::YouTube::Video>

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
