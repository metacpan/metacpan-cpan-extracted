
# $Id: Category.pm,v 1.3 2014-09-09 03:07:56 Martin Exp $

=head1 NAME

WWW::Search::Ebay::Completed::Category - backend for returning entire categories of completed auctions on www.ebay.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Completed::Category');
  # Category 35845 is Disney Modern Bottles:
  $oSearch->native_query(35845);
  $oSearch->login('ebay_username', 'ebay_password');
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of L<WWW::Search>.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Returns the "first" 200 completed items in the given category.
I'm not sure what exactly "first" means in this case; YMMV.

It is up to you to determine the number of the category you want.

See the NOTES section of L<WWW::Search::Ebay> for a description of the results.

=head1 METHODS

=cut

#####################################################################

package WWW::Search::Ebay::Completed::Category;

use strict;
use warnings;

use Carp;
use base 'WWW::Search::Ebay::Completed';

our
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

my $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

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
  # As of August 2014:
  # http://www.ebay.com/sch/Magazine-Back-Issues-/280/i.html?_from=R40%7CR40&LH_Complete=1&_udlo=&_udhi=&_ftrt=901&_ftrv=1&_sabdlo=&_sabdhi=&_samilow=&_samihi=&_sadis=10&_fpos=&_fsct=&LH_SALE_CURRENCY=0&_sop=13&_dmd=1&_ipg=50&_nkw=playboy+october+1977
  $self->{search_host} = 'http://www.ebay.com';
  $self->{search_path} = sprintf(q{/sch/Foo-/%i/i.html}, $native_query);
  return $self->SUPER::_native_setup_search(q{}, $rhOptsArg);
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

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

__END__
