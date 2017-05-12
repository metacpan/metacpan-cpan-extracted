
# $Id: Motors.pm,v 1.20 2014-09-02 01:50:28 Martin Exp $

=head1 NAME

WWW::Search::Ebay::Motors - backend for searching eBay Motors

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Motors');
  my $sQuery = WWW::Search::escape_query("Buick Star Wars");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay Motors specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Same as L<WWW::Search::Ebay>.

=head1 OPTIONS

Same as L<WWW::Search::Ebay>.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LEGALESE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay::Motors;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.20 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  if (ref($rhOptsArg) ne 'HASH')
    {
    carp " --- second argument to _native_setup_search should be hashref";
    return;
    } # unless
  # As of 2013-03:
  # http://motors.shop.ebay.com/eBay-Motors-/6000/i.html?_nkw=bugatti&_trksid=p2050890.m570.l1313&_rdc=1
  $rhOptsArg->{search_host} = 'http://motors.shop.ebay.com';
  $rhOptsArg->{search_path} = '/eBay-Motors-/6000/i.html';
  $self->{_options} = {
                       _nkw => $native_query,
                       _armrs => 1,
                       # _trksid => 'p2050890.m570.l1313',
                       # Turn off JavaScript:
                       _jsoff => 1,
                       # Search AUCTIONS ONLY:
                       LH_Auction => 1,
                       _ipg => $self->{_hits_per_page},
                       _rdc => 1,
                      };
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

sub _columns
  {
  my $self = shift;
  return qw( price bids junk enddate );
  } # _columns

1;

__END__

