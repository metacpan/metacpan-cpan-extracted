
# $Id: ES.pm,v 2.104 2013-03-03 15:03:57 Martin Exp $

=head1 NAME

WWW::Search::Ebay::ES - backend for searching auctions at eBay Spain

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::ES');
  my $sQuery = WWW::Search::escape_query("Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package WWW::Search::Ebay::ES;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 2.104 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $self->{search_host} = 'http://www.ebay.es';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_element_specs_USE_DEFAULT
  {
  return (
          '_tag' => 'div',
          class => 'count'
         );
  } # _result_count_element_specs


sub _result_count_pattern
  {
  return qr'(?:encontrados?\s+)?(\d+)\s+(art(í|Ã­)culo|resultado|anuncio)s?';
  } # _result_count_pattern


sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Siguiente';
  } # _next_text

sub _currency_pattern
  {
  my $self = shift;
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  my $W = $self->whitespace_pattern;
  return qr{[\d.,]+$W+EUR}; # } } # Emacs indentation bugfix
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
  # This is for ES:
  return qw( paypal bids price shipping enddate );
  } # _columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  $s =~ s!Tiempo\s+restante:!!gi;
  # Convert Spanish abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)d!$1 days!;
  $s =~ s!(\d)h!$1 hours!;
  $s =~ s!(\d)m!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__
