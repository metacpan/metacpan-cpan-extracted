# Ebay/ByEndDate.pm
# by Martin Thurn
# $Id: ByEndDate.pm,v 2.33 2015-06-06 20:22:00 Martin Exp $

=head1 NAME

WWW::Search::Ebay::ByEndDate - backend for searching www.ebay.com, with results sorted with "items ending first"

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::ByEndDate');
  my $sQuery = WWW::Search::escape_query("C-10 carded Yakface");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The calling program must ensure that the Date::Manip module is able to
determine the local timezone.  When Date::Manip changed from version 5
to version 6, the timezone handling was completely overhauled.  See
the documentation of Date::Manip but good luck because it is VERY
confusing and does not contain useful examples.

The search is done against CURRENT running auctions only.

The query is applied to TITLES only.

The results are ordered auctions ending soon first (order of
increasing auction ending date).

In the resulting WWW::Search::Result objects, the description field
consists of a human-readable combination (joined with semicolon-space)
of the Item Number; number of bids; and high bid amount (or starting
bid amount).

In the WWW::Search::Result objects, the change_date field contains the
auction ending date & time in ISO 8601 format;
i.e. YYYY-MM-DDThh:mm:ss.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LEGALESE

Copyright (C) 1998-2015 Martin 'Kingpin' Thurn

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay::ByEndDate;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Date::Manip;
use base 'WWW::Search::Ebay';

our
$VERSION = do { my @r = (q$Revision: 2.33 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

my $EBAY_TZ = 'America/Los_Angeles';

# private
sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to _native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{'SortProperty'} = 'MetaEndSort';
  if (0)
    {
    # my @a = sort Date_Init();
    # print STDERR " III BEFORE: ", Dumper(\@a);
    Date_Init("ConvTZ=$EBAY_TZ");
    # @a = sort Date_Init();
    # print STDERR " III AFTER: ", Dumper(\@a);
    # We need to know the time in eBayLand right now:
    my $tz = $Date::Manip::Cnf{TZ}; # UnixDate('today', '%Z');
    } # if 0
  # Get the date-time right now, in the local timezone:
  my $dateToday = ParseDate('today');
  # Date_Init("SetDate=$EBAY_TZ");
  # Date::Manip::DM6 says it will "default to the local timezone":
  my $tz = undef;
  # print STDERR " DDD convert today ==$dateToday== to tz ==$EBAY_TZ==\n";
  $self->{_today_} = Date_ConvTZ($dateToday, $tz, $EBAY_TZ);
  # print STDERR " DDD   result today == ", $self->{_today_}, "\n";
  # exit;
  return $self->SUPER::_native_setup_search($native_query, $rhOptsArg);
  } # _native_setup_search

# Enforce sorting by end date, even if Ebay is returning it in a
# different order.  (They will be out of order if there are "Featured
# Items" at the top of the page.)  Calls _parse_tree() of the base
# class, and then reshuffles its 'cache' results.  Code contributed by
# Mike Schilli.

sub _parse_tree
  {
  my ($self, @args) = @_;
  my $hits = $self->SUPER::_parse_tree(@args);
  $self->{cache} ||= [];
  if (0)
    {
    # Convert all eBay relative times to absolute times:
    $self->{cache} = [
                      map {
                        my $iMin = _minutes($_->change_date) || _minutes(_date_to_rel($_->change_date,
                                                                                      $self->{_today_}));
                        $_->change_date(UnixDate(DateCalc($self->{_today_}, " + $iMin minutes"),
                                                 '%Y-%m-%dT%H:%M:%S'));
                        $_
                        }
                      grep { ref }
                      @{$self->{cache}}
                     ];
    } # if
  # Sort by date using a Schwartzian transform to save memory:
  $self->{cache} = [
                    map { $_->[0] }
                    sort { $a->[1] cmp $b->[1] }
                    map { [ $_, $_->change_date ] }
                    @{$self->{cache}}
                   ];
  return $hits;
  } # _parse_tree

use constant DEBUG_MINUTES => 0;

sub _minutes
  {
  my $s = shift;
  DEBUG_MINUTES && print STDERR " III _minutes($s)...\n";
  my $min = 0;
  $min += 60*24*$1 if $s =~ /(\d+)\s?[dT]/;
  $min += 60*$1 if $s =~ /(\d+)\s?[hS]/;
  $min += $1 if $s =~ /(\d+)\s?[mM]/;
  DEBUG_MINUTES && print STDERR "     min=$min=\n";
  return $min;
  } # _minutes

sub _date_to_rel
  {
  my $string = shift;
  my $today = shift;
  DEBUG_MINUTES && print STDERR " III _date_to_rel($string)...\n";
  my $date = ParseDate($string) || '';
  DEBUG_MINUTES && print STDERR "     raw date =$date=...\n";
  my $delta = DateCalc($today, $date) || 0;
  DEBUG_MINUTES && print STDERR "     delta =$delta=...\n";
  # Convert to minutes:
  my $iMin = int(&Delta_Format($delta, 0, '%mt'));
  my $result = "$iMin min";
  DEBUG_MINUTES && print STDERR "     result =$result=...\n";
  return $result;
  } # _date_to_rel

1;

__END__
