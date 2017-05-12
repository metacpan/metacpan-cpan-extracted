package WWW::Shorten::Googl;

use strict;
use warnings;
use Carp                 ();
use HTTP::Request        ();
use LWP::Protocol::https ();
use JSON::MaybeXS        ();
use URI                  ();

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT  = qw( makeashorterlink makealongerlink );
our $VERSION = '1.100';
$VERSION = eval $VERSION;
use constant API_URL => 'https://www.googleapis.com/urlshortener/v1/url';

{
    # As docs advice you use this module as "use WWW::Shorten 'Googl'"
    # that module takes care of the importing.. so let's hack this in here
    no strict 'refs';
    *{"main::getlinkstats"} = *{"WWW::Shorten::Googl::getlinkstats"};
}

sub makeashorterlink {
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');

    my $request = HTTP::Request->new('POST', URI->new(API_URL));
    $request->content(JSON::MaybeXS::encode_json({longUrl => $url}));
    if (my $res = _req($request)) {
        return $res->{id} if ($res->{id});
        Carp::croak("Couldn't find the shorter URL");
    }
    Carp::croak("Unable to get a response");
}

sub makealongerlink {
    my $url = shift or Carp::croak('No URL passed to makealongerlink');
    $url = "http://goo.gl/$url" unless $url =~ m!^http://!i;

    my $endpoint = URI->new(API_URL);
    $endpoint->query_form(shortUrl => $url);
    my $request = HTTP::Request->new('GET', $endpoint);

    if (my $res = _req($request)) {
        return $res->{longUrl} if ($res->{longUrl});
        Carp::croak("Couldn't find the longer URL");
    }
    Carp::croak("Unable to get a response");
}

sub getlinkstats {
    my $url = shift or Carp::croak('No URL passed to getlinkstats');
    $url = "http://goo.gl/$url" unless $url =~ m!^http://!i;

    my $endpoint = URI->new(API_URL);
    $endpoint->query_form(projection => 'FULL', shortUrl => $url);
    my $request = HTTP::Request->new('GET', $endpoint);

    if (my $res = _req($request)) {
        return $res;
    }
    Carp::croak("Unable to get a response");
}

sub _api_key { $ENV{GOOGLE_API_KEY} || '' }

sub _req {
    my $request = shift or Carp::croak("Expected an HTTP::Request object");
    $request->header('Content-Type' => 'application/json');
    $request->uri->query_form($request->uri->query_form(), key => _api_key());

    my $ua = __PACKAGE__->ua();

    if (my $res = $ua->request($request)) {
        if ($res->is_success()) {
            Carp::croak("Couldn't parse JSON response")
                unless (my $data = JSON::MaybeXS::decode_json($res->content));
            return $data;
        }
        else {
            Carp::croak("Request failed - " . $res->status_line);
        }
    }
    else {
        Carp::croak("Unable to get response");
    }
}

1;

__END__

=head1 NAME

WWW::Shorten::Googl - Perl interface to L<http://goo.gl/>

=head1 SYNOPSIS

  use strict;
  use warnings;

  use WWW::Shorten::Googl; # OR
  # use WWW::Shorten 'Googl';

  # $ENV{GOOGLE_API_KEY} should be set

  my $url = 'http://metacpan.org/pod/WWW::Shorten::Googl';
  my $short_url = makeashorterlink($url);
  my $long_url  = makealongerlink($short_url);

  # Note - this function is specific to the Googl shortener
  my $stats = getlinkstats( $short_url );

=head1 DESCRIPTION

A Perl interface to the L<http://goo.gl/> URL shortening service. Googl simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 FUNCTIONS

=head2 makeashorterlink

The function C<makeashorterlink> will call the Googl web site passing
it your long URL and will return the shorter Googl version.

If you provide your Google username and password, the link will be added
to your list of shortened URLs at L<http://goo.gl/>.

See AUTHENTICATION for details.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

=head2 getlinkstats

Given a L<http://goo.gl/> URL, returns a hash ref with statistics about the URL.

See L<http://code.google.com/apis/urlshortener/v1/reference.html#resource_url>
for information on which data can be present in this hash ref.

=head1 AUTHENTICATION

To use this shorten service, you'll first need to setup an
L<API Key|https://developers.google.com/url-shortener/v1/getting_started#APIKey>.

Once you have that key setup, you will need to set the C<GOOGLE_API_KEY> environment
variable to use that key.

=head1 AUTHOR

Magnus Erixzon <F<magnus@erixzon.com>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2004, Magnus Erixzon <F<magnus@erixzon.com>>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Shorten>, L<http://goo.gl/>, L<API Reference|https://developers.google.com/url-shortener/v1/getting_started>

=cut
