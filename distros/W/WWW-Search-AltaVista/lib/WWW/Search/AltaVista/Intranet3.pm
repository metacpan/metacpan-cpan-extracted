# AltaVista/Intranet3.pm
# $Id: Intranet3.pm,v 1.5 2008/01/21 02:04:11 Daddy Exp $
#
# Complete copyright notice follows below.

=head1 NAME

WWW::Search::AltaVista::Intranet3 - class for searching via AltaVista Search Intranet 3.0

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('AltaVista::Intranet3', 
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

Added support for score/rank (thanks to Peter von Burg <pvonburg@aspes.ch>)

=head2 2.02, 1999-11-29

Fixed to work with latest version of AltaVista.pm

=head2 1.03, 1999-06-20

First publicly-released version.

=cut

#####################################################################

package WWW::Search::AltaVista::Intranet3;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';
use Carp;
our
$VERSION = '2.04';

our $TEST_CASES = <<"ENDTESTCASES";
&no_test('AltaVista::Intranet3', '$MAINTAINER');
ENDTESTCASES

$self->{_debug} = 1;   # PvB

# private
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

  $self->{_options} = { # PvB
		'search_url' => 'http://' . $self->{_host} . ':' . $self->{_port} . '/cgi-bin/query',
                'mss' => 'search', # AV Intranet 3.0
#		 'mss' => 'simple', # AV Intranet 2.3
		'kl' => '',
		'i' => '',
                'text' => 'yes',
		};
  #  $self->{_debug} = 1; # PvB

  if ($self->{_debug})
    { # PvB
    print " Query: ", $sQuery, "\n";
    print " Options: ";
    while (($k, $v) =each %$rhOptions) {print "$k => $v  "};
    print "\n";
  }

  # let AltaVista.pm finish up the hard work.

  return $self->SUPER::native_setup_search($sQuery, $rhOptions);

}  # native_setup_search


# private
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
  print STDERR " *   got response, start parsing\n" if $self->{_debug};
 # parse the output
  my ($HEADER, $HITS, $TITLE,$DESC,$DATE,$SIZE,$TRAILER) = qw(HE HI TI DE DA SI TR);
  my $hits_found = 0;
  my $state = ($HEADER);
  my $cite = "";
  my $hit = ();
  foreach ($self->split_lines($response->content()))
    {
    next if m@^$@; # short circuit for blank lines
    print STDERR " * $state ===$_=== \n" if 2 <= $self->{'_debug'};
    if ($state eq $HEADER && m/<b>AltaVista found\s+(\d+)/i) # PvB
      {
      print "No of Pages Line --$_--\n" if 2 <= $self->{_debug}; # 1st parsing check: No of Pages
      # Actual line of input is:
      # 
      print STDERR "found web pages count line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      print "No of pages found: $1\n\n" if $self->{_debug}; # PvB
      $state = $HITS;
      } # COUNT line
    if ($state eq $HITS && m/Word count:/) # PvB
      {
      print "No of words Line --$_--\n" if 2 <= $self->{_debug}; # 2nd parsing check: No of Words
      # Actual line of input is:
      # 
      print STDERR "count line\n" if 2 <= $self->{_debug};
      $self->approximate_result_count($1);
      $state = $HITS;
      } # COUNT line
    elsif ($state eq $HITS && m/Begin results list/i) # PvB
      {
      $state = $TITLE; # PvB
      }
    elsif ($state eq $TITLE && m:\<a\shref=\"([^"]+)\">:i) # PvB   *** begin found pages ***
      {
      print "title line:  --$_--\n" if 2 <= $self->{_debug};				# 4nd parsing check: title
      # Actual line of input is:
      # 
      # 
      print STDERR "title line\n" if 2 <= $self->{_debug};
      if (ref($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        }
      $hit = new WWW::SearchResult;
      $hit->add_url($1);
      print "Hit found: $1\n" if $self->{_debug};
      $hits_found++;
      if (m:\<b>(.+?)\</b>:i)
        {
        my $sTitle = $1;
        $sTitle =~ s/\s+$//;
        $sTitle =~ s:</a>.*::;
        $sTitle =~ s:.*<a.*">::;
	print "Title of page found: ", $sTitle, "\n" if $self->{_debug};
        $hit->title($sTitle);
        } # if
      if (m:\<strong>(.+?)\</strong>:i)
        {
        my $sTitle = $1;
        $sTitle =~ s/\s+$//;
	print "Title of page found: ", $sTitle, "\n" if $self->{_debug};
        $hit->title($sTitle);
        } # if
      $state = $DESC;
      } # TITLE line
    elsif ($state eq $DESC)
      {
      # Actual line of input is:
      # 
      $_ =~ s/<dd>//i;
      $_ =~ s/<br>//i;
      print STDERR "description line\n" if 2 <= $self->{_debug};
      print STDERR "description: --$_-- \n" if 2 <= $self->{_debug};
      $hit->description($_);
      $state = $DATE;
      print "Description of page found: ", $_, "\n" if $self->{_debug};
      } # DESCRIPTION line
    elsif ($state eq $DATE && m:Last modified (.+)$:i)
      {
      # Actual lines of input are:
      # 
      # 
      print STDERR "relevance/date/size line\n" if 2 <= $self->{_debug};
      $line = $_;
      $_ =~ s/.*modified on //i;
      $_ =~ s/ &middot.*//i;
      print STDERR "last modified date: $_ \n" if $self->{_debug};
      $hit->change_date($_);
      $_ = $line;
      $_ =~ s/Relevance //i;
      $_ =~ s/ &middot.*//i;
      print STDERR "relevance: $_ \n" if $self->{_debug};
      $hit->score($_);
      $_ = $line;
      $_ =~ s/.* &middot; Last//i;
      $_ =~ s/.*? &middot; //i;
      $_ =~ s/&nbsp;bytes.*//i;
      my $iSize = $_;
      $iSize *= 1024 if ($iSize =~ s@k$@@i);
      $iSize *= 1024*1024 if ($iSize =~ s@M$@@i);
      print STDERR "size: $iSize \n\n" if $self->{_debug};
      $hit->size($iSize);
      $state = $TITLE;
      } # REL/DATE/SIZE line
    elsif ($state eq $TRAILER && m:next\s*&gt;&gt;:i)
      {
      # Actual line of input is:
      # 
      print STDERR "next link line\n" if 2 <= $self->{_debug};
      $_ =~ s/\[<a href="//i;
      $_ =~ s/"><b>next.*//i;
      $_ = 'http://' . $self->{_host} .':'. $self->{_port} . $_ ;
      $self->{_next_url} = $_;
      print STDERR "next link url is: $_ \n" if $self->{_debug};
      $state = $TRAILER;
      } # next AV result page
    elsif ($_ eq "<!-- End results list. -->")
      {
      print " *   end of parsing reached\n" if $self->{_debug};
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
  
  print " *   hits found: \n" if $self->{_debug};
  return $hits_found;
  } # native_retrieve_some

1;

__END__

