# News.pm
# by John Heidemann
# Copyright (C) 1996 by USC/ISI
# $Id: News.pm,v 2.108 2008/01/21 02:04:11 Daddy Exp $
#
# Complete copyright notice follows below.

=head1 NAME

WWW::Search::AltaVista::News - class for Alta Vista news searching


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('AltaVista::News');

=head1 DESCRIPTION

This class implements the AltaVista news search
(specializing AltaVista and WWW::Search).
It handles making and interpreting AltaVista news searches
F<http://www.altavista.com>.

Details of AltaVista can be found at L<WWW::Search::AltaVista>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 METHODS

=cut

#####################################################################

package WWW::Search::AltaVista::News;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';

our
$VERSION = do { my @r = (q$Revision: 2.108 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

=head2 native_setup_search (private)

This method does the heavy-lifting after native_query() is called.

=cut

sub native_setup_search
  {
  my $self = shift;
  my $sQuery = shift;
  if (!defined($self->{_options}))
    {
    # http://www.altavista.com/news/results?q=Ashburn&nc=0&nr=0&nd=2
    $self->{_options} = {
                         'nbq' => '50',
                         'q' => $sQuery,
                         'search_host' => 'http://www.altavista.com',
                         'search_path' => '/news/results',
                        };
    } # if
  # Let AltaVista.pm finish up the hard work:
  return $self->SUPER::native_setup_search($sQuery, @_);
  } # native_setup_search

sub _preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # return $sPage;
  # For debugging only.  Print the page contents and abort.
  print STDERR '='x 25, "\n\n", $sPage, "\n\n", '='x 25;
  exit 88;
  } # preprocess_results_page

=head2 parse_tree

This method parses the HTML of the search results.

=cut

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $iHits = 0;
  my $WS = q{[\t\r\n\240\ ]};
  # Only try to parse the hit count if we haven't done so already:
  print STDERR " + start, approx_h_c is ==", $self->approximate_hit_count(), "==\n" if 2 <= $self->{_debug};
  if ($self->approximate_hit_count() < 1)
    {
    my $qrCount = $self->_count_pattern;
    # The hit count is inside a <B> tag:
    my @aoB = $tree->look_down('_tag' => 'b',
                               'class' => 'lbl',
                              );
 B_TAG:
    foreach my $oB (@aoB)
      {
      next unless ref $oB;
      print STDERR " + try B ==", $oB->as_HTML if 2 <= $self->{_debug};
      my $s = $oB->as_text;
      print STDERR " +   TEXT ==$s==\n" if 2 <= $self->{_debug};
      if ($s =~ m!$qrCount!i)
        {
        my $iCount = $1;
        $iCount =~ s!,!!g;
        $self->approximate_result_count($iCount);
        last B_TAG;
        } # if
      } # foreach B_TAG
    } # if
  print STDERR " + found approx_h_c is ==", $self->approximate_hit_count(), "==\n" if 2 <= $self->{_debug};
  # Get the hits:
  my @aoA = $tree->look_down('_tag' => 'a',
                             'class' => 'res',
                            );
 A_TAG:
  foreach my $oA (@aoA)
    {
    next A_TAG unless ref $oA;
    my $sURL = $oA->attr('href') || '';
    next A_TAG unless ($sURL ne '');
    my $sTitle = $oA->as_text;
    print STDERR " + oA ==", $oA->as_HTML, "==\n" if (2 <= $self->{_debug});
    print STDERR " + sTitle ==$sTitle==\n" if (2 <= $self->{_debug});
    my $oTD = $oA->parent;
    next A_TAG unless ref $oTD;

    my $oSPANdate = $oTD->look_down('_tag' => 'span', 'class' => 'ngrn');
    next A_TAG unless ref $oSPANdate;
    my $sDate = $oSPANdate->as_text;

    my $oSPANsrc = $oTD->look_down('_tag' => 'span', 'style' => 'color:#4a4a4a');
    next A_TAG unless ref $oSPANsrc;
    my $sSource = $oSPANsrc->as_text;

    my $oSPANdesc = $oTD->look_down('_tag' => 'span', 'class' => 's');
    next A_TAG unless ref $oSPANdesc;
    my $sDescription = $oSPANdesc->as_text;

    my $oHit = new WWW::Search::Result;
    $oHit->add_url($self->absurl($self->{'_prev_url'}, $sURL));
    $oHit->title(&WWW::Search::strip_tags($sTitle));
    $oHit->source(&WWW::Search::strip_tags($sSource));
    $oHit->description(&WWW::Search::strip_tags($sDescription));
    $oHit->change_date(&WWW::Search::strip_tags($sDate));
    push(@{$self->{cache}}, $oHit);
    $self->{'_num_hits'}++;
    $iHits++;
    # Make it easier to find the "Next" tag:
    $oA->detach;
    $oA->delete;
    } # foreach A_TAG
  # Find the 'next page' link:
  @aoA = $tree->look_down('_tag' => 'a',
                         );
 NEXT_TAG:
  foreach my $oA (@aoA)
    {
    next NEXT_TAG unless ref $oA;
    # Multilingual version:
    next NEXT_TAG unless $oA->as_text =~ m!\s>>\Z!;
    # English-only version:
    # next NEXT_TAG unless $oA->as_text eq q{Next >>};
    $self->{_next_url} = $self->absurl($self->{'_prev_url'}, $oA->attr('href'));
    last NEXT_TAG;
    } # foreach
  return $iHits;
  } # parse_tree

1;

=head1 AUTHOR

C<WWW::Search> is written by John Heidemann, <johnh@isi.edu>.


=head1 COPYRIGHT

Copyright (c) 1996 University of Southern California.
All rights reserved.

Redistribution and use in source and binary forms are permitted
provided that the above copyright notice and this paragraph are
duplicated in all such forms and that any documentation, advertising
materials, and other materials related to such distribution and use
acknowledge that the software was developed by the University of
Southern California, Information Sciences Institute.  The name of the
University may not be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

__END__

