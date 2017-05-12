package WWW::Shorten::MahewinSexyUrl;

use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT  = qw( makeashorterlink makealongerlink );
our $VERSION = '0.2';

use Carp;

sub makeashorterlink ($) {
    my $url         = shift or croak 'No URL passed to makeashorterlink';
    my $ua          = __PACKAGE__->ua();
    my $service_url = 'http://msud.pl';

    my $resp = $ua->post($service_url, [
        sexy_url => $url,
        source   => "PerlAPI-$VERSION",
    ]);

    return undef unless $resp->header('X-ShortUrl');
    return $service_url . '/' . $resp->header('X-ShortUrl');
}

sub makealongerlink ($) {
    my $msud = shift or croak 'No msud key / url passed to makealongerlink';
    my $ua   = __PACKAGE__->ua();

    $msud = "http://msud.pl/$msud" unless $msud =~ m/^http:\/\//i;

    my $resp = $ua->get($msud);

    return undef unless $resp->is_redirect;
    my $url = $resp->header('Location');

    return $url;
}

1;

__END__

=head1 NAME

=encoding utf8

WWW::Shorten::MahewinSexyUrl - Perl interface to msud.pl

=head1 SYNOPSIS

  use WWW::Shorten 'MahewinSexyUrl';

  my $long_url  = 'http://essai.fr';
  my $short_url = 'http://msud.pl/O0';

  my $short_url = makeashorterlink($long_url);
  my $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site msud.pl. MahewinSexyUrl simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the MahewinSexyUrl web site passing
it your long URL and will return the shorter MahewinSexyUrl version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full MahewinSexyUrl URL or just the
MahewinSexyUrl identifier.

If anything goes wrong, then either function will return C<undef>.

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 SUPPORT, LICENCE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 AUTHOR

Natal Ngétal <hobbestig@cpan.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://msud.pl/>

=cut

