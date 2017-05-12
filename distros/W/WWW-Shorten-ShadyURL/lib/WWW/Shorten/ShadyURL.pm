package WWW::Shorten::ShadyURL;
#
#   WWW::Shorten module for shadyurl.com
#
#   $Id: ShadyURL.pm 141 2010-05-18 03:41:20Z infidel $
#

use 5.006;
#use URI::Escape qw( uri_escape uri_unescape );
use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
our $VERSION = '0.03';

use Carp;

###
### Vars
###

my $shortener_url = 'http://www.shadyurl.com/create.php?myUrl=';
my $arg_sep       = '&';
my $params        = {
    'shorten'  => '&shorten=on',
};
my $url_map       = {
    '5z8.info' => 'www.5z8.info',
};

=head1 NAME

WWW::Shorten::ShadyURL - Perl interface to shadyurl.com

=head1 SYNOPSIS

  use WWW::Shorten::ShadyURL;

  use WWW::Shorten 'ShadyURL';

  $shady_url = makeashorterlink( $long_url );

  $orig_url  = makealongerlink( $shady_url );

=head1 DESCRIPTION

A Perl interface to the web site shadyurl.com. ShadyURL simply maintains
a database of long URLs, each of which has a unique identifier, that
appears at first glance "shady", but resolves just like any other shortener
service.  However, the URLS may not be actually shorter, just sketchier.

Their motto is:

=over 4

I<Don't just shorten your URL, make it suspicious and frightening.>

=back

I am not affiliated with them.  See L<http://shadyurl.com/> for more
information.

=head1 FUNCTIONS

=head2 B<makeashorterlink>( $url [, $shorten ] )

The function C<makeashorterlink> will connect to the ShadyURL web site and
attempt to create an alias to the URL supplied.

=head3 Arguments:

B<$url> [required] - The URL you wish to shorten.

B<$shorten> [optional] - Set to a C<TRUE> value to actually create a short link.

The ShadyURL service creates links that appear sketchy, there is no guarantee
that they will actually be shorter than the supplied URL.  This attempts to
make them shorter, but they will then appear less dubious.

=cut

sub makeashorterlink ($;$)
{
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $shorten = shift;

    # Construct the request URL
    my @url_args;
#    $url  = $shortener_url . uri_escape( $url );
    $url  = $shortener_url . $url;
    push( @url_args, $params->{'shorten'} ) if( $shorten );
    $url = join( $arg_sep, $url, @url_args );

    # Get the page
    my $ua = __PACKAGE__->ua();
    my $resp = $ua->get( $url );
    return unless $resp->is_success;

    # HTML manual parsing = evil, but there's no API, and I'm not going
    # to pull in a whole parser.  If ShadyURL starts making a lot of
    # changes, I'll do it in a later revision.  Deal.
    my $content = $resp->decoded_content;
    my ( $shorturl ) = $content =~ m#is now.*?href.*?\>(.*?)\</a>#;

    return( $shorturl );
}

=head2 B<makealongerlink>( $shorturl )

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument a full ShadyURL link.

If anything goes wrong, then either function will return C<undef>.

=cut

sub makealongerlink ($)
{
    my $url = shift
        or croak 'No URL passed to makealongerlink';

    # skip unnecessary shadyURL double redirects ( canonical -> www. )
    $url =~ s/\Q$_\E/$url_map->{$_}/  
        for( keys( %$url_map ) );

    # get Location header
    my $ua = __PACKAGE__->ua();
    my $resp = $ua->get( $url );
    my $location = $resp->header('Location');

#    return uri_unescape( $location ) if( $location );
    return $location if( $location );
    return;
}

1;

__END__

=head1 EXPORT

C<makeashorterlink>, C<makealongerlink>

=head1 SUPPORT, LICENCE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

Note: I am not affiliated with shadyurl.com.  If you have problems with
their service, contact them.

=head1 AUTHOR

Jason McManus <infidel AT cpan.org>

Based on WWW::Shorten by Dave Cross <dave AT dave.org.uk>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://shadyurl.com/>

=cut
