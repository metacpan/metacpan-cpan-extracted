=head1 NAME

WWW::Shorten::Smallr - Perl interface to Smallr.com

=head1 SYNOPSIS

  use WWW::Shorten::Smallr;

  use WWW::Shorten 'Smallr';

  my $short_url = makeashorterlink($long_url);

=head1 DESCRIPTION

A Perl interface to the web site Smallr.com. Smallr maintains a
database of long URLs, each of which has a unique identifier.

=cut

package WWW::Shorten::Smallr;
use strict;
use warnings;
use Carp;

use base qw( WWW::Shorten::generic Exporter );

our @EXPORT = qw(makeashorterlink);
our $VERSION = '0.01';

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the Smallr.com web site,
pass it your long URL, and return the shortened version.

=cut

sub makeashorterlink ($)
{
  my $smallr = 'http://smallr.com/url/make';
  my $base_url = 'http://smallr.com/';
  my $url = shift or croak 'No URL passed to makeashorterlink';
  my $ua = __PACKAGE__->ua();

  my $resp = $ua->post($smallr,
                       [ url => $url, submit => 'submit' ]);

  return unless $resp->is_success;

  if ($resp->content =~ m!<h2 id="shortUrl"><a href="/(.*?)"!) {
  #if ($resp->content =~ m!Your shorter link is: <a href="(.*?)">!) {
      return "$base_url$1";
  }
  return;
}

1;

__END__

=head2 EXPORT

makeashorterlink

=head1 SUPPORT, LICENCE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://smallr.com/>

=cut
