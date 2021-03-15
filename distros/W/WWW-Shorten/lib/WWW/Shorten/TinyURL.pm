package WWW::Shorten::TinyURL;

use strict;
use warnings;
use Carp ();

use base qw( WWW::Shorten::generic Exporter );
our $_error_message = '';
our @EXPORT         = qw( makeashorterlink makealongerlink );
our $VERSION = '3.094';

sub makeashorterlink {
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    $_error_message = '';

    # terrible, bad!  skip live testing for now.
    if ( $ENV{'WWW-SHORTEN-TESTING'} ) {
        return 'https://tinyurl.com/abc12345'
            if ( $url eq 'https://metacpan.org/release/WWW-Shorten' );
        $_error_message = 'Incorrect URL for testing purposes';
        return undef;
    }

    # back to normality.
    my $ua      = __PACKAGE__->ua();
    my $tinyurl = 'https://tinyurl.com/api-create.php';
    my $resp
        = $ua->post($tinyurl, [url => $url, source => "PerlAPI-$VERSION",]);
    return undef unless $resp->is_success;
    my $content = $resp->content;
    if ($content =~ /Error/) {

        if ($content =~ /<html/) {
            $_error_message = 'Error is a html page';
        }
        elsif (length($content) > 100) {
            $_error_message = substr($content, 0, 100);
        }
        else {
            $_error_message = $content;
        }
        return undef;
    }
    if ($resp->content =~ m!(\Qhttps://tinyurl.com/\E\w+)!x) {
        return $1;
    }
    return;
}

sub makealongerlink {
    my $url = shift
        or Carp::croak('No TinyURL key / URL passed to makealongerlink');
    $_error_message = '';
    $url = "https://tinyurl.com/$url"
        unless $url =~ m!^https://!i;

    # terrible, bad!  skip live testing for now.
    if ( $ENV{'WWW-SHORTEN-TESTING'} ) {
        return 'https://metacpan.org/release/WWW-Shorten'
            if ( $url eq 'https://tinyurl.com/abc12345' );
        $_error_message = 'Incorrect URL for testing purposes';
        return undef;
    }

    # back to normality
    my $ua = __PACKAGE__->ua();

    my $resp = $ua->get($url);

    unless ($resp->is_redirect) {
        my $content = $resp->content;
        if ($content =~ /Error/) {
            if ($content =~ /<html/) {
                $_error_message = 'Error is a html page';
            }
            elsif (length($content) > 100) {
                $_error_message = substr($content, 0, 100);
            }
            else {
                $_error_message = $content;
            }
        }
        else {
            $_error_message = 'Unknown error';
        }

        return undef;
    }
    my $long = $resp->header('Location');
    return $long;
}

1;

=head1 NAME

WWW::Shorten::TinyURL - Perl interface to L<https://tinyurl.com>

=head1 SYNOPSIS

  use strict;
  use warnings;

  use WWW::Shorten::TinyURL;
  use WWW::Shorten 'TinyURL';

  my $short_url = makeashorterlink('https://www.foo.com/some/long/url');
  my $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site L<https://tinyurl.com>.  The service simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the L<https://TinyURL.com> web site passing
it your long URL and will return the shorter version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, then either function will return C<undef>.

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 SUPPORT, LICENSE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<https://tinyurl.com/>

=cut
