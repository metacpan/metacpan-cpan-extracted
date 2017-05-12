##########################################################
# NetFind.pm
# by Gil Vidals
# Copyright (C) 1999-2000 by Gil Vidals at PositionGeek.com
# $Id: NetFind.pm,v 1.802 2008/02/01 02:50:26 Daddy Exp $
##########################################################

=head1 NAME

WWW::Search::NetFind - class for searching NetFind
Originally based on Google.pm. NetFind is the same
as AOL search.

=head1 SYNOPSIS

use WWW::Search;
my $Search = new WWW::Search('NetFind'); # cAsE matters
my $Query = WWW::Search::escape_query("search engine consultant");
$Search->native_query($Query);
while (my $Result = $Search->next_result()) {
print $Result->url, "\n";
}

=head1 DESCRIPTION

This class is a NetFind (AOL) specialization of WWW::Search.
It handles making and interpreting NetFind searches.
F<http://search.aol.com>.

NetFinds returns 100 Hits per page. 

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 AOL SEARCH

Please note that searching at search.aol.com produces 
results from both the Open Source Directory and the licensed
Inktomi search engine. Results from Open Source Directory are
presented first followed by results from Inktomi.

If there are no results from the Open Source Directory, then
results are presented from Inktomi alone. Those results
that start with "MATCHING SITES" are from the Open Source
Directory and those that start with "MATCHING WEB PAGES" 
are from the Inktomi engine.

If you are interested in results only from Inktomi, 
then force the search to use the web.adp query like so:

 $search->native_query(WWW::Search::escape_query($query),{search_url=>'http://netfind.aol.com/web.adp'});

If you are interested in results only from the Open Source
Directory, refer to the OpenDirectory.pm module.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 HOW DOES IT WORK?

C<native_setup_search> is called (from C<WWW::Search::setup_search>)
before we do anything.  It initializes our private variables (which
all begin with underscore) and sets up a URL to the first results
page in C<{_next_url}>.

C<native_retrieve_some> is called (from C<WWW::Search::retrieve_some>)
whenever more hits are needed.  It calls C<WWW::Search::http_request>
to fetch the page specified by C<{_next_url}>.
It then parses this page, appending any search hits it finds to 
C<{cache}>.  If it finds a ``next'' button in the text,
it sets C<{_next_url}> to point to the page for the next
set of results, otherwise it sets it to undef to indicate we''re done.


=head1 TESTING

This module adheres to the C<WWW::Search> test suite mechanism. 

=head1 AUTHOR

This backend is maintained and supported by Gil Vidals.
<gil@positiongeek.com>

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 BUGS

Since this is a new Backend there are undoubtly one. Report any ASAP. 

=head1 VERSION HISTORY
1.8
Changed the root search from netfind.aol.com to search.aol.com
because netfind.aol.com seemed very unresponsive and the
searches timed out frequently. Also changed to the new format
using $self->hash_to_cgi_string($self->{_options});

1.5
Formatting change 10/08/99

0.7
First release  09/19/99

=cut

package WWW::Search::NetFind;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 1.802 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $MAINTAINER = 'Gil Vidals <gil@positiongeek.com>';
my $TEST_CASES = <<"ENDTESTCASES";
&test('NetFind', '$MAINTAINER', 'zero_gv', 'dlslkdkjd ' . \$bogus_query, \$TEST_EXACTLY);
&test('NetFind', '$MAINTAINER', 'one_gv', 'Zuckus', \$TEST_RANGE, 2, 49);
&test('NetFind', '$MAINTAINER', 'multi_gv', 'salsa tacos', \$TEST_GREATER_THAN, 12);
ENDTESTCASES

use Carp ();
use WWW::Search(generic_option);
require WWW::SearchResult;

sub native_setup_search {

     my ($self, $native_query, $native_options_ref) = @_;
     $self->{_debug} = $native_options_ref->{'search_debug'};
     $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
     $self->{_debug} = 0 if (!defined($self->{_debug}));
     my $DEFAULT_HITS_PER_PAGE = 100;
     ## $DEFAULT_HITS_PER_PAGE = 10 if 0 < $self->{_debug};
     $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
     $self->{agent_e_mail} = 'gil@positiongeek.com';
     $self->user_agent('user');
     $self->{_next_to_retrieve} = 1;
     $self->{'_num_hits'} = 0;
     if (!defined($self->{_options})) {
       $self->{'search_base_url'} = 'http://search.aol.com/';
       $self->{_options} = {
         'search_url' => 'http://search.aol.com/dirsearch.adp',
         'query' => $native_query,
       };
     }
     my $options_ref = $self->{_options};
     if (defined($native_options_ref)) 
     {
     # Copy in new options.
       foreach (keys %$native_options_ref) 
     {
     $options_ref->{$_} = $native_options_ref->{$_};
     } # foreach
     } # if
     # Process the options.
     my($options) = '';
     foreach (sort keys %$options_ref) 
     {
     # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
     next if (generic_option($_));
     $options .= $_ . '=' . $options_ref->{$_} . '&';
     }
     chop $options;
     # Finally figure out the url.
     # old way ---> $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
     $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
     } # native_setup_search

# private
#--------------------------------------------------------------------------------
sub native_retrieve_some {
#--------------------------------------------------------------------------------
my ($self) = @_;
print STDERR "**NetFind::native_retrieve_some()**\n" if $self->{_debug};
return undef if (!defined($self->{_next_url}));

# sleep so as to not overload the server:
$self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};

print STDERR "**Sending request (",$self->{_next_url},")\n" if $self->{_debug};    
my($response) = $self->http_request('GET', $self->{_next_url});      
$self->{response} = $response;        

if (!$response->is_success)         {
       return undef;
}
$self->{'_next_url'} = undef;
print STDERR "**Parse the Results**\n" if $self->{_debug};

# parse the output
my ($START, $SCORE, $NEXT, $HITS, $TITLE, $DESC, $TRAILER) = (1..10);
my $hits_found = 0;
my $state = $START;
my $hit = ();
my $next_query = '';

foreach ($self->split_lines($response->content())) {
  next if m@^$@; # short circuit for blank lines
  print STDERR " $state ===$_=== " if 2 <= $self->{'_debug'};

  if ($state eq $START and m/MATCHING SITE|MATCHING WEB/) {
    print "*** FOUND MATCHING ***\n" if 2 <= $self->{_debug};
    $state = $SCORE;
  }
 
  if ($state eq $SCORE and m@\(<B>\d+</B> thru <B>(\d+)</B> of <B>(\d+)</B>\)@) {
       print "*** FOUND SCORE ***\n" if 2 <= $self->{_debug};
       $self->approximate_result_count($2) unless $self->approximate_result_count;
       $state = $NEXT;
  } 
  ## MATCHING WEB PAGES (web.adp) the FIRST "next" is like this:
  ## <A HREF="web.adp?query=salsa%20tacos&next=web&first=11&last=25">next</A> <B>&gt;&gt;</B>

  ## <A HREF="web.adp?query=%28salsa%20AND%20verde%29&next=web&first=26&last=40">next</A> <B>&gt;&gt;</B>

  ## MATCHING WEB PAGES (more than one page) "ferfer it"
  ## <TD WIDTH=200><FONT COLOR=#990000 STYLE="font-family: Arial, helv, helvetica;  font-weight:bold; font-size:14px">MATCHING WEB PAGES</FONT></TD><TD WIDTH=50>&nbsp;</TD><TD WIDTH=130 ALIGN=CENTER>(<B>1</B> thru <B>15</B> of <B>19</B>)</TD><TD WIDTH=50 ALIGN=CENTER><A HREF="web.adp?query=ferfer%20it&first=16&last=30"><FONT STYLE="font-family: Arial, helv, helvetica;  font-weight:bold; font-size:12px">next</FONT></A> <B>&gt;&gt;</B></TD></TR></TABLE>

  ## MATCHING SITES (dirsearch.adp) the FIRST "next" is like this:
  ## <TD WIDTH=60 ALIGN=CENTER></TD><TD WIDTH=60 ALIGN=CENTER> <B><A HREF="dirsearch.adp?query=salsa%20tacos&first=11&last=25&next=item"><FONT STYLE="font-family: Arial, helv, helvetica; font-weight:bold; font-size:12px">next</FONT></A> &gt;&gt;</B> </TD></TR></TABLE>

  ## MATCHING SITES (dirsearch.adp) the SECOND "next" is like this:
  ## <TD WIDTH=60 ALIGN=CENTER> <B>&lt;&lt;</B> <A HREF="dirsearch.adp?query=kansas%20state%20laws&first=110&last=124&next=item"><FONT STYLE="font-family: Arial, helv, helvetica; font-weight:bold; font-size:12px">back</FONT></A> </TD><TD WIDTH=60 ALIGN=CENTER> <B><A HREF="dirsearch.adp?query=kansas%20state%20laws&first=151&last=165&next=item"><FONT STYLE="font-family: Arial, helv, helvetica; font-weight:bold; font-size:12px">next</FONT></A> &gt;&gt;</B> </TD></TR></TABLE>
 
  if ($state eq $NEXT and m@(^.+?<B>|CENTER>|^)<A HREF="(.+?)">.*?next.*?</A>.+?$@) {
  ## if ($state eq $NEXT and m@^.+?<B><A HREF="(.+?)">.*?next.*?</A>.+?$@) {
       print "*** FOUND NEXT *** $_\n *** " if 2 <= $self->{_debug};
       $next_query = $2;
       $next_query =~ m/first=(\d+)&last=(\d+)/;
       print "\$next_query: ", $next_query, "\n" if 2 <= $self->{_debug};
       $state = $NEXT;  
       # print "\n\n\n"; 
  } elsif ($state eq $NEXT and m@following results are from the World Wide Web@) {
       print "***HITS WILL START HERE***\n" if 2 <= $self->{_debug};
       $state = $HITS;
  }

  ## MATCHING SITES via dirsearch.adp
  if ($state eq $HITS and m@(\d+%).+?<A HREF="(.+?)">.+?</A>.*?<BR>(.*?)(<I>|$)@i) {
    print "*** MATCHING SITE HIT ***\n" if 2 <= $self->{_debug};
    if (defined($hit)) {
      push(@{$self->{cache}}, $hit);
    };
    $hit = new WWW::SearchResult;
    $hits_found++;
    $hit->score($1);
    $hit->add_url($2); ###  if defined($hit);
    $hit->title($3); 
    $hit->description($4);
    $state = $HITS;

  ## MATCHING WEB VIA dirsearch.adp
  } elsif ($state eq $HITS and m@(\d+%).+?<A HREF="(.+?)".+?<B>(.+?)</B>.*?$@i) {
     print "*** MATCHING WEB HIT ***\n" if 2 <= $self->{_debug};
    if (defined($hit)) {
      push(@{$self->{cache}}, $hit);
    };
    $hit = new WWW::SearchResult;
    $hits_found++;
    $hit->score($1);
    $hit->add_url($2); ###  if defined($hit);
    $hit->title($3); ###  if defined($hit);
    $state = $DESC;
  } elsif ($state eq $DESC and m@^<I>http://.+?</I>.*?@i) {
    print "*** MISSING DESC ***\n" if 2 <= $self->{_debug};
    $state = $HITS;
  } elsif ($state eq $DESC and m@^(.+?)<BR>$@i) {
    print "*** DESC ***\n" if 2 <= $self->{_debug};
    $hit->description($1);
    $state = $HITS;

  ## MATCHING WEB via web.adp
  } elsif ($state eq $TITLE and m@^\s*(.+?)</A></B>$@i) {
    print "*** TITLE ***\n" if 2 <= $self->{_debug};
    $hit->title($1);
    $state = $DESC; 
  } elsif ($state eq $DESC and m@^<FONT.+?>(.*?)</FONT>.*?$@i) {
    print "*** DESC  ***\n" if 2 <= $self->{_debug};
    $hit->description($1);
    $state = $HITS; 
  } elsif ($state eq $DESC and m@^<FONT.+?italic">htt.*?$@i) {
    print "*** NO DESC!!!  ***\n" if 2 <= $self->{_debug};
    $hit->description('');
    $state = $HITS; 
  ## END OF web.adp
  ## <FONT STYLE="font-weight:bold">&lt;&lt;</FONT> <FONT STYLE="font-family: Arial, helv, helvetica; font-weight:bold; font-size:12px"><A HREF="dirsearch.adp?query=kansas%20state%20laws&first=-4&last=10">back</A></FONT>  &nbsp;(11 - 25)&nbsp;  <FONT STYLE="font-family: Arial, helv, helvetica; font-weight:bold; font-size:12px"><A HREF="dirsearch.adp?query=kansas%20state%20laws&first=26&last=40&next=item">next</A></FONT> <FONT STYLE="font-weight:bold">&gt;&gt;</FONT> <P>

  } elsif ($state eq $HITS and (m@<FORM ACTION=.+?.adp>@i or m@^.+?</FONT>\s+&nbsp;\(\d+ - \d+\)&nbsp;\s+<FONT.+?$@i)) {
     print STDERR "**Going to Next Page**\n" if 2 <= $self->{_debug};
     if ($next_query =~ /\S/o) {
       $self->{'_next_to_retrieve'}++; ## can't see much use in this field other than pg counter; 
       $self->{'_next_url'} = $self->{'search_base_url'} . $next_query;
     } else {
       $self->{'_next_url'} = undef;
     }
     print STDERR "**Next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
     $next_query = '';
     last; ## $state = $TRAILER;
  } else {
     print STDERR "**Nothing Matched**\n" if 2 <= $self->{_debug};
  }
} # end of for loop 

if (defined($hit)) {
   push(@{$self->{cache}}, $hit);
} 
print "**Hits found** ", $hits_found, "\n" if 2 <= $self->{_debug};
return $hits_found;
} # native_retrieve_some

1;

__END__

