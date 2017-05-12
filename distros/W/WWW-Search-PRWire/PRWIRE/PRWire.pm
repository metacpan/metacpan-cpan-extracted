# PRWire.pm
# by Jim Smyser
# Copyright (C) 2000 by Jim Smyser 
# $Id: PRWire.pm,v 1.00 2000/04/07 02:33:19 jims Exp $


package WWW::Search::PRWire;

=head1 NAME

WWW::Search::PRWire - class for viewing latest Press Releases 

=head1 SYNOPSIS

  use WWW::Search;
 my $search = new WWW::Search('PRWire');
 $search->native_query(WWW::Search::escape_query('NULL'));
  while (my $result = $search->next_result())
    { 
    print $result->url, "\n"; 
    }

=head1 DESCRIPTION

Class for WWW::Search for fetching and parsing latest PRWire news 
headlines. F<http://www.prnewswire.com>. This code should
serve as an example of using WWW::Search to parse useful data
from pages other than its usual searching methods. Yes, WWW::Search
is useful for retrieving data when there is "next" pages to get and
yet, no search interface to interact with. 
See USAGE.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 USAGE

PRWire.pm does not deal with options $native_query (Query) or any
others except $maximum_to_retrieve. In a sense, this is not a
"search" backend. It simply parses all the latest headlines and
retrieves more as defined by $maximum_to_retrieve.

If you use with WebSearch or AutoSearch you will need to to send a
bogus query to prevent complaining of NO query. Search for NULL or
something. On a web page you could just have a button with a caption
"View Latest Press Releases" and optionally perhaps a option for how
many to return.

$result->title returns just the date and time of the article, so you
will also want to print $result->description after $result->title
so users will have descriptive text identifying the article. 

=head1 AUTHOR

C<WWW::Search::PRWire> is written and maintained by Jim Smyser
<jsmyser@bigfoot.com>.

=head1 COPYRIGHT

(c) PR Newswire Redistribution, retransmission, republication or
commercial exploitation of the contents of PR Newswire are expressly
prohibited without the written consent of PR Newswire.

WWW::Search Copyright (c) 1996-1998 University of Southern California.
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
$VERSION = '1.0';

use Carp ();
use WWW::Search(qw(generic_option strip_tags));

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
             if (!defined($self->{_options})) {
             $self->{_options} = {
             'search_url' => 'http://www.prnewswire.com/tnw/tnw.shtml',
             };
             }
        
        my $options_ref = $self->{_options};
        if (defined($native_options_ref))
             {
        # Copy in new options.
        foreach (keys %$native_options_ref)
             {
        $options_ref->{$_} = $native_options_ref->{$_};
             } 
             } 
        # Process the options.
        my($options) = '';
        foreach (sort keys %$options_ref)
             {
        next if (generic_option($_));
        $options .= $_ . '=' . $options_ref->{$_} . '&';
             }
        chop $options;
        $self->{_next_url} = $self->{_options}{'search_url'};
             } 
# private
sub native_retrieve_some {

        my ($self) = @_;
        print STDERR "**PRWire Get Latest**\n" if $self->{_debug};
            
        # Fast exit if already done:
        return undef if (!defined($self->{_next_url}));
            
        # If this is not the first page of results, sleep so as to not
        # overload the server:
        $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
            
        # Get some if were not already scoring somewhere else:
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
        
        if (m|<TITLE>.*?</TITLE>|i) 
        {
        $state = $HITS;
        } 
   elsif ($state eq $HITS && m@^<A HREF="(.*)">@i) 
        {
        print "**Found Hit URL**\n" if 2 <= $self->{_debug};
        my ($url) = ($1);
        if (defined($hit))
            {
        push(@{$self->{cache}}, $hit);
            };
        $hit = new WWW::SearchResult;
        $hits_found++;
        $url = "http://www.prnewswire.com" . $url;
        $hit->add_url($url);
        $state = $TITLE;
        } 
   elsif ($state eq $TITLE && m|^(.+)</A>|i) 
        {
        my $sTitle = $1;
        $hit->title($sTitle);
        $state = $DESC;
        } 
    elsif ($state eq $DESC && m|^<DD>(.+)|i) 
        {
        $hit->description($1);
        $state = $HITS;
        } 
    elsif ($state eq $HITS && m|Click\s<A HREF="(.*?)">.*?<IMG SRC.*?>|i) 
        {
        $sURL = $1;
        $self->{'_next_url'} = 'http://www.prnewswire.com' . $sURL;
        print STDERR " **Next Tag is: ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
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


