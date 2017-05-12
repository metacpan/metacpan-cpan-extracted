# MetaCrawler.pm
# by Jim Smyser
# $Id: MetaCrawler.pm,v 2.72 2008/02/01 02:50:26 Daddy Exp $

=head1 NAME

WWW::Search::MetaCrawler - class for searching http://mc3.go2net.com! 


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('MetaCrawler');

=head1 DESCRIPTION

Class specialization of WWW::Search for searching F<http://mc3.go2net.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,
or the specialized AltaVista searches described in options.

=head1 HOW DOES IT WORK?

C<native_setup_search> is called before we do anything.
It initializes our private variables (which all begin with underscores)
and sets up a URL to the first results page in C<{_next_url}>.

C<native_retrieve_some> is called (from C<WWW::Search::retrieve_some>)
whenever more hits are needed.  It calls the LWP library
to fetch the page specified by C<{_next_url}>.
It parses this page, appending any search hits it finds to 
C<{cache}>.  If it finds a ``next'' button in the text,
it sets C<{_next_url}> to point to the page for the next
set of results, otherwise it sets it to undef to indicate we're done.

=head1 AUTHOR

C<WWW::Search::MetaCrawler> is written and maintained
by Jim Smyser - <jsmyser@bigfoot.com>.

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
#'

#####################################################################

package WWW::Search::MetaCrawler;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 2.72 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my $MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
my $TEST_CASES = <<"ENDTESTCASES";
&test('MetaCrawler', '$MAINTAINER', 'zero', \$bogus_query, \$TEST_EXACTLY);
&test('MetaCrawler', '$MAINTAINER', 'one', 'ohme'.'ohmy', \$TEST_RANGE, 2,20);
&test('MetaCrawler', '$MAINTAINER', 'two', 'Bos'.'sk', \$TEST_GREATER_THAN, 101);
ENDTESTCASES

use Carp ();
use WWW::Search qw(generic_option strip_tags);
require WWW::SearchResult;

sub native_setup_search {

       my($self, $native_query, $native_options_ref) = @_;
       $self->{_debug} = $native_options_ref->{'search_debug'};
       $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
       $self->{_debug} = 0 if (!defined($self->{_debug}));
       $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
       $self->user_agent('user');
       $self->{'_num_hits'} = 30;
       $self->{'_next_to_retrieve'} = 1;
               if (!defined($self->{_options})) {
             $self->{_options} = {
             'search_url' => 'http://mc3.go2net.com/crawler',
             'method'=> '0',
             'region' => '0',
             'rpp' => $self->{'_num_hits'},
             'timeout' => '10',
             'hpe' => '30',
             'sort'=> '0',
             'eng' => 'AltaVista&eng=Excite&eng=Infoseek&eng=Lycos&eng=WebCrawler&eng=Yahoo&eng=Thunderstone&eng=LookSmart&eng=About&eng=GoTo&eng=DirectHit',
             'refer' => 'mc-power',
             'general' =>  $native_query,
             };
             }

       my $options_ref = $self->{_options};
       if (defined($native_options_ref))
         {
       foreach (keys %$native_options_ref)
         {
       $options_ref->{$_} = $native_options_ref->{$_};
         } 
         } 
       my($options) = '';
       foreach (sort keys %$options_ref)
         {
       next if (generic_option($_));
       $options .= $_ . '=' . $options_ref->{$_} . '&';
         }
       chop $options;
       $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
         } 

# private
sub native_retrieve_some {

       my ($self) = @_;
       print STDERR "**MetaCrawler::native_retrieve_some()\n" if $self->{_debug};
       # Fast exit if already done:
       return undef if (!defined($self->{_next_url}));
           
       # If this is not the first page of results, sleep so as to not
       # overload the server:
       $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
           
       # Get some:
       print STDERR "**Requesting (",$self->{_next_url},")\n" if $self->{_debug};
       my($response) = $self->http_request('GET', $self->{_next_url});
       $self->{response} = $response;
       if (!$response->is_success)
         {
       return undef;
         }
       $self->{'_next_url'} = undef;
       print STDERR "**Found Some\n" if $self->{_debug};

       my ($HEADER, $HITS, $NEXT, $DESC) = qw(HE HI NX DE);
       my $state = $HEADER;
       my $hit = ();
       my $hits_found = 0;
       foreach ($self->split_lines($response->content()))
         {
       next if m@^$@; # short circuit for blank lines
       print STDERR " * $state ===$_=== " if 2 <= $self->{'_debug'};
       if (m|(\d+) results</font>|i) 
         {
       $self->approximate_result_count($1);
       $state = $HITS;
         } 
       elsif ($state eq $HITS && m@<dt>.*?<a href="([^"]+)">(.*)</a>@i) 
         {
       print STDERR "**Found a URL\n" if 2 <= $self->{_debug};
       my ($url,$title) = ($1,$2);
       if (defined($hit))
         {
       push(@{$self->{cache}}, $hit);
         }
       $hit = new WWW::SearchResult;
       $hit->add_url($url);
       $hits_found++;
       $hit->title(strip_tags($title));
       $state = $NEXT;
         } 
       elsif ($state eq $NEXT && m@^<br>@i) 
         {
       $state = $DESC;
         } 
       elsif ($state eq $DESC && m@(<i>.*?</i>:.*)<br>@i || m@<dd>(.*)<br>@i) 
         {
       print STDERR "**Found description\n" if 2 <= $self->{_debug};
       $hit->description(strip_tags($1));
       $state = $HITS;
         } 
       elsif ($state eq $HITS && m|HREF="([^"]+)"><b>next</b></a>|i) 
         {
       print STDERR "**Found 'next' Tag\n" if 2 <= $self->{_debug};
       my $sURL = $1;
       $self->{'_next_url'} = $sURL;
       print STDERR " **Next URL is: ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
       $state = $HITS;
         }
         else
         {
       print STDERR "**Nothing Matched\n" if 2 <= $self->{_debug};
         }
         } 
         if (defined($hit)) 
         {
       push(@{$self->{cache}}, $hit);
         }
       return $hits_found;
         }

1;

__END__
