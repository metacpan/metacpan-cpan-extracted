#
# $Id: YouTube.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(dev_id ua));

use Carp;
use WebService::YouTube::Feeds;
use WebService::YouTube::Videos;

sub videos {
    my $self = shift;

    $self->{_videos} ||= WebService::YouTube::Videos->new($self);
    return $self->{_videos};
}

sub feeds {
    my $self = shift;

    $self->{_feeds} ||= WebService::YouTube::Feeds->new($self);
    return $self->{_feeds};
}

1;

__END__

=head1 NAME

WebService::YouTube - Perl interfece to YouTube

=head1 VERSION

This document describes WebService::YouTube version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube;
    
    my $youtube = WebService::YouTube->new( { dev_id => 'YOUR_DEV_ID' } );
    
    # Get videos via REST API
    my @videos = $youtube->videos->list_featured;
    
    # Get videos via RSS Feed
    my @videos = $youtube->feeds->recently_added;

=head1 DESCRIPTION

This is a Perl interface to YouTube API and RSS.
See Developers Page L<http://youtube.com/dev> and About RSS L<http://www.youtube.com/rssls> for details.

B<I<This module support only Legacy API, does not support YouTube Data API based on Google data protocol.>>
See YouTube Data API Overview L<http://code.google.com/apis/youtube/overview.html> for details.

=head1 SUBROUTINES/METHODS

=head2 new(\%fields)

Creates and returns a new WebService::YouTube object.
%fields can contain parameters enumerated in L</ACCESSORS> section.

=head2 videos( )

Returns a L<WebService::YouTube::Videos> object.

=head2 feeds( )

Returns a L<WebService::YouTube::Feeds> object.

=head2 ACCESSORS

=head3 dev_id

Developer ID

=head3 ua

L<LWP::UserAgent> object

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Class::Accessor::Fast>, L<WebService::YouTube::Videos>, L<WebService::YouTube::Feeds>

=head1 INCOMPATIBILITIES

L<WWW::YouTube>

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
