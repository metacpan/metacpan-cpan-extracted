
# $Id: Yahoo.pm,v 2.380 2009/05/02 13:28:41 Martin Exp $

=head1 NAME

WWW::Search::Yahoo - backend for searching www.yahoo.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Yahoo');
  my $sQuery = WWW::Search::escape_query("sushi restaurant Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Yahoo specialization of L<WWW::Search>.  It handles
making and interpreting Yahoo searches F<http://www.yahoo.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The default search is: Yahoo's web-based index (not Directory).

=head1 PRIVATE METHODS

If you just want to write Perl code to search Yahoo,
you do NOT need to read any further here.
Instead, just read the L<WWW::Search> documentation.

If you want to write a subclass of this module
(e.g. create a backend for another branch of Yahoo)
then please read about the private methods here:

=cut

package WWW::Search::Yahoo;

use strict;
use warnings;

use Carp ();
use Data::Dumper;  # for debugging only
use HTML::TreeBuilder;
use WWW::Search;
use WWW::SearchResult;
use URI;
use URI::Escape;

use vars qw( $iMustPause );

use base 'WWW::Search';
our
$VERSION = do { my @r = (q$Revision: 2.380 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# Thanks to the hard work of Gil Vidals and his team at
# positionresearch.com, we know the following: In early 2004,
# yahoo.com implemented new robot-blocking tactics that look for
# frequent requests from the same client IP.  One way around these
# blocks is to slow down and randomize the timing of our requests.  We
# therefore insert a random sleep before every request except the
# first one.  This variable is equivalent to a "first-time" flag for
# this purpose:
$iMustPause = 0;

=head2 gui_query

Yes, Virginia, we do try to emulate stupid-human queries.

=cut

sub gui_query
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'p' => $sQuery,
                         # 'hc' => 0,
                         # 'hs' => 0,
                         'ei' => 'UTF-8',
                        };
  # print STDERR " +   Yahoo::gui_query() is calling native_query()...\n";
  $rh->{'search_base_url'} = 'http://search.yahoo.com';
  $rh->{'search_base_path'} = '/bin/query';
  return $self->native_query($sQuery, $rh);
  } # gui_query

sub _native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  # print STDERR " +     This is Yahoo::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  $self->{'_hits_per_page'} = 100;
  # $self->{'_hits_per_page'} = 10;  # for debugging

  # www.yahoo.com refuses robots.
  $self->user_agent('non-robot');
  # www.yahoo.com completely changes the HTML output depending on the
  # browser!
  # $self->{'agent_name'} = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)';
  # $self->{agent_e_mail} = 'mthurn@cpan.org';

  $self->{_next_to_retrieve} = 1;

  $self->{'search_base_url'} ||= 'http://search.yahoo.com';
  $self->{'search_base_path'} ||= '/search';
  if (! defined($self->{'_options'}))
    {
    # We do not clobber the existing _options hash, if there is one;
    # e.g. if gui_search() was already called on this object
    $self->{'_options'} = {
                           'vo' => $native_query,
                           'h' => 'w',  # web sites
                           'n' => $self->{_hits_per_page},
                           # 'b' => $self->{_next_to_retrieve}-1,
                          };
    } # if
  my $rhOptions = $self->{'_options'};
  if (defined($rhOptsArg))
    {
    # Copy in new options, promoting special ones:
    foreach my $key (keys %$rhOptsArg)
      {
      # print STDERR " +   inspecting option $key...";
      if (WWW::Search::generic_option($key))
        {
        # print STDERR "promote & delete\n";
        $self->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        delete $rhOptsArg->{$key};
        }
      else
        {
        # print STDERR "copy\n";
        $rhOptions->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        }
      } # foreach
    # print STDERR " + resulting rhOptions is ", Dumper($rhOptions);
    # print STDERR " + resulting rhOptsArg is ", Dumper($rhOptsArg);
    } # if
  # Finally, figure out the url.
  $self->{'_next_url'} = $self->{'search_base_url'} . $self->{'search_base_path'} .'?'. $self->hash_to_cgi_string($rhOptions);

  $self->{_debug} = $self->{'search_debug'} || 0;
  $self->{_debug} = 2 if ($self->{'search_parse_debug'});
  } # _native_setup_search


=head2 need_to_delay

This method tells the L<WWW::Search> controller code whether we need to
pause and give the yahoo.com servers a breather.

=cut

sub need_to_delay
  {
  # print STDERR " + this is Yahoo::need_to_delay()\n";
  return $iMustPause;
  } # need_to_delay


=head2 user_agent_delay

This method tells the L<WWW::Search> controller code how many seconds we should pause.

=cut

sub user_agent_delay
  {
  my $self = shift;
  my $iSecs = int(30 + rand(30));
  print STDERR " + sleeping $iSecs seconds, to make yahoo.com think we're NOT a robot...\n" if (0 < $self->{_debug});
  sleep($iSecs);
  } # user_agent_delay


=head2 preprocess_results_page

Clean up the Yahoo HTML before we attempt to parse it.

=cut

sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  if ($self->{_debug} == 77)
    {
    # For debugging only.  Print the page contents and abort.
    print STDERR $sPage;
    exit 88;
    } # if
  # Delete the <BASE> tag that appears BEFORE the <html> tag (because
  # it causes HTML::TreeBuilder to NOT be able to parse it!)
  $sPage =~ s!<BASE\s[^>]+>!!;
  return $sPage;
  } # preprocess_results_page


=head2 _result_list_tags

Returns a list,
which will be passed as arguments to HTML::Element::look_down()
in order to return a list of HTML::Element which contain the query results.

=cut

sub _result_list_tags
  {
  return (_tag => 'div',
          class => 'res',
         );
  } # _result_list_tags


=head2 _result_list_items

Given an HTML::TreeBuilder tree,
returns a list of HTML::Element,
which contain the query results.

=cut

sub _result_list_items
  {
  my $self = shift;
  my $oTree = shift || die;
  my @ao = $oTree->look_down($self->_result_list_tags);
  return @ao;
  } # _result_list_items

my $WS = q{[\t\r\n\240\ ]};

sub _parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  print STDERR " + ::Yahoo got a tree $oTree\n" if (2 <= $self->{_debug});
  # Every time we get a page from yahoo.com, we have to pause before
  # fetching another.
  $iMustPause++;
  my $hits_found = 0;
  # Only try to parse the hit count if we haven't done so already:
  print STDERR " + start, approx_h_c is ==", $self->approximate_hit_count(), "==\n" if (2 <= $self->{_debug});
  if ($self->approximate_hit_count() < 1)
    {
    my $rh = $self->_where_to_find_count;
    my @aoDIV = $oTree->look_down(%$rh);
 DIV_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try DIV ==", $oDIV->as_HTML if (2 <= $self->{_debug});
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if (2 <= $self->{_debug});
      my $iCount = $self->_string_has_count($s);
      $iCount =~ tr!,\.!!d;
      if (0 <= $iCount)
        {
        $self->approximate_result_count($iCount);
        last DIV_TAG;
        } # if
      } # foreach DIV_TAG
    } # if
  print STDERR " + found approx_h_c is ==", $self->approximate_hit_count(), "==\n" if (2 <= $self->{_debug});

  my @aoLI = $self->_result_list_items($oTree);
  print STDERR " DDD aoLI has ", scalar(@aoLI), " items...\n" if (2 <= $self->{_debug});
 LI_TAG:
  foreach my $oLI (@aoLI)
    {
    # Sanity check:
    next LI_TAG unless ref($oLI);
    print STDERR " DDD found oLI is ==", $oLI->as_HTML, "==\n" if (2 <= $self->{_debug});
    my $oA = $oLI->look_down(_tag => 'a');
    next LI_TAG unless ref($oA);
    print STDERR " DDD   found oA is ==", $oA->as_HTML, "==\n" if (2 <= $self->{_debug});
    my $sTitle = $oA->as_text || '';
    my $sURL = $oA->attr('href') || '';
    next LI_TAG if ($sURL eq '');
    print STDERR " +   raw     URL is ==$sURL==\n" if (2 <= $self->{_debug});
    # Throw out various unwanted Yahoo links:
    next LI_TAG if ($sURL =~ m!\.yahoo\.com/(about|jobseeker|preferences|search)/!);
    next LI_TAG if ($sURL =~ m!//((answers|cgi|cn|de|docs|europe|help|local|myweb\d?|search|searchmarketing|video)\.)+yahoo\.com!);
    # Strip off the yahoo.com redirect part of the URL:
    $sURL =~ s!\A.*?\*-!!;
    $sURL =~ s!\Ahttp%3A!http:!i;
    print STDERR " +   cooked  URL is ==$sURL==\n" if (2 <= $self->{_debug});
    my $hit = new WWW::SearchResult;
    $hit->description(q{});
    $self->parse_details($oLI, $hit);
    $hit->add_url($sURL);
    $sTitle = $self->strip($sTitle);
    $hit->title($sTitle);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach LI_TAG
  # Now try to find the "next page" link:
  my @aoA = $oTree->look_down('_tag' => 'a');
 NEXT_A:
  foreach my $oA (reverse @aoA)
    {
    next NEXT_A unless ref($oA);
    my $sAhtml = $oA->as_HTML;
    printf STDERR (" +   next A ==%s==\n", $sAhtml) if (2 <= $self->{_debug});
    if ($self->_a_is_next_link($oA))
      {
      # Here is an example of a raw next URL:
      # http://rds.yahoo.com/_ylt=A0Je5ra.FlVEwsQA1RhXNyoA/SIG=13517q7d2/EXP=1146513470/**http%3a//search.yahoo.com/search%3fn=100%26vo=pokemon%26ei=UTF-8%26pstart=1%26b=101
      # http://rds.yahoo.com/;_ylt=AutpqXFv9tv2eTXen2Mw_c1XNyoA;_ylu=X3oDMTExN2UzODg3BGNvbG8DdwRzZWMDcGFnaW5hdGlvbgR2dGlkA0RGWDJfOQ--/SIG=19e131ad9/EXP=1130207429/**http%3A%2F%2Fsearch.yahoo.com%2Fsearch%3Fn%3D100%26vo%3Dpokemon%26ei%3DUTF-8%26xargs%3D12KPjg1hVSt4GmmvmnCOObHb%255F%252Dvj0Zlpi3g5UzTYR6a9RL8nQJDqADN%255F2aP%255FdLHL9y7XrQ0JOkvqV2HOs3qODiIxkSdWH8UbKsmJS5%255FIp9DLfdaXlzsbIu0%252Djv3NcQZy8nLl2qbeONz73ZI6L5Hk57%26pstart%3D6%26b%3D101
      my $sURL = $oA->attr('href');
      print STDERR " +   raw     next URL ==$sURL==\n" if (2 <= $self->{_debug});
      # Delete Yahoo-redirect portion of URL:
      $sURL =~ s!\A.+?[-*]+(?=http)!!;
      print STDERR " +   poached next URL ==$sURL==\n" if (2 <= $self->{_debug});
      $sURL = WWW::Search::unescape_query($sURL);
      $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
      print STDERR " +   cooked  next URL ==$self->{_next_url}==\n" if (2 <= $self->{_debug});
      last NEXT_A;
      } # if
    } # foreach NEXT_A
  return $hits_found;
  } # _parse_tree


=head2 parse_details

Given a (portion of an) HTML::TreeBuilder tree
and a L<WWW::SearchResult> object,
parses one result out of the tree and populates the SearchResult.

=cut

sub parse_details
  {
  my $self = shift;
  # Required arg1 = (part of) an HTML parse tree:
  my $oLI = shift;
  # Required arg2 = a WWW::SearchResult object to fill in:
  my $hit = shift;
  my $oDIV = $oLI->look_down(_tag => 'div',
                             class => 'abstr',
                            );
  if (ref($oDIV))
    {
    my $sDesc = $oDIV->as_text;
    $hit->description($self->strip($sDesc));
    } # if
  # Delete the useless human-readable restatement of the URL (first
  # <EM> tag we come across):
  my $oEM = $oLI->look_down(_tag => 'em');
  if (ref($oEM))
    {
    my $sSize = '';
    $sSize = $1 if ($oLI->as_text =~ m!(\d+[kb]?)!gx);
    $hit->size($sSize);
    } # if
  return;
  # Delete any remaining <A> tags:
  my @aoA = $oLI->look_down(_tag => 'a');
 A_TAG:
  foreach my $oA (@aoA)
    {
    $oA->detach;
    $oA->delete;
    } # foreach A_TAG
  $oDIV = $oLI->look_down(_tag => 'div');
  if (ref $oDIV)
    {
    $oDIV->detach;
    $oDIV->delete;
    } # if
  my $sDesc = $oLI->as_text;
  print STDERR " +   raw     sDesc is ==$sDesc==\n" if (2 <= $self->{_debug});
  # Grab stuff off the end of the description:
  print STDERR " +   cooked  sDesc is ==$sDesc==\n" if (2 <= $self->{_debug});
  $hit->description($self->strip($sDesc));
  } # parse_details


=head2 _where_to_find_count

Returns a list,
which will be passed as arguments to HTML::Element::look_down()
in order to return an HTML::Element
which contains the approximate result count.

=cut

sub _where_to_find_count
  {
  my %hash = (
              _tag => 'div',
              # 'class' => 'ygbody',
              id => 'info',
             );
  return \%hash;
  } # _where_to_find_count


=head2 _string_has_count

Given a string,
returns the approximate result count
if that string contains the approximate result count.

=cut

sub _string_has_count
  {
  my $self = shift;
  my $s = shift;
  # print STDERR " DDD Yahoo::string_has_count($s)?\n";
  return $1 if ($s =~ m!\bof\s+(?:about\s+)?([,0-9]+)!i);
  return -1;
  } # _string_has_count


=head2 _a_is_next_link

Given an HTML::Element,
returns true if it seems to contain the clickable "next page" widget.

=cut

sub _a_is_next_link
  {
  my $self = shift;
  my $oA = shift;
  return 0 if (! ref $oA);
  my $sID = $oA->attr('id') || '';
  return 1 if ($sID eq 'pg-next');
  my $s = $oA->as_text;
  print STDERR " +     next A as_text ==$s==\n" if (2 <= $self->{_debug});
  return ($s =~ m!\A$WS*Next$WS+&gt;$WS*\z!i);
  } # _a_is_next_link


=head2 strip

Given a string,
strips leading and trailing whitespace off of it.

=cut

sub strip
  {
  my $self = shift;
  my $s = &WWW::Search::strip_tags(shift);
  $s =~ s!\A$WS+  !!x;
  $s =~ s!  $WS+\Z!!x;
  return $s;
  } # strip

1;

__END__

GUI search:
http://ink.yahoo.com/bin/query?p=sushi+restaurant+Columbus+Ohio&hc=0&hs=0

Advanced search:
http://search.yahoo.com/search?h=w&fr=op&va=&vp=&vo=Martin+Thurn&ve=&bbase=Search&vl=&vc=&vd=all&vt=any&vss=i&vs=&vr=&vk=
http://ink.yahoo.com/bin/query?o=1&p=LSAm&d=y&za=or&h=c&g=0&n=20

actual next link from page:

http://google.yahoo.com/bin/query?p=%22Shelagh+Fraser%22&b=21&hc=0&hs=0&xargs=

_next_url :

http://google.yahoo.com/bin/query?%0Ap=%22Shelagh+Fraser%22&b=21&hc=0&hs=0&xargs=

http://rds.yahoo.com/_ylt=A0Je5ra.FlVEwsQA1RhXNyoA/SIG=13517q7d2/EXP=1146513470/**http%3a//search.yahoo.com/search%3fn=100%26vo=pokemon%26ei=UTF-8%26pstart=1%26b=101

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

As of 1998-02-02, C<WWW::Search::Yahoo> is maintained by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Yahoo> was originally written by Wm. L. Scheding,
based on C<WWW::Search::AltaVista>.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 LICENSE

Copyright (C) 1998-2009 Martin 'Kingpin' Thurn

This software is released under the same license as Perl itself.

=cut
