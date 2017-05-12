
# $Id: WatchNet.pm,v 1.5 2008/02/01 02:50:27 Daddy Exp $

=head1 NAME

WWW::Search::WatchNet - backend for searching www.watchnet.com forums

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('WatchNet');
  my $sQuery = WWW::Search::escape_query("rolex gold");
  $oSearch->native_query($sQuery,
                         { forum => 'tradingpst' }
                        );
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a WatchNet.com specialization of L<WWW::Search>.  It
handles making and interpreting searches on the WatchNet forums
F<http://www.watchnet.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

By default, the search is applied to the "Trading Post" forum.
If you want to search a different forum,
add the option {forum=>'forumname'} when you call native_query().
The forum names are as follows:

  watchtalk
  tradingpst
  dealwatch
  goodguys
  watchparts
  auctionwatch

In the resulting WWW::SearchResult objects,
the 'source' element will contain the forum-registered name of the poster.

In the resulting WWW::SearchResult objects,
the 'change_date' element will contain the date and time of the post,
exactly as it appears on the search page
(usually 'MM/DD/YY hh:mm')

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the maintainer if you find any!

=head1 AUTHOR

Martin Thurn C<mthurn@cpan.org>
L<http://www.sandcrawler.com/SWB/cpan-modules.html>

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

See the Changes file

=cut

#####################################################################

package WWW::Search::WatchNet;

use strict;
use warnings;

use Carp ();
use Data::Dumper;  # for debugging only
use HTML::TreeBuilder;
use WWW::Search;
use WWW::SearchResult;
use URI;
use URI::Escape;

use vars qw( $VERSION $MAINTAINER @ISA );

@ISA = qw( WWW::Search );
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $sQuery, $rhOptsArg) = @_;
  # print STDERR " +     This is WatchNet::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  $self->http_method('GET');
  $self->user_agent('non-robot');
  # $self->agent_email('user@timezone.com');

  # http://forums.watchnet.com/index.php?t=search&srch=tissot&field=all&forum_limiter=&search_logic=AND&sort_order=DESC&btn_submit=Search

  $self->{_next_to_retrieve} = 1;
  my $sForum = lc($rhOptsArg->{forum}) || 'tradingpst';
  $self->{'search_base_url'} ||= 'http://forums.watchnet.com';
  $self->{'search_base_path'} ||= "/index.php";
  $self->{'_options'} = {
                         t => 'search',
                         srch => $sQuery,
                         field => 'all',
                         forum_limiter => '',
                         search_logic => 'OR',
                         sort_order => 'DESC',
                         btn_submit => 'Search',
                        };
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
  } # native_setup_search


sub hash_to_cgi_string
  {
  my $self = shift;
  my $rh = shift;
  my $sRet = '';
  foreach my $sKey (qw( t srch field forum_limiter search_logic sort_order btn_submit ))
    {
    $sRet .= "$sKey=$rh->{$sKey}&";
    } # foreach
  chop $sRet;
  return $sRet;
  } # hash_to_cgi_string


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
  return $sPage;
  } # preprocess_results_page

sub parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  print STDERR " + ::WatchNet got tree $oTree\n" if (2 <= $self->{_debug});
  my $hits_found = 0;
  my $oTD = $oTree->look_down(_tag => 'td',
                              VALIGN => 'TOP',
                              ALIGN => 'RIGHT',
                             );
  if (ref($oTD))
    {
    my $s = $oTD->as_text;
    print STDERR " DDD approx TD is ==$s==\n" if (2 <= $self->{_debug});
    if ($s =~ m!([0-9,]+) of [0-9,]+ Messages!)
      {
      my $s1 = $1;
      $s1 =~ s!,!!g;
      $self->approximate_hit_count(0 + $s1);
      } # if
    } # if
  my @aoTD = $oTree->look_down(_tag => 'td',
                               class => 'GenText',
                               width => '100%',
                              );
 TD_TAG:
  foreach my $oTD (@aoTD)
    {
    next TD_TAG unless ref($oTD);
    my $s = $oTD->as_HTML;
    print STDERR " DDD hit TD is ==$s==\n" if (2 <= $self->{_debug});
    my $oA = $oTD->look_down(_tag => 'a');
    next TD_TAG unless ref($oA);
    $s = $oA->as_HTML;
    print STDERR " DDD title A is ==$s==\n" if (2 <= $self->{_debug});
    my $sTitle = $oA->as_text || '';
    my $sURL = $oA->attr('href') || '';
    next TD_TAG unless ($sURL ne '');
    print STDERR " DDD URL is ==$sURL==\n" if (2 <= $self->{_debug});
    $oA->detach;
    $oA->delete;
    my $sDesc = $oTD->as_text;
    my $sDate = 'unknown';
    my $sPoster = 'unknown';
    my $sForum = 'unknown';
    my $oTR = $oTD->parent;
    if (ref $oTR)
      {
      my @aoA = $oTR->look_down(_tag => 'a');
      my $oA = shift @aoA;
      if (ref $oA)
        {
        $s = $oA->as_HTML;
        print STDERR " DDD forum A is ==$s==\n" if (2 <= $self->{_debug});
        $sForum = $oA->as_text;
        } # if
      $oA = shift @aoA;
      if (ref $oA)
        {
        $s = $oA->as_HTML;
        print STDERR " DDD   poster A is ==$s==\n" if (2 <= $self->{_debug});
        $sPoster = $oA->as_text;
        } # if
      my $oFONT = $oTR->look_down(_tag => 'font');
      if (ref $oFONT)
        {
        $s = $oFONT->as_HTML;
        print STDERR " DDD date FONT is ==$s==\n" if (2 <= $self->{_debug});
        $sDate = $oFONT->as_text;
        } # if
      } # if
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->change_date($sDate);
    $hit->source($sPoster);
    $hit->location($sForum);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach TD_TAG
  return $hits_found;
  } # parse_tree

sub strip
  {
  my $self = shift;
  my $s = &WWW::Search::strip_tags(shift);
  $s =~ s!\A\s+  !!x;
  $s =~ s!  \s+\Z!!x;
  return $s;
  } # strip

1;

__END__

http://forums.timezone.com/index.php?t=search&srch=tissot&field=all&forum_limiter=&search_logic=AND&sort_order=DESC

