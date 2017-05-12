# $Id: Search.pm,v 1.15 2008/07/27 16:34:27 Martin Exp $

=head1 NAME

WWW::Search::Search - class for searching www.search.com

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Search');
  my $sQuery = WWW::Search::escape_query("+sushi restaurant +Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a search.com specialization of L<WWW::Search>.  It handles
making and interpreting searches at F<http://www.search.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 PRIVATE METHODS

In order to use this module,
you do NOT need to know about these methods;
they are just part of the underlying WWW::Search mechanism.

=over

=cut

package WWW::Search::Search;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = (q$Revision: 1.15 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
my $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

use Carp;
use URI::Escape;
use WWW::Search;
# We need the version with the add_sources() method:
use WWW::SearchResult 2.078;

=item gui_query

In WWW::Search::Search, the default query is the same as the GUI query.

=cut

sub gui_query
  {
  my $self = shift;
  return $self->native_query(@_);
  } # gui_query

=item native_setup_search

=cut

sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # $self->{agent_e_mail} = 'mthurn@cpan.org';
  $self->user_agent('non-robot');

  $self->{_next_to_retrieve} = 1;
  $self->{'_num_hits'} = 0;
  # search.com returns 10 hits per page no matter what.
  $self->{'_hits_per_page'} = 10;
  if (!defined($self->{_options}))
    {
    $self->{'search_base_url'} = 'http://www.search.com';
    $self->{_options} = {
                         'search_url' => $self->{'search_base_url'} .'/search',
                         'q' => $native_query,
                        };
    } # if
  my $options_ref = $self->{_options};
  # Copy in options which were passed in our second argument:
  if (defined($native_options_ref))
    {
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if
  # Copy in options which were set by a child object:
  if (defined($self->{'_child_options'}))
    {
    foreach (keys %{$self->{'_child_options'}})
      {
      $self->{'_options'}->{$_} = $self->{'_child_options'}->{$_};
      } # foreach
    } # if
  # Finally, figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search


sub _preprocess_results_page_OFF
  {
  my $self = shift;
  my $sPage = shift;
  print STDERR '='x 10, $sPage, '='x 10, "\n";
  return $sPage;
  } # preprocess_results_page


sub _parse_tree
  {
  my $self = shift;
  my $oTree = shift;
  my $hits_found = 0;
  if (! $self->approximate_result_count)
    {
    my $oTITLE = $oTree->look_down('_tag' => 'div',
                                   class => 'statusbar',
                                   id => 'done',
                                  );
    if (ref $oTITLE)
      {
      my $sRC = $oTITLE->as_text;
      print STDERR " +   RC == $sRC\n" if 2 <= $self->{_debug};
      if ($sRC =~ m!RESULTS\s+\d+\s*-\s*\d+\s+OF\s+(?:ABOUT\s+)?([0-9,]+)!i)
        {
        my $sCount = $1;
        print STDERR " +     raw    count == $sCount\n" if 2 <= $self->{_debug};
        $sCount =~ s!,!!g;
        print STDERR " +     cooked count == $sCount\n" if 2 <= $self->{_debug};
        $self->approximate_result_count($sCount);
        } # if number pattern matches
      } # if found DIV
    } # if don't have approx count yet
  my $sScore = '';
  my $sSize = '';
  my $sDate = '';
  my $oDIV = $oTree->look_down('_tag' => 'div',
                               'id' => 'organic',
                              );
  goto SKIP_RESULTS_LIST unless ref $oDIV;
  my $oUL = $oDIV->look_down('_tag' => 'ul',
                            );
  goto SKIP_RESULTS_LIST unless ref $oUL;
  # print STDERR " +   oUL is ===". $oUL->as_HTML ."===\n" if 2 <= $self->{_debug};
  # The items in this list are the web search results:
  my @aoLI = $oUL->look_down(_tag => 'li');
 LI_TAG:
  foreach my $oLI (@aoLI)
    {
    next LI_TAG unless ref $oLI;
    print STDERR " +   oLI is ===". $oLI->as_HTML ."===\n" if 2 <= $self->{_debug};
    my $oPtitle = $oLI->look_down(_tag => 'p',
                                  class => 'title');
    next LI_TAG unless ref $oPtitle;
    my $oAtitle = $oPtitle->look_down(_tag => 'a');
    next LI_TAG unless ref $oAtitle;
    my $hit = new WWW::SearchResult;
    my $sTitle = $oAtitle->as_text;
    $hit->title($sTitle);
    my $sURL = $oAtitle->attr('href');
    if ($sURL =~ m!,(http.+)\Z!)
      {
      $sURL = uri_unescape($1);
      } # if
    $hit->add_url($sURL);
    my $oSPANurl = $oLI->look_down(_tag => 'p',
                                   class => 'url');
    if (ref $oSPANurl)
      {
      # Parse out the source sites:
      my $sSrc = $oSPANurl->as_text;
      if ($sSrc =~ m/\[\s*Result\s+from\s+(.+?)\s*\]/)
        {
        my $sSrcs = $1;
        my @asSrc = split /,\s*/, $sSrcs;
        $hit->add_sources(@asSrc);
        } # if
      } # if
    my $oPdesc = $oLI->look_down(_tag => 'p',
                                 class => 'desc');
    if (ref $oPdesc)
      {
      my $sDesc = $oLI->as_text;
      print STDERR " +   found desc ===$sDesc===\n" if 2 <= $self->{_debug};
      $hit->description(_strip($sDesc));
      } # if
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach LI_TAG
SKIP_RESULTS_LIST:
  # Find the next link, if any:
  my $oLInext = $oTree->look_down('_tag' => 'li',
                                  class => 'next');
  if (ref $oLInext)
    {
    my $oAnext = $oLInext->look_down(_tag => 'a');
    print STDERR " +   oAnext is ===", $oAnext->as_HTML, "===\n" if 2 <= $self->{_debug};
    $self->{_next_url} = $self->absurl($self->{'_prev_url'},
                                       $oAnext->attr('href'));
    } # if
 SKIP_NEXT_LINK:
  return $hits_found;
  } # _parse_tree


sub _strip
  {
  my $sRaw = shift;
  my $s = &WWW::Search::strip_tags($sRaw);
  # Strip leading whitespace:
  $s =~ s!\A[\240\t\r\n\ ]+  !!x;
  # Strip trailing whitespace:
  $s =~ s!  [\240\t\r\n\ ]+\Z!!x;
  return $s;
  } # _strip

1;

__END__

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Search> was originally written by Martin Thurn,
based loosely on the code for C<WWW::Search::Lycos>.

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut

