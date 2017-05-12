
# $Id: UK.pm,v 2.6 2013-03-17 01:11:23 Martin Exp $

=head1 NAME

WWW::Search::Ebay::UK - backend for searching auctions at www.ebay.co.uk

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::UK');
  my $sQuery = WWW::Search::escape_query("Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::UK;

use strict;
use warnings;

use Carp;
use WWW::Search::Ebay 2.258;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.6 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $self->{search_host} = 'http://www.ebay.co.uk';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_element_specs_USE_DEFAULT
  {
  return (
          '_tag' => 'p',
          id => 'count'
         );
  } # _result_count_element_specs


sub _currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|£)}; # } } # Emacs indentation bugfix
  } # _currency_pattern

sub _preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # print STDERR Dumper($self->{response});
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # preprocess_results_page

sub _columns
  {
  my $self = shift;
  # This is for UK:
  return qw( paypal bids price repeat postage enddate );
  } # _columns

1;

__END__
