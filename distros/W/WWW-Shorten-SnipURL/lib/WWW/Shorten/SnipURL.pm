package WWW::Shorten::SnipURL;

use 5.006;
use strict;
use warnings;

use Carp ();
use HTTP::Request::Common 'POST';
use Try::Tiny qw(try catch);

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT  = qw(makeashorterlink makealongerlink);
our $VERSION = '2.023';
$VERSION = eval $VERSION;

sub makeashorterlink {
    my $url     = shift or Carp::croak('No URL passed to makeashorterlink');
    my $ua      = __PACKAGE__->ua();
    my $snipurl = 'http://wwww.snipurl.com/site/index';
    my $req     = POST $snipurl, [url => $url,];
    my $resp
        = try { return $ua->request($req); } catch { warn $_; return undef };
    return unless $resp;
    return unless $resp->is_success;

    if ($resp->content
        =~ m|<input name="SNIPPED" class="snipped textsnipped" type="text" value="(http://snipurl.com/\w+)"|
        )
    {
        return $1;
    }
    return;
}

sub makealongerlink {
    my $code = shift
        or Carp::croak('No SnipURL key / URL passed to makealongerlink');
    my $ua = __PACKAGE__->ua();
    $code = "http://snipurl.com/$code" unless ($code =~ m|^http://|i);

    my $resp = try { return $ua->get($code); } catch { warn $_; return undef };
    return unless $resp;
    return unless $resp->is_redirect;
    return $resp->header('Location');
}

1;

=head1 NAME

WWW::Shorten::SnipURL - Perl interface to L<http://SnipURL.com>

=head1 SYNOPSIS

  use strict;
  use warnings;

  use WWW::Shorten 'SnipURL'; # recommended
  # use WWW::Shorten::SnipURL; # also available

  my $long_url = 'http://www.foo.com/bar/';
  my $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

B<WARNING:> L<http://snipurl.com> does not provide an API.  We must scrape the
resulting HTML.

* Also, their service has been up and down quite a bit lately.  We have disabled
live tests due to this.

* You have been warned.  We suggest using another L<WWW::Shorten> service.

A Perl interface to the web service L<http://SnipURL.com>. The service maintains a
database of long URLs, each of which has a unique identifier or
nickname. For more features, please visit L<http://snipurl.com/features>.

=head1 Functions

L<WWW::Shorten::SnipURL> makes the following functions available.

=head2 makeashorterlink

  my $short = makeashorterlink('http://www.example.com/');

The function C<makeashorterlink> will call use the web service, passing it
your long URL and will return the shorter version.

=head2 makealongerlink

  my $long = makealongerlink('ablkjadf2314sfd');
  my $long = makealongerlink('http://snipurl.com/ablkjadf2314sfd');

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Shashank Tripathi <shank@shank.com>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener C<capoeirab@cpan.org>

=item *

Dave Cross C<dave@perlhacks.com>

=back

=head1 COPYRIGHT AND LICENSE

See the main L<WWW::Shorten> docs.

=head1 SEE ALSO

L<WWW::Shorten>, L<http://shorl.com/>

=cut
