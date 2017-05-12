
# $Id: Timezone.pm,v 1.5 2008/02/01 02:50:27 Daddy Exp $

=head1 NAME

WWW::Search::Timezone - backend for searching www.timezone.com forums

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Timezone');
  my $sQuery = WWW::Search::escape_query("rolex gold");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Timezone.com specialization of L<WWW::Search>.  It
handles making and interpreting searches on the TimeZone forums
F<http://forums.timezone.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

In the resulting WWW::SearchResult objects,
the 'description' element will contain the first N words of the post
(as it appears on the search results page).

In the resulting WWW::SearchResult objects,
the 'location' element will contain the name of the forum in which the post appears.

In the resulting WWW::SearchResult objects,
the 'source' element will contain the forum-registered name of the poster.

In the resulting WWW::SearchResult objects,
the 'change_date' element will contain the date and time of the post,
exactly as it appears on the search page
(usually 'Mmm dd, YYYY - hh:mm PM')

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

package WWW::Search::Timezone;

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

sub gui_query_not_implemented
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                        };
  # print STDERR " +   Timezone::gui_query() is calling native_query()...\n";
  return $self->native_query($sQuery, $rh);
  } # gui_query


sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  # print STDERR " +     This is Timezone::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  $self->{'_hits_per_page'} = 250;

  # www.timezone.com refuses robots.
  $self->user_agent('non-robot');
  # $self->agent_email('user@timezone.com');

  $self->{_next_to_retrieve} = 1;

  $self->{'search_base_url'} ||= 'http://forums.timezone.com';
  $self->{'search_base_path'} ||= '/index.php';
  if (! defined($self->{'_options'}))
    {
    # http://forums.timezone.com/index.php?t=search&srch=tissot&field=all&forum_limiter=&search_logic=AND&sort_order=DESC

    # We do not clobber the existing _options hash, if there is one;
    # e.g. if gui_search() was already called on this object
    $self->{'_options'} = {
                           t => 'search',
                           srch => $native_query,
                           field => 'all',
                           search_logic => 'AND',
                           sort_order => 'DESC',
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
  } # native_setup_search


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
  print STDERR " + ::Timezone got tree $oTree\n" if (2 <= $self->{_debug});
  my $hits_found = 0;
  # This search engine does not tell us how many hits there are!
  my @aoA = $oTree->look_down(
                               _tag => 'a',
                               class => 'GenLink',
                              );
 A_TAG:
  foreach my $oA (@aoA)
    {
    # Sanity checks:
    next A_TAG unless ref($oA);
    my $oTD = $oA->parent;
    next A_TAG unless ref($oTD);
    next A_TAG unless ($oTD->tag eq 'td');
    my $sTitle = $oA->as_text || '';
    my $sURL = $oA->attr('href') || '';
    next A_TAG unless ($sURL ne '');
    print STDERR " DDD URL is ==$sURL==\n" if (2 <= $self->{_debug});
    $oA->detach;
    $oA->delete;
    # Delete (but remember) the hit counter:
    my $sTDtext = $oTD->as_text;
    next A_TAG unless ($sTDtext =~ s!\A(\d+)\.\s*!!);
    my $iHit = 0 + $1;
    my $sDate = 'unknown';
    my $sForum = 'unknown';
    my $sPoster = 'unknown';
    my $oTDforum = $oTD->right;
    if (ref($oTDforum))
      {
      $sForum = $oTDforum->as_text;
      print STDERR " DDD   forum is ==$sForum==\n" if (2 <= $self->{_debug});
      my $oTDdate = $oTDforum->right;
      if (ref($oTDdate))
        {
        my $oFONT = $oTDdate->look_down(_tag => 'font');
        if (ref($oFONT))
          {
          $sDate = $oFONT->as_text;
          print STDERR " DDD   date is ==$sDate==\n" if (2 <= $self->{_debug});
          } # if
        my $oA = $oTDdate->look_down(_tag => 'a');
        if (ref($oA))
          {
          $sPoster = $oA->as_text;
          print STDERR " DDD   poster is ==$sPoster==\n" if (2 <= $self->{_debug});
          } # if
        # Prevent extraneous <A> tags from matching our search:
        $oTDdate->detach;
        $oTDdate->delete;
        } # if
      # Prevent extraneous <A> tags from matching our search:
      $oTDforum->detach;
      $oTDforum->delete;
      } # if
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sTDtext);
    $hit->change_date($sDate);
    $hit->location($sForum);
    $hit->source($sPoster);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach A_TAG
  # Now try to find the "next page" link:
  my @aoAnext = $oTree->look_down('_tag' => 'a',
                                  class => 'PagerLink',
                                  sub { $_[0]->as_text eq '>' },
                                 );
 NEXT_A:
  foreach my $oA (@aoAnext)
    {
    next NEXT_A unless ref($oA);
    my $sURL = $oA->attr('href');
    print STDERR " +   raw     next URL ==$sURL==\n" if (2 <= $self->{_debug});
    $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $sURL);
    print STDERR " +   cooked  next URL ==$self->{_next_url}==\n" if (2 <= $self->{_debug});
    last NEXT_A;
    } # foreach NEXT_A
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

