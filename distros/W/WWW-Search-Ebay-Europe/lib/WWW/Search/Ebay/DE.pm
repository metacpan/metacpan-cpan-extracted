
package WWW::Search::Ebay::DE;

use strict;
use warnings;

our
$VERSION = 2.105;

=head1 NAME

WWW::Search::Ebay::DE - backend for searching auctions at www.ebay.de

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::DE');
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
use base 'WWW::Search::Ebay';
# We need the version that allows shipping to be "unknown":
use WWW::Search::Ebay 2.273;

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to _native_setup_search should be hashref";
    return undef;
    } # unless
  $self->{search_host} = 'http://www.ebay.de';
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_element_specs_NOT_NEEDED
  {
  return (
          '_tag' => 'p',
          class => 'count'
         );
  } # _result_count_element_specs


sub _result_count_pattern
  {
  return qr'(\d+)\s+(?:Artikel|Ergebnis(?:se)?|Angebote)'i;
  } # _result_count_pattern

sub _next_text
  {
  # The text of the "Next" button, localized:
  return 'Weiter';
  } # _next_text

sub _currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|£|EUR)}; # } } # Emacs indentation bugfix
  } # _currency_pattern

=head2 preprocess_results_page

Tweak the HTML to make it easy to parse

=cut

sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # Make it easy to parse the shipping portion of the list:
  $sPage =~ s!(<span\s(class="ship[^"]*")>)!</td><td $2>$1!g;
  # Clean up "no shipping info":
  $sPage =~ s/\s*Keine Angaben zum Versand\s*/UNKNOWN/g;
  # print STDERR $sPage;
  return $self->SUPER::preprocess_results_page($sPage);
  # print STDERR Dumper($self->{response});
  # For debugging:
  print STDERR $sPage;
  exit 88;
  } # _preprocess_results_page

sub _columns
  {
  my $self = shift;
  # This is for DE:
  return qw( paypal bids price shipping enddate );
  } # _columns

sub _process_date_abbrevs
  {
  my $self = shift;
  my $s = shift;
  # Convert German abbreviations for units of time to something
  # Date::Manip can parse (namely, English words):
  $s =~ s!(\d)T!$1 days!;
  $s =~ s!(\d)Std\.?!$1 hours!;
  $s =~ s!(\d)Min\.?!$1 minutes!;
  return $s;
  } # _process_date_abbrevs


1;

__END__
