# AlltheWeb.pm
# by Jim Smyser
# Copyright (c) 2000 by Jim Smyser 
# $Id: AlltheWeb.pm,v 1.5 2000/07/17 07:10:59 jims Exp $

package WWW::Search::AlltheWeb;

=head1 NAME

WWW::Search::AlltheWeb - class for searching AlltheWeb

=head1 SYNOPSIS

use WWW::Search;
$query = "sprinkler system installation how to"; 
$search = new WWW::Search('AlltheWeb');
$search->native_query(WWW::Search::escape_query($query));
$search->maximum_to_retrieve(100);
while (my $result = $search->next_result()) {

$url = $result->url;
$title = $result->title;
$desc = $result->description;

print "<a href=$url>$title</a> $source<br>$date<br>$desc<p>\n"; 
} 

=head1 DESCRIPTION

AlltheWeb is a class specialization of WWW::Search.
It handles making and interpreting AlltheWeb searches.
This is one of the fastest and largest search engines around. 
F<http://www.alltheweb.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects. See SYNOPSIS.

=head1 AUTHOR

C<WWW::Search::AlltheWeb> is written by Jim Smyser
Author e-mail <jsmyser@bigfoot.com>

=head1 COPYRIGHT

Copyright (c) 1996-1999 University of Southern California.
All rights reserved.                                            

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
#'

#####################################################################
require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = '1.5';

$MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';
$TEST_CASES = <<"ENDTESTCASES";
&test('AlltheWeb', '$MAINTAINER', 'zero', \$bogus_query, \$TEST_EXACTLY);
&test('AlltheWeb', '$MAINTAINER', 'one', 'vbt'.'hread', \$TEST_RANGE, 2,50);
&test('AlltheWeb', '$MAINTAINER', 'two_page', '+LS'.'AM +IS'.'I', \$TEST_GREATER_THAN, 26);
ENDTESTCASES

use Carp ();
use WWW::Search(generic_option);
require WWW::SearchResult;

sub native_setup_search {
        my($self, $native_query, $native_options_ref) = @_;
        $self->{_debug} = $native_options_ref->{'search_debug'};
        $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
        $self->{_debug} = 0 if (!defined($self->{_debug}));
        $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
        $self->user_agent('user');
        $self->{_next_to_retrieve} = 1;
        $self->{'_num_hits'} = 0;
        $self->{'_hits_per_page'} = 100;
        
        if (!defined($self->{_options})) {
        $self->{'search_base_url'} = 'http://www.ussc.alltheweb.com';
        $self->{_options} = {
        'search_url' => 'http://www.ussc.alltheweb.com/cgi-bin/search',
              'query' => $native_query,
              'type' => 'all',
              'hits' => $self->{'_hits_per_page'},
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
        $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
              } 
 
sub native_retrieve_some {
        my ($self) = @_;
        print STDERR "**Getting Some**\n" if $self->{_debug};
        return undef if (!defined($self->{_next_url}));
        $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
        print STDERR "*Sending request (",$self->{_next_url},")\n" if $self->{_debug};
        my($response) = $self->http_request('GET', $self->{_next_url});
        $self->{response} = $response;
        if (!$response->is_success)
              {
       return undef;
              }
        $self->{'_next_url'} = undef;
        print STDERR "**Response\n" if $self->{_debug};
        
        # parse the output
        my ($HEADER, $HITS, $TITLE, $DESC) = qw(HE HI TI DE);
        my $hits_found = 0;
        my $state = $HEADER;
        my $hit = ();
        foreach ($self->split_lines($response->content()))
        {
        next if m@^$@; # short circuit for blank lines
        print STDERR " $state ===$_=== " if 2 <= $self->{'_debug'};
        
     if (m|(\d+)\sdocuments\sfound|i) 
        {
        print STDERR "**Found Count**\n" if ($self->{_debug});
        $self->approximate_result_count($1);
        $state = $HITS;
        } 
    elsif ($state eq $HITS && m@<dt>.*?<a href="([^"]+)">(.+)$@i) 
        {
        print "**Found Hit URL/Title**\n" if 2 <= $self->{_debug};
        if (defined($hit))
              {
        push(@{$self->{cache}}, $hit);
              }
        $hit = new WWW::SearchResult;
        $hits_found++;
        $hit->add_url($1);
        $hit->title($2);
        $state = $DESC;
        } 
    elsif ($state eq $DESC && m|<dd><span.*?>(.*)$|i) 
        {
        print STDERR "**Found Description**\n" if 2 <= $self->{_debug};
        $hit->description($1);
        $state = $HITS;
        } 
    elsif ($state eq $HITS && m|.*?<A HREF="([^"]+)"><span class="resultbar">&gt;&gt;</span></a>|i) 
        {
        print STDERR "**Going to Next Page**\n" if 2 <= $self->{_debug};
        my $URL = $1;
        $self->{'_next_url'} = $self->{'search_base_url'} . $URL;
        print STDERR "Next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
        $state = $HITS;
               } 
            else 
               {
       print STDERR "**Nothing matched.**\n" if 2 <= $self->{_debug};
               }
               } 
        if (defined($hit)) 
               {
           push(@{$self->{cache}}, $hit);
               }
        return $hits_found;
               } 
1;

