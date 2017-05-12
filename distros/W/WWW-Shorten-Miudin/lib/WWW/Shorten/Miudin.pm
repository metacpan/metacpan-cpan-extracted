# $Id$

=head1 NAME

WWW::Shorten::Miudin - Perl interface to miud.in

=head1 SYNOPSIS

  use WWW::Shorten::Miudin;
  use WWW::Shorten 'Miudin';

  $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site miud.in.  Miudin simply maintains
a database of long URLs, each of which has a unique identifier.

=cut

package WWW::Shorten::Miudin;

use 5.006;
use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
our $VERSION = '1.0';

use Carp;

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the Miudin web site passing
it your long URL and will return the shorter Miudin version.

=cut

sub makeashorterlink ($)
{
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $ua = __PACKAGE__->ua();
    my $tinyurl = 'http://miud.in/api-create.php';
    my $resp = $ua->post($tinyurl, [
	url => $url,
	source => "PerlAPI-$VERSION",
	]);
    return undef unless $resp->is_success;
    my $content = $resp->content;
    return undef if $content =~ /Error/;
    if ($resp->content =~ m!(\Qhttp://miud.in/\E\w+)!x) {
	return $1;
    }
    return;
}

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full Miudin URL or just the
Miudin identifier.

If anything goes wrong, then either function will return C<undef>.

=cut

sub makealongerlink ($)
{
    my $tinyurl_url = shift 
	or croak 'No Miudin key / URL passed to makealongerlink';
    my $ua = __PACKAGE__->ua();

    $tinyurl_url = "http://miud.in/$tinyurl_url"
    unless $tinyurl_url =~ m!^http://!i;

    my $resp = $ua->get($tinyurl_url);

    return undef unless $resp->is_redirect;
    my $url = $resp->header('Location');
    return $url;

}

1;

__END__

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 SUPPORT, LICENCE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 AUTHOR

Thiago Rondon, <thiago@aware.com.br>

http://www.aware.com.br/

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://miud.in/>

=cut
