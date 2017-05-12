
=head1 NAME

WWW::Search::Yahoo::Germany - class for searching Yahoo! Deutschland

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::Germany');
  my $sQuery = WWW::Search::escape_query("ich liebe dich");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    {
    print $oResult->url, "\n";
    } # while

=head1 DESCRIPTION

This module is just a synonym for L<WWW::Search::Yahoo::Deutschland>.

=head1 AUTHOR

Martin Thurn C<mthurn@cpan.org>

=cut

package WWW::Search::Yahoo::Germany;

use strict;
use warnings;

use base 'WWW::Search::Yahoo::Deutschland';

our
$VERSION = do { my @r = (q$Revision: 2.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

1;

__END__
