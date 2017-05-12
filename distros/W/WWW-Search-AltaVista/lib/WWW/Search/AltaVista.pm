# AltaVista.pm
# by John Heidemann
# Copyright (C) 1996-1998 by USC/ISI
# $Id: AltaVista.pm,v 2.905 2008/01/21 02:04:11 Daddy Exp $
#
# Complete copyright notice follows below.

=head1 NAME

WWW::Search::AltaVista - class for searching www.altavista.com


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('AltaVista');


=head1 DESCRIPTION

This class is an AltaVista specialization of WWW::Search.
It handles making and interpreting AltaVista searches
F<http://www.altavista.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

The default is "any of these words" (OR of query terms).

=over 8

=item aqa=all+of+these+words

Add the AND of these words to the query.

=item aqp=this+exact+phrase

Add "this exact phrase" to the query.

=item aqo=any+of+these+words

Add the OR of these words to the query.
This is where the query is placed by default.

=item aqn=none+of+these+words

Add NOT these words to the query.

=item aqb=(boolean+AND+expression)+NEAR+entry

Add a boolean expression to the query.
Operators are AND, OR, AND NOT, and NEAR.
In the browser interface, the boolean expression can not be combined with any other query types listed above.
You should probably build the boolean expression with parentheses and spaces and urlescape it.

=item aqs=these+words

Pages containing "these words" will be ranked highest.

=item kgs=[0,1]

To restrict the search to U.S. websites, set kgs=1.
The default is world-wide, kgs=0.

=item kls=[0,1]

To restrict the search to pages in English and Spanish, set kls=1.
The default is no language restrictions, kls=0.

=item filetype=[html,pdf]

To restrict the search to HTML pages only, set filetype=html.
To restrict the search to PDF pages only, set filetype=pdf.
The default is no restriction on page type, filetype=.

=item rc=dmn&swd=net+org+or.jp

To restrict the search to pages from certain domains,
set rc=dmn and set swd to a list of desired toplevel domains.

=item rc=url&lh=www.sandcrawler.com/SWB

To restrict the search to pages from a particular site,
set rc=url and set lh to the site name and path.
Leave off the http:// from the site.

=back

=head1 PUBLIC METHODS

=cut

#####################################################################

package WWW::Search::AltaVista;

use strict;
use warnings;

use Carp ();
use Date::Manip;
use WWW::Search qw( generic_option strip_tags unescape_query );
use WWW::Search::Result;

use base 'WWW::Search';

our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';
our
$VERSION = do { my @r = (q$Revision: 2.905 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _undef_to_emptystring
  {
  return defined($_[0]) ? $_[0] : "";
  } # _undef_to_emptystring

=head2 gui_query

Call this instead of native_query() if you want to get the same results as your average Joe web surfer.

=cut

sub gui_query
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'search_host' => 'http://www.altavista.com',
                         'search_path' => '/web/results',
                         'q' => $sQuery,
                         'kls' => 0,
                         avkw => 'qtrp',
                        };
  return $self->native_query($sQuery, $rh);
  } # gui_query

=head1 PRIVATE METHODS

=head2 native_setup_search

This private method does the heavy lifting after you call native_query()
or gui_query().

=cut

sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  $self->user_agent('user');
  $self->{_next_to_retrieve} = 0;
  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'pg' => 'aq',
                         'avkw' => 'qtrp',
                         'aqmode' => 's',
                         'aqo' => $native_query,
                         'kgs' => 0,
                         'kls' => 0,
                         # 'dt' => 'dtrange',
                         'rc' => 'dmn',
                         'nbq' => '50',
                         'search_host' => 'http://www.altavista.com',
                         'search_path' => '/web/results',
                        };
    if ((my $s = $self->date_from) ne '')
      {
      $s = &UnixDate($s, '%m/%d/%y');
      $self->{_options}->{d0} = $s;
      $self->{_options}->{dt} = 'dtrange';
      } # if
    if ((my $s = $self->date_to) ne '')
      {
      $s = &UnixDate($s, '%m/%d/%y');
      $self->{_options}->{d1} = $s;
      $self->{_options}->{dt} = 'dtrange';
      } # if
    } # if
  my($options_ref) = $self->{_options};
  if (defined($native_options_ref))
    {
    # Copy in new options.
    foreach (keys %$native_options_ref)
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if
  # Process the options.
  my $options = '';
  # For Intranet search to work, mss option must be first:
  if (exists $options_ref->{'mss'})
    {
    $options .= 'mss=' . $options_ref->{'mss'} . '&';
    } # if
  foreach my $key (keys %$options_ref)
    {
    # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    next if (generic_option($key));
    next if $key eq 'mss';
    $options .= $key . '=' . $options_ref->{$key} . '&';
    } # foreach
  chop $options;
  $self->{_debug} = $options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # Finally figure out the url.
  $self->{_base_url} =
  $self->{_next_url} =
  $self->{_options}{'search_host'} . $self->{_options}{'search_path'} .'?'. $options;
  # print STDERR $self->{_base_url} . "\n" if ($self->{_debug});
  } # native_setup_search

sub _count_pattern
  {
  # Pattern for matching result-count in many languages.
  # Language-specific subclasses might need to override this.
  return qr{\b(?:found|fand)
            \s+
            ([0-9.,]+)
            \s+
            # This covers English and German:
            (?:result|headline|Ergebnisse)
            }x;
  } # _count_pattern


sub _preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # return $sPage;
  # For debugging only.  Print the page contents and abort.
  print STDERR '='x 25, "\n\n", $sPage, "\n\n", '='x 25;
  exit 88;
  } # _preprocess_results_page

=head2 parse_tree

This private method does the hard work of parsing the results out of the HTML.

=cut

sub parse_tree
  {
  my $self = shift;
  my $tree = shift;
  my $iHits = 0;
  my $iCountSpoof = 0;
  my $WS = q{[\t\r\n\240\ ]};
  # Only try to parse the hit count if we haven't done so already:
  print STDERR " + start, approx_h_c is ==", $self->approximate_hit_count(), "==\n" if 2 <= $self->{_debug};
  if ($self->approximate_hit_count() < 1)
    {
    # Sometimes the hit count is inside a <DIV> tag:
    my @aoDIV = $tree->look_down('_tag' => 'div',
                                  'class' => 'xs',
                                 );
    # Sometimes the hit count is inside a <SPAN> tag:
    push @aoDIV, $tree->look_down('_tag' => 'span',
                                  'class' => 'y',
                                 );
    my $qrCount = $self->_count_pattern;
 DIV_TAG:
    foreach my $oDIV (@aoDIV)
      {
      next unless ref $oDIV;
      print STDERR " + try DIV ==", $oDIV->as_HTML if 2 <= $self->{_debug};
      my $s = $oDIV->as_text;
      print STDERR " +   TEXT ==$s==\n" if 2 <= $self->{_debug};
      if ($s =~ m!$qrCount!i)
        {
        my $iCount = $1 || '';
        $iCount =~ tr!.,!!d;
        $self->approximate_result_count($iCount);
        print STDERR " + found approx_h_c is ==", $self->approximate_hit_count(), "==\n" if (2 <= $self->{_debug});
        last DIV_TAG;
        } # if
      } # foreach DIV_TAG
    } # if
  # Get the hits:
  my @aoA = $tree->look_down(
                             '_tag' => 'a',
                             'class' => 'res',
                            );
 A_TAG:
  foreach my $oA (@aoA)
    {
    # <a class="res" href="/r?ck_sm=4bf6b336&amp;ci=4939&amp;av_tc=null&amp;q=%7Cvirus+%7Cprotease&amp;rpos=1&amp;rpge=1&amp;rsrc=U&amp;ref=200020080&amp;uid=1da8cd3e47b05cd0&amp;r=http%3A%2F%2Fwww.mcafee.com%2F" onmouseout="status=''; return true;" onmouseover="status='http://www.mcafee.com/'; return true;">McAfee Security - Computer Virus Software and Internet Security For Your PC</a>
    next unless ref $oA;
    my $sA = $oA->as_HTML;
    print STDERR " +   found A==$sA==\n" if (2 <= $self->{_debug});
    my $sURL = $self->absurl($self->{'_prev_url'}, $oA->attr('href'));
    print STDERR " +     the URL   is ==$sURL==\n" if (2 <= $self->{_debug});
    # Ignore advertising links:
    next if ($sURL =~ m!//rc10\.overture\.com!);
    my $sTitle = $oA->as_text;
    print STDERR " +     the title is ==$sTitle==\n" if (2 <= $self->{_debug});
    my $oSPAN = $oA;
 FIND_SPAN:
    while (1)
      {
      last FIND_SPAN if ! ref $oSPAN;
      last FIND_SPAN if ($oSPAN->tag eq 'span');
      $oSPAN = $oSPAN->right;
      } # while
    if (ref $oSPAN)
      {
      # $oSPAN now is <span class=s> which contains the description
      # and the URL:
      print STDERR " +     found SPAN==", $oSPAN->as_HTML, "==\n" if (2 <= $self->{_debug});
      my $oHit = new WWW::Search::Result;
      $oHit->add_url($sURL);
      $oHit->title($sTitle);
      $oHit->description(&WWW::Search::strip_tags($oSPAN->as_text));
      push(@{$self->{cache}}, $oHit);
      $self->{'_num_hits'}++;
      $iHits++;
      } # if
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


=head1 BUGS

=over

=item Not all of the above options have been tested.

=item Please report bugs and send feature requests via email to
C<bug-WWW-Search-AltaVista@rt.cpan.org>, or via the web interface at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Search-AltaVista>.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized AltaVista searches described in options.

=head1 AUTHOR

Written by John Heidemann, C<johnh@isi.edu>;
maintained by Martin Thurn, C<mthurn@cpan.org>.

=head1 LICENSE

This software is released under the same license as Perl itself.

=head1 COPYRIGHT

Copyright (c) 1996-1998 University of Southern California.
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

1;

__END__

advanced search results:

full URL, as of 2005-12 = http://www.altavista.com/web/results?itag=ody&pg=aq&aqmode=s&aqa=all&aqp=this+phrase&aqo=any&aqn=none&aqb=&kgs=1&kls=0&d2=0&dt=dtrange&dfr%5Bd%5D=1&dfr%5Bm%5D=1&dfr%5By%5D=1980&dto%5Bd%5D=14&dto%5Bm%5D=12&dto%5By%5D=1995&filetype=&rc=dmn&swd=&lh=&nbq=10

http://www.altavista.com/web/results?pg=aq&avkw=qtrp&aqmode=s&aqa=&aqp=&aqo=martin+thurn&aqn=&aqb=&aqs=&kgs=0&kls=0&dt=tmperiod&d2=0&d0=&d1=&filetype=&rc=dmn&swd=&lh=&nbq=50

gui query results:
http://www.altavista.com/web/results?q=Rhonda+Thurn&kgs=0&kls=0&avkw=qtrp
