
# $Id: Category.pm,v 2.5 2015-09-13 14:27:26 Martin Exp $

=head1 NAME

WWW::Search::Ebay::Category - backend for returning entire categories on www.ebay.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Category');
  # Category 1381 is Disney Modern Premiums:
  $oSearch->native_query(1381);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of L<WWW::Search>.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Returns the "first" 200 *auction* items in the given category.
I'm not sure what exactly "first" means in this case; YMMV.

It is up to you to determine the number of the category you want.

See the NOTES section of L<WWW::Search::Ebay> for a description of the results.

=head1 METHODS

=cut

#####################################################################

package WWW::Search::Ebay::Category;

use strict;
use warnings;

use Carp;
use Date::Manip;
use base 'WWW::Search::Ebay';

our
$VERSION = do { my @r = (q$Revision: 2.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use constant DEBUG_FUNC => 0;

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to _native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $self->{_options} = {
                       _ipg => 200,
                       _sacat => $native_query,
                      };
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search


sub _preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # preprocess_results_page

sub _columns_use_SUPER
  {
  my $self = shift;
  # This is for basic USA eBay:
  return qw( paypal bids price shipping enddate );
  } # _columns


1;

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Maintained by Martin Thurn, C<mthurn@cpan.org>, L<http://www.sandcrawler.com/SWB/cpan-modules.html>.

=head1 LEGALESE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

__END__
