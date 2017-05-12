# YahooNews.pm
# by Jim Smyser
# Copyright (c) 1999 by Jim Smyser
# $Id: YahooNews.pm,v 1.0 2000/07/9 16:05:28 jims Exp $

package WWW::Search::YahooNews;

=head1 NAME

WWW::Search::YahooNews - backend for searching Yahoo News

=head1 SYNOPSIS

use WWW::Search;
$query = "Bob Hope"; 
$search = new WWW::Search('YahooNews');
$search->native_query(WWW::Search::escape_query($query));
$search->maximum_to_retrieve(100);
while (my $result = $search->next_result()) {

$url = $result->url;
$title = $result->title;
$desc = $result->description;

print "<a href=$url>$title</a><br>$desc<p>\n"; 
} 

=head1 DESCRIPTION

This class is a Yahoo specialization of WWW::Search. It handles making
and interpreting Yahoo News Searches. Yahoo allows searching a wide
variety of news sources like SEC and PRWire to name a few.
F<http://www.search.news.yahoo.com>.

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

=head1 AUTHOR

This Backend is will now be maintained and supported by Jim Smyser.
Flames to: <jsmyser@bigfoot.com>

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 CHANGES

1.0
First release. 

=cut
#'

#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = '1.00';

$MAINTAINER = 'Jim Smyser <jsmyser@bigfoot.com>';

use Carp ();
use WWW::Search(qw( generic_option strip_tags ));
require WWW::SearchResult;


# private
sub native_setup_search
  {
   my ($self, $native_query, $native_options_ref) = @_;
   $self->{_debug} = $native_options_ref->{'search_debug'};
   $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
   $self->{_debug} = 0 if (!defined($self->{_debug}));
   $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
   $self->timeout(120); 
   $self->user_agent('user');
   $self->{_next_to_retrieve} = 1;
   $self->{'_num_hits'} = 0;
   if (!defined($self->{_options})) 
    {
    $self->{_options} = {
 'search_url' => 'http://search.news.yahoo.com/search/news?p=' . $native_query. '&z=date&n=20&o=a',  
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
     next if (generic_option($_));
     $options .= $_ . '=' . $options_ref->{$_} . '&';
     }
   chop $options;
   # Finally figure out the url.
   $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
   } # native_setup_search

# private
sub native_retrieve_some
    {
    my ($self) = @_;
    print STDERR "**Getting Some**\n" if $self->{_debug};
    
    # Fast exit if already done:
    return undef if (!defined($self->{_next_url}));
    $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
    
    # Get some:
    print STDERR "**Requesting-> (",$self->{_next_url},")\n" if $self->{_debug};
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) 
      {
      return undef;
      }
    $self->{'_next_url'} = undef;
    print STDERR "**Found Some**\n" if $self->{_debug};

# parse the output
  my ($HEADER, $HITS) = qw(HE HH);
  my ($hits_found) = 0;
  my ($state) = ($HITS);
  my ($hit) = ();
  my $NEXT = '';
  my $URL = '';
  foreach ($self->split_lines($response->content()))
    {
    s/\r$//;  # delete DOS carriage-return
    next if m/^\r?$/; # short circuit for blank lines
    print STDERR "\n * $state ===$_===" if 2 <= $self->{'_debug'};

	
    if ($state eq $HITS && m/^<p><a href/i) 
      {
      print STDERR "**Found Hit's Line**" ;
      my @mLine = split /<p>/;
      foreach my $iHit (@mLine) {

        $URL = $1 if $iHit =~ m@<A HREF="(.*?)">.*?</a>@i;
		$URL =~ s/\/h\//\/htx\//g;
		next if ($URL =~ m@^/@);
        $Title = $1 if $iHit =~ m@<A HREF=".*?">(.+)</a>@i;
		$Title =~ s/<\/a>//g;
		$source = $1 if $iHit =~ m@<small>(.+)</small><br>@i;
		$desc = $1 if $iHit =~ m@<br>(.*</i></small>)@i;
		$desc = $desc . " $source";
        if ($URL ne '')
          {
        if (ref($hit))
          {
        push(@{$self->{cache}}, $hit);
          };
          $hit = new WWW::SearchResult;
          $hit->title(strip_tags($Title));
          $hit->add_url($URL);
          $hit->description($desc);
          $self->{'_num_hits'}++;
          $hits_found++;
          } 
		  }
         $state = $HITS;
          } 
      if ($state eq $HITS && m@^<a href="(/search/news.*?)">@i) 
          {
		$NEXT = $1;
        $self->{'_next_url'} = 'http://search.news.yahoo.com' . $NEXT;
        print STDERR "**Going to Next Page**";
    $state = $HITS;
          } 
          } 
  if (defined($hit)) 
    {
    push(@{$self->{cache}}, $hit);
    }

  return $hits_found;
  } # native_retrieve_some

1;
