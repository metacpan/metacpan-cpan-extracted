
# $Id: Advanced.pm,v 2.62 2009/05/02 16:42:37 Martin Exp $

=head1 NAME

WWW::Search::Yahoo::News::Advanced - search Yahoo!News using the
"advanced" interface

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo::News::Advanced');
  my $sQuery = WWW::Search::escape_query("George Lucas");
  $oSearch->date_from('7 days ago');
  $oSearch->date_to  ('now');
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo! News specialization of L<WWW::Search>.  It
handles making and interpreting searches on Yahoo! News
F<http://news.yahoo.com> using the Advanced search interface.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

This backend supports narrowing the search by date-range.
Use date_from() and date_to() to set the endpoints of the desired date range.
You can use any date format supported by the Date::Manip module.

NOTE that Yahoo only seems to keep the last 60 days worth of news in its searchable index.

At one time, News.yahoo.com would die if the unescaped query is longer
than 485 characters or so.  This backend does NOT check for that.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

To report a new bug, please use
https://rt.cpan.org/Ticket/Create.html?Queue=WWW-Search-Yahoo

=head1 AUTHOR

C<WWW::Search::Yahoo::News::Advanced> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Yahoo::News::Advanced;

use strict;
use warnings;

use Data::Dumper;  # for debugging only
use Date::Manip;
use WWW::Search qw( strip_tags );
use WWW::Search::Result;
use WWW::Search::Yahoo;

use base 'WWW::Search::Yahoo';
our
$VERSION = do { my @r = (q$Revision: 2.62 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub _native_setup_search
  {
  my ($self, $sQuery, $rh) = @_;
  # print STDERR " +   in Y::N::A::_native_setup_search, rh is ", Dumper($rh);
  my $sDateFrom = $self->date_from || '';
  my $sDateTo = $self->date_to || '';
  my $iUseDate = 0;
  my ($iMonthFrom, $iDayFrom, $iMonthTo, $iDayTo);
  if ($sDateFrom ne '')
    {
    # User specified the beginning date.
    my $dateFrom = &ParseDate($sDateFrom);
    $iMonthFrom = &UnixDate($dateFrom, '%m');
    $iDayFrom   = &UnixDate($dateFrom, '%d');
    $iUseDate = 1;
    }
  else
    {
    # User did not specify the beginning date.  Set it to the distant
    # past.  Yahoo.com barfs if it gets a date earlier than 1999,
    # though.
    $sDateFrom = &UnixDate(&ParseDate('1999-01-01'), '%m/%d/%y');
    }
  if ($sDateTo ne '')
    {
    # User specified the ending date.
    my $date = &ParseDate($sDateTo);
    $iMonthTo = &UnixDate($date, '%m');
    $iDayTo   = &UnixDate($date, '%d');
    $iUseDate = 1;
    }
  else
    {
    # User did not specify the ending date.  Set it to the future:
    $sDateTo = &UnixDate(&ParseDate('tomorrow'), '%m/%d/%y');
    }
  # With default search options:
  # http://news.search.yahoo.com/search/news?p=Aomori&c=&ei=UTF-8&fl=0&n=100&x=wrt

  $self->{'_options'} = {
                         'ei' => 'UTF-8',
                         'fl' => 0,
                         'n' => 100,  # 10 for testing, 100 for release
                         'p' => $sQuery,
                        };
  if ($iUseDate)
    {
    # This is the url when user chose date range:
    # http://news.search.yahoo.com/search/news?ei=UTF-8&fr=&va=Aomori&va_vt=any&vp=&vp_vt=any&vo=&vo_vt=any&ve=&ve_vt=any&&pub=1&smonth=3&sday=22&emonth=3&eday=30&source=&location=&fl=0&n=100
    $self->{'_options'}->{'pub'} = 1;
    delete $self->{'_options'}->{'fl'};
    delete $self->{'_options'}->{'p'};
    $self->{'_options'}->{'va'} = $sQuery;
    $self->{'_options'}->{'va_vt'} = 'any';
    $self->{'_options'}->{'smonth'} = $iMonthFrom;
    $self->{'_options'}->{'sday'} = $iDayFrom;
    $self->{'_options'}->{'emonth'} = $iMonthTo;
    $self->{'_options'}->{'eday'} = $iDayTo;
    } # if
  $rh->{'search_base_url'} = 'http://news.search.yahoo.com';
  $rh->{'search_base_path'} = '/search/news/';
  # print STDERR " +   Y::N::A::_native_setup_search() is calling SUPER::_native_setup_search()...\n";
  return $self->SUPER::_native_setup_search($sQuery, $rh);
  } # _native_setup_search


sub _parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $hits_found = 0;
  my @aoFONTcount = $tree->look_down('_tag', 'div',
                                     'id' => 'yschtools',
                                    );
 FONTcount_TAG:
  foreach my $oFONT (@aoFONTcount)
    {
    my $s = $oFONT->as_text;
    print STDERR " + FONTcount == ", $oFONT->as_HTML if 2 <= $self->{_debug};
    # print STDERR " +   TEXT == ", $s, "\n" if 2 <= $self->{_debug};
    if ($s =~ m!Results\s+\d+\s*-\s*\d+\s+of\s+(?:about\s+)?([0-9,]+)!)
      {
      my $iCount = $1;
      $iCount =~ s!,!!g;
      # print STDERR " +   found number $iCount\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($iCount);
      last FONTcount_TAG;
      } # if
    } # foreach FONT_TAG

  my @aoA = $tree->look_down('_tag' => 'a',
                             'class' => 'yschttl',
                            );
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR "\n + A == %s", $oA->as_HTML if 2 <= $self->{_debug};
    my $sMouseOver = $oA->attr('onmouseover');
    next A_TAG unless ($sMouseOver =~ m!window\.status='(.+)'!);
    my $sURL = $1;
    next A_TAG unless defined($sURL);
    next A_TAG unless ($sURL ne '');
    print STDERR " +   URL   == $sURL\n" if 2 <= $self->{_debug};
    my $sTitle = $oA->as_text;
    print STDERR " +   TITLE == $sTitle\n" if 2 <= $self->{_debug};
    # In order to make it easier to parse, make sure everything is an object!
    my $oLI = $oA->look_up(_tag => 'li');
    next A_TAG unless ref($oLI);
    $oA->detach;
    $oA->delete;
    my $oEM = $oLI->look_down('_tag' => 'em',
                             class => 'yschurl');
    next A_TAG unless ref($oEM);
    my $sEM = $oEM->as_text;
    my ($sSource, $sDate) = split(/[\s\240]-[\s\240]/, $sEM);
    my $oDIV = $oLI->look_down(_tag => 'div',
                               class => 'yschabstr');
    next A_TAG unless ref($oDIV);
    my $sDesc = &strip_tags($oDIV->as_text);
    print STDERR " +   raw DESC  == $sDesc\n" if 2 <= $self->{_debug};
    $sDesc =~ s!Save to My Web\Z!!;
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach oFONT

  # The "next" link is a plain old <A>:
  @aoA = $tree->look_down('_tag', 'a');
A_TAG:
  foreach my $oA (@aoA)
    {
    printf STDERR " + A == %s\n", $oA->as_HTML if 2 <= $self->{_debug};
    # <a href="http://search.news.yahoo.com/search/news?p=Japan&amp;b=21"><b>Next 20 &gt;</b></a>
    if ($oA->as_text eq 'Next')
      {
      $self->{_next_url} = $HTTP::URI_CLASS->new_abs($oA->attr('href'), $self->{'_prev_url'});
      last A_TAG;
      } # if
    } # foreach $oA
  $tree->delete;
  return $hits_found;
  } # _parse_tree


1;

__END__

As of 2007-04:
http://news.search.yahoo.com/search/news?ei=UTF-8&fr=&va=Aomori&va_vt=any&vp=&vp_vt=any&vo=&vo_vt=any&ve=&ve_vt=any&&pub=1&smonth=3&sday=22&emonth=3&eday=30&source=&location=&fl=0&n=100
