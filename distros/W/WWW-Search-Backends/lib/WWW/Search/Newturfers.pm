
# $Id: Newturfers.pm,v 1.5 2008/02/01 02:50:26 Daddy Exp $

=head1 NAME

WWW::Search::Newturfers - backend for searching www.watchnet.com forums

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Newturfers');
  my $sQuery = WWW::Search::escape_query("rolex gold");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Newturfers.com specialization of L<WWW::Search>.  It
handles making and interpreting searches on the Newturfers forums
F<http://www.newturfers.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

In the resulting WWW::SearchResult objects,
the 'source' element will contain the forum-registered name of the poster.

In the resulting WWW::SearchResult objects,
the 'change_date' element will contain the date and time of the post,
exactly as it appears on the search results page
(usually 'YYYY-MMDD hh:mm')

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

package WWW::Search::Newturfers;

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
  # print STDERR " +     This is Newturfers::native_setup_search()...\n";
  # print STDERR " +       _options is ", $self->{'_options'}, "\n";

  $self->user_agent('non-robot');
  # $self->agent_email('user@timezone.com');

  $self->{_next_to_retrieve} = 1;
  $self->{'search_base_url'} ||= 'http://www.newturfers.com';
  $self->{'search_base_path'} ||= "/bin/mwf/forum_search.pl";
  $self->{'_options'} = {
                         board => 'cid6',
                         mode => 'or',
                         user => '',
                         age => '',
                         words => $sQuery,
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
  print STDERR " + ::Newturfers got tree $oTree\n" if (2 <= $self->{_debug});
  my $hits_found = 0;
  my $oTD = $oTree->look_down(_tag => 'table',
                              class => 'tbl',
                             );

  my @aoA = $oTD->look_down(_tag => 'a',
                              sub { $_[0]->attr('href') =~ m!topic_show.pl! },
                              );
 A_TAG:
  foreach my $oA (@aoA)
    {
    # Sanity checks:
    next A_TAG unless ref($oA);
    my $oTD = $oA->parent;
    next A_TAG unless ref($oTD);
    my $oTR = $oTD->parent; 
    next A_TAG unless ($oTR->attr('class') eq 'crw');
    my $sTitle = $oA->as_text || '';
    my $sURL = $oA->attr('href') || '';
    $sURL = $self->{'search_base_url'} . '/bin/mwf/' . $sURL;
    next A_TAG unless ($sURL ne '');
    print STDERR " DDD URL is ==$sURL==\n" if (2 <= $self->{_debug});
    my $sDate = 'unknown';
    my $sPoster = 'unknown';
    $oTD = $oTD->right;
    my $oPoster = $oTD->look_down(_tag => 'a', 
                               sub { $_[0]->attr('href') =~ m!user_info.pl! },
                               );
    if (ref($oPoster)) 
    {
      $sPoster = $oPoster->as_text;
    }
    my $oDate = $oTD->right;
    if (ref($oDate))
    {
      $sDate = $oDate->as_text;
    }
    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->change_date($sDate);
    $hit->source($sPoster);
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    } # foreach A_TAG
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


