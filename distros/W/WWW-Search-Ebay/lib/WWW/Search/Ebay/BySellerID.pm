
# $Id: BySellerID.pm,v 2.14 2014-09-01 21:49:09 Martin Exp $

=head1 NAME

WWW::Search::Ebay::BySellerID - backend for searching eBay for items offered by a particular seller

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::BySellerID');
  my $sQuery = WWW::Search::escape_query("martinthurn");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

See L<WWW::Search::Ebay> for details.
The query string must be an eBay seller ID.

This class is an Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Searches only for items offered by eBay sellers whose ID matches exactly.

See L<WWW::Search::Ebay> for explanation of the results.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LICENSE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

=cut

package WWW::Search::Ebay::BySellerID;

use strict;
use warnings;

use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.14 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # As of 2013-03:
  # http://www.ebay.com/sch/allhypedup82/m.html?_ipg=200&_sop=1&_rdc=1
  $rh->{search_host} = 'http://www.ebay.com';
  $rh->{search_path} = qq'/sch/$sQuery/m.html';
  $self->{_options} = {
                       _ipg => $self->{_hits_per_page},
                       _rdc => 1,
                       _sop => 1,
                      };
  return $self->SUPER::_native_setup_search($sQuery, $rh);
  # Old version:
  $rh->{'MfcISAPICommand'} = 'MemberSearchResult';
  $rh->{'frompage'} = 'itemsbyseller';
  $rh->{'sofindtype'} = '26';
  $rh->{'userid'} = $sQuery;
  # $rh->{'completed'} = 1;  # Also return completed auctions
  # $rh->{'since'} = 30;  # The oldest possible
  # $rh->{'include'} = 1;  # also return bidders email addresses (only
                         # possible if you login)
  $rh->{'fcm'} = 0;  # Whether to return "similar" user ids
  $rh->{'frpp'} = '200';  # Results per page
  $rh->{'submit'} = 'Search';
  # Don't know what the rest are for:
  $rh->{'fcl'} = '3';
  $rh->{'amp;sspagename'} = 'h:h:advsearch:US';
  $rh->{'sacat'} = '-1';
  $rh->{'nojspr'} = 'y';
  $rh->{'catref'} = 'C5';
  $rh->{'from'} = 'R7';
  $rh->{'pfid'} = '0';
  return $self->SUPER::_native_setup_search('', $rh);
  } # _native_setup_search

sub _columns_NOT_NEEDED
  {
  my $self = shift;
  # This is for basic USA eBay:
  return qw( enddate price repeat bids );
  } # _columns

1;

__END__

