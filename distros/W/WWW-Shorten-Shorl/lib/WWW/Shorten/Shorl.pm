package WWW::Shorten::Shorl;

use 5.006;
use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
use Carp qw();
use URI ();
use Try::Tiny qw(try catch);

our @EXPORT  = qw(makeashorterlink makealongerlink);
our $VERSION = '2.101';
$VERSION = eval $VERSION;

sub makeashorterlink {
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    my $ua = __PACKAGE__->ua();
    $ua->agent('Mozilla/5.0');
    my $shorl = URI->new('http://shorl.com/create.php');
    $shorl->query_form(url => $url);
    my $resp = try { return $ua->get($shorl); } catch { warn $_; return undef };
    return unless $resp;
    return unless $resp->is_success;
    if (
        $resp->content =~ m!
        Shorl:\s+
        <a\s+href="http://shorl\.com/\w+"\s+rel="nofollow">\s*
        (http://shorl\.com/\w+)
        </a>.*?<br>\s*Password:\s+(\w+)
    !xms
        )
    {
        return wantarray ? ($1, $2) : $1;
    }
    return;
}

sub makealongerlink {
    my $shorl_url = shift
        or Carp::croak('No Shorl key / URL passed to makealongerlink');
    my $ua = __PACKAGE__->ua();

    $shorl_url = "http://shorl.com/$shorl_url"
        unless $shorl_url =~ m!^http://!i;

    my $resp
        = try { return $ua->get($shorl_url); } catch { warn $_; return undef };
    return unless $resp;
    return if $resp->is_error;
    my ($url) = $resp->content =~ /URL=(.+)\"/;
    return $url;
}

1;

=head1 NAME

WWW::Shorten::Shorl - Perl interface to http://shorl.com

=head1 SYNOPSIS

  use strict;
  use warnings;

  use WWW::Shorten 'Shorl'; # recommended
  # use WWW::Shorten::Shorl; # also available

  my $long_url = 'http://www.foo.com/bar/';
  my $short_url = makeashorterlink($long_url);
  my ($short_url,$password) = makeashorterlink($long_url);

  $long_url = makealongerlink($short_url);

=head1 DESCRIPTION

B<WARNING:> L<http://shorl.com> does not provide an API.  We must scrape the
resulting HTML.

* Also, they prevent multiple usages of their service within a changing time
frame.  Due to this, all live tests against this service have been skipped.

* You have been warned.  We suggest using another L<WWW::Shorten> service.

A Perl interface to the web site L<http://shorl.com>.  That service simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 Functions

L<WWW::Shorten::Shorl> makes the following functions available.

=head2 makeashorterlink

  my $short = try { makeashorterlink('http://www.example.com') } catch { warn $_ };

The function C<makeashorterlink> will call use the web service, passing it
your long URL and will return the shorter version. If used in a
list context, then it will return both the shorter URL and the password.

Note that this service, unlike others, returns a unique code for every submission.

=head2 makealongerlink

  my $long = try { makealongerlink('abc11234234adfagv') } catch { warn $_ };

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full short URL or just the
service's identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener C<capoeirab@cpan.org> -- current maintainer

=item *

Dave Cross C<dave@perlhacks.com>

=back

=head1 COPYRIGHT AND LICENSE

See the main L<WWW::Shorten> docs.

=head1 SEE ALSO

L<WWW::Shorten>, L<http://shorl.com/>

=cut
