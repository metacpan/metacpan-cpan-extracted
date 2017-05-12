# AltaVista/Intranet.pm
# by Martin Thurn
# $Id: Intranet.pm,v 1.12 2008/01/21 02:04:11 Daddy Exp $
#
# Complete copyright notice follows below.

=head1 NAME

WWW::Search::AltaVista::Intranet - class for searching via AltaVista Search Intranet 2.3

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('AltaVista::Intranet', 
                                (_host => 'copper', _port => 9000),);
  my $sQuery = WWW::Search::escape_query("+investment +club");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class implements a search on AltaVista's Intranet ("AVI") Search.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 NOTES

If your query includes characters outside the 7-bit ascii,
you must tell AVI how to interpret 8-bit characters.
Add an option for 'enc' to the native_query() call:

  $oSearch->native_query(WWW::Search::escape_query('Zürich'),
                         { 'enc' => 'iso88591'},
                        );

Hopefully the correct values for various languages can be found in the
AVI documentation (sorry, I haven't looked).

=head1 TESTING

There is no standard built-in test mechanism for this module, because
very few users of WWW::Search will have AVI installed on their
intranet.  (How's that for an excuse? ;-)

=head1 AUTHOR

C<WWW::Search::AltaVista::Intranet>
was written by Martin Thurn <mthurn@cpan.org>

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

=head1 VERSION HISTORY

If it''s not listed here, then it wasn''t a meaningful nor released revision.

=head2 2.04, 2000-03-09

Added pod for selecting query language encoding

=head2 2.03, 2000-02-14

Added support for score/rank (thanks to Peter bon Burg <pvonburg@aspes.ch>)

=head2 2.02, 1999-11-29

Fixed to work with latest version of AltaVista.pm

=head2 1.03, 1999-06-20

First publicly-released version.

=cut

#####################################################################

package WWW::Search::AltaVista::Intranet;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';
use Carp;
our
$VERSION = '2.04';

our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';
our $TEST_CASES = <<"ENDTESTCASES";
&no_test('AltaVista::Intranet', '$MAINTAINER');
ENDTESTCASES

=head2 native_setup_search

This private method does the heavy lifting after native_query() is called.

=cut

sub native_setup_search
  {
  my ($self, $sQuery, $rhOptions) = @_;
  my $sMsg = '';
  unless (defined($self->{_host}) && ($self->{_host} ne ''))
    { $sMsg .= " --- _host not specified in WWW::Search::AltaVista::Intranet object\n"; }
  unless (defined($self->{_port}) && ($self->{_port} ne ''))
    { $sMsg .= " --- _port not specified in WWW::Search::AltaVista::Intranet object\n"; }
  if ($sMsg ne '')
    {
    carp $sMsg;
    return undef;
    } # if
  $self->{_options} = {
                       'search_url' => 'http://'. $self->{_host} .':'. $self->{_port} .'/cgi-bin/query',
                       'text' => 'yes',
                       'mss' => 'simple',
                      };
  # let AltaVista.pm finish up the hard work.
  return $self->SUPER::native_setup_search($sQuery, $rhOptions);
  } # native_setup_search


=head2 native_retrieve_some

This private method does the heavy lifting of communicating
with the server.

=cut

sub native_retrieve_some
  {
  my ($self) = @_;
  print STDERR " *   AltaVista::Intranet::native_retrieve_some()\n" if $self->{_debug};
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  # If this is not the first page of results, sleep so as to not overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
  # get some
  print STDERR " *   sending request (",$self->{_next_url},")\n" if $self->{_debug};
  my($response) = $self->http_request('GET', $self->{_next_url});
  $self->{response} = $response;
  if (!$response->is_success) 
    {
    return undef;
    }
  $self->{'_next_url'} = undef;
  print STDERR " *   got response\n" if $self->{_debug};
  # parse the output
  my ($HEADER, $HITS, $TITLE,$DESC,$DATE,$SIZE,$TRAILER) = qw(HE HI TI DE DA SI TR);
  my $hits_found = 0;
  my $state = ($HEADER);
  my $cite = "";
  my $hit = ();
  foreach ($self->split_lines($response->content()))
    {
    next if m@^$@; # short circuit for blank lines
    print STDERR " * $state ===$_=== " if 2 <= $self->{'_debug'};
    if ($state eq $HEADER && m/found\s+(\d+)\s+Web\s+pages\s+for\s+you/i)
      {
      # Actual line of input is:
      # <b><b><!-- avecho val="About " if="notexists $avs.header.isExact" -->AltaVista found 33 Web pages for you. </b></b>
      print STDERR "count line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      $state = $HITS;
      } # COUNT line
    if ($state eq $HEADER && m/DOCUMENTS\s+\d+-\d+\s+OF+\s(\d+)/i)
      {
      # Actual line of input is:
      # <b> Documents 1-1  of 1  matching the query,  best matches first.</b><dl>
      print STDERR "count line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      $state = $HITS;
      } # COUNT line
    elsif ($state eq $HITS && m:\<dl>\<dt>\<b>(\d+)\.:i)
      {
      # Actual line of input is:
      # <dl><dt><b>1.   </b>
      print STDERR "rank line\n" if 2 <= $self->{_debug};
      $state = $TITLE;
      }
    elsif ($state eq $TITLE && m:\<a\shref=\"([^"]+)\">:i)
      {
      # Actual line of input is:
      # <!-- PAV 1 --><a href="http://www.tasc.com/news/prism/9811/51198.html"><!-- PAV end --><b>Arlington Pond Waterski Club 11/98                                                  </b></a><dd>
      # <dt><a href="http://copper.dulles.tasc.com/SEVEN/TESTFILE1-header"><strong>TESTFILE1-header</strong></a><dd>dummy header line 1 dummy header line 2 dummy header line 3 dummy header line 4 DUCTAPE ENCODED 321 535 dummy header line 6 dummy header line 7 DEBUG THIS.<br><cite><a href="http://copper.dulles.tasc.com/SEVEN/TESTFILE1-header">http://copper.dulles.tasc.com/SEVEN/TESTFILE1-header</a><font size=-1> - size 1K</font></cite><br>
      print STDERR "title line\n" if 2 <= $self->{_debug};
      if (ref($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        }
      $hit = new WWW::SearchResult;
      $hit->add_url($1);
      $hits_found++;
      if (m:\<b>(.+?)\</b>:i)
        {
        my $sTitle = $1;
        $sTitle =~ s/\s+$//;
        $hit->title($sTitle);
        } # if
      if (m:\<strong>(.+?)\</strong>:i)
        {
        my $sTitle = $1;
        $sTitle =~ s/\s+$//;
        $hit->title($sTitle);
        } # if
      $state = $DESC;
      } # TITLE line
    elsif ($state eq $DESC)
      {
      # Actual line of input is:
      # The Analytic Investment Club. TASC employees in Northern Virginia formed The Analytic Investment Club (TAIC) in June 1995. The goals of the club are to...<br>
      print STDERR "description line\n" if 2 <= $self->{_debug};
      $hit->description($_);
      $state = $DATE;
      } # DESCRIPTION line
    elsif ($state eq $DATE && m:Last modified (.+)$:i)
      {
      # Actual lines of input are:
      # Last modified 15-Jan-1999
      # <br>Rank: 170 - Last modified 11-Feb-2000
      print STDERR "date line\n" if 2 <= $self->{_debug};
      $hit->change_date($1);
      $hit->score($1) if m!Rank:\s+(\d+)!;
      $state = $SIZE;
      } # DATE line
    elsif ($state eq $SIZE && m:page size (\S+):i)
      {
      # Actual line of input is:
      # - page size 5K
      print STDERR "size line\n" if 2 <= $self->{_debug};
      my $iSize = $1;
      $iSize *= 1024 if ($iSize =~ s@k$@@i);
      $iSize *= 1024*1024 if ($iSize =~ s@M$@@i);
      $hit->size($iSize);
      $state = $HITS;
      } # SIZE line
    elsif ($state eq $HITS && m:next\s*&gt;&gt;:i)
      {
      # Actual line of input is:
      # <a href="cgi-bin/query?mss=simple&what=web&pg=q&q=investment+club&text=yes&kl=XX&enc=iso88591&filter=intranet&stq=10">[<b>next &gt;&gt;</b>]</a>
      print STDERR "next link line\n" if 2 <= $self->{_debug};
      if (m:href=\"([^\"]+)\":i)
        {
        my $relative_url = $1;
        $self->{_next_url} = new URI::URL($relative_url, $self->{_base_url});
        } # if
      $state = $TRAILER;
      } # NEXT line
    else 
      {
      print STDERR "didn't match\n" if 2 <= $self->{_debug};
      }
    } # foreach

  if (defined($hit)) 
    {
    push(@{$self->{cache}}, $hit);
    } # if
  
  return $hits_found;
  } # native_retrieve_some

1;

__END__

Here is a complete URL:

http://copper.dulles.tasc.com:9000/cgi-bin/query?mss=simple&pg=q&what=web&user=searchintranet&text=yes&enc=iso88591&filter=intranet&kl=XX&q=forensics&act=Search

This is the barest-bones version that still works:

http://copper.dulles.tasc.com:9000/cgi-bin/query?mss=simple&text=yes&q=giraffe

This is what we are generating with WWW::Search 2.06:

http://copper:9000/cgi-bin/query?fmt=&mss=simple&pg=q&text=yes&what=web&q=giraffe

