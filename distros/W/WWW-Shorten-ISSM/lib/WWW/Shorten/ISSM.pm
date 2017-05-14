# $Id$

=head1 NAME

WWW::Shorten::ISSM - Perl interface to issm.tk

=head1 SYNOPSIS

  use WWW::Shorten::ISSM;
  use WWW::Shorten 'ISSM';

  $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site ISSM.tk.  ISSM simply maintains
a database of long URLs, each of which has a unique identifier.

=cut

package WWW::Shorten::ISSM;

use 5.006;
use strict;
use warnings;
use Carp qw(croak carp);
use LWP::Simple;
use WWW::Shorten::generic;
use Exporter;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );


=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the ISSM web site passing
it your long URL and will return the shorter ISSM version.

=cut

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $alias = get("http://issm.tk/api/add.pl?url=".$url) or croak('Getting link failed.');
    chomp $alias;
    return 'http://issm.tk/?a='.$alias;
}

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full ISSM URL or just the
ISSM identifier.

If anything goes wrong, then either function will return C<undef>.

=cut

sub makealongerlink {
    my $link = shift or croak 'No url passed to makealongerlink';
    my $longurl = get("http://issm.tk/api/reverse.pl?id=".$link);
    chomp $longurl;
    return $longurl;
}

1;

__END__

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 AUTHOR

Alexandria Marie Wolcott <alyx@cpan.org>

Aaron Blakley <aaron@ephasic.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://ISSM.tk/>

=cut
