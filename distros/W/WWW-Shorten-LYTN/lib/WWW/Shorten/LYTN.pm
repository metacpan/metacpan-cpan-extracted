# $Id$

=head1 NAME

WWW::Shorten::LYTN - Perl interface to LYTN

=head1 SYNOPSIS

  use WWW::Shorten::LYTN;
  use WWW::Shorten 'LYTN';

  $short_url = makeashorterlink($long_url);

=head1 DESCRIPTION

A Perl interface to the web site lytn.it.  lytn simply maintains
a database of long URLs, each of which has a unique identifier.  lytn.it
will also track how many hits a URL recieves, but this feature is currently
unavailable.

=cut

package WWW::Shorten::LYTN;

use 5.006;
use strict;
use warnings;
use Carp qw(croak carp);
use LWP::Simple;
use WWW::Shorten::generic;
use Exporter;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink );


=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the lytn web site passing
it your long URL and will return the shorter lytn version.

=cut

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $alias = get("http://lytn.it/api.php?rel=2&link=".$url) or croak('Getting link failed.');
    chomp $alias;
    return $alias;
}

1;

__END__

=head2 EXPORT

makeashorterlink

=head1 AUTHOR

Aaron Blakley <aaron@cpan.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://lytn.it/>

=cut
