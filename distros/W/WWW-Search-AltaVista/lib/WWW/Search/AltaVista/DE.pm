# DE.pm
# by Martin Thurn
# $Id: DE.pm,v 1.5 2008/01/21 02:04:11 Daddy Exp $

=head1 NAME

WWW::Search::AltaVista::DE - class for searching www.AltaVista.DE

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('AltaVista::DE');

=head1 DESCRIPTION

This class handles making and interpreting AltaVista Germany searches
F<http://www.altavista.de>.

Details of AltaVista can be found at L<WWW::Search::AltaVista>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 AUTHOR

Martin Thurn C<mthurn@cpan.org>

=cut

#####################################################################

package WWW::Search::AltaVista::DE;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';
our
$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/o);

=head2 native_setup_search

This private method does the heavy lifting after native_query() is called.

=cut

sub native_setup_search
  {
  my $self = shift;
  my $sQuery = shift;
  if (!defined($self->{_options})) {
    $self->{_options} = {
                         'nbq' => '50',
                         'q' => $sQuery,
                         'search_host' => 'http://de.altavista.com',
                         'search_path' => '/web/results',
                        };
    };
  # Let AltaVista.pm finish up the hard work:
  return $self->SUPER::native_setup_search($sQuery, @_);
  } # native_setup_search

1;

__END__

