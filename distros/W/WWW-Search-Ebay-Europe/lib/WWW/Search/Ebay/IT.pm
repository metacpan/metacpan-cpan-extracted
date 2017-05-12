
package WWW::Search::Ebay::IT;

use strict;
use warnings;

our
$VERSION = 2.106;

=head1 NAME

WWW::Search::Ebay::IT - backend for searching auctions at eBay Italy

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::IT');
  my $sQuery = WWW::Search::escape_query("Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

use Carp;
use WWW::Search::Ebay 2.258;
use base 'WWW::Search::Ebay';

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $self->{search_host} = 'http://www.ebay.it';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search


sub _result_count_pattern
  {
  return qr'(\d+)\s+(oggetti|inserzioni|risultati)';
  } # _result_count_pattern


sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Avanti';
  } # _next_text

sub _currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  my $W = $self->whitespace_pattern;
  return qr{(?:US\s?\$|£|EUR)$W*[\d.,]+}; # } } # Emacs indentation bugfix
  } # _currency_pattern

sub _preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  # print STDERR Dumper($self->{response});
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # _preprocess_results_page

sub _columns
  {
  my $self = shift;
  # This is for IT:
  return qw( paypal bids price repeat shipping enddate );
  } # _columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  # Convert Italian abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)g!$1 days!;
  $s =~ s!(\d)h!$1 hours!;
  $s =~ s!(\d)m!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__
