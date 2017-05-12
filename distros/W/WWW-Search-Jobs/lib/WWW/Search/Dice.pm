#
# Dice.pm
# Author: Alexander Tkatchev 
# e-mail: Alexander.Tkatchev@cern.ch
#
# WWW::Search back-end Dice
# http://jobsearch.dice.com/jobsearch/jobsearch.cgi
#

package WWW::Search::Dice;

use strict;
use warnings;

=head1 NAME

WWW::Search::Dice - class for searching Dice

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('Dice');
 my $sQuery = WWW::Search::escape_query("unix and (c++ or java)");
 $oSearch->native_query($sQuery,
 			{'method' => 'bool',
		         'state' => 'CA',
		         'daysback' => 14});
 while (my $res = $oSearch->next_result()) {
     if(isHitGood($res->url)) {
 	 my ($company,$title,$date,$location) = 
	     $oSearch->getMoreInfo($res->url);
 	 print "$company $title $date $location " . $res->url . "\n";
     } 
 }

 sub isHitGood {return 1;}

=head1 DESCRIPTION

This class is a Dice specialization of WWW::Search.
It handles making and interpreting Dice searches at
F<http://www.dice.com>.


By default, returned WWW::SearchResult objects contain only url, title
and description which is a mixture of location and skills wanted.
Function B<getMoreInfo( $url )> provides more specific info - it has to
be used as

    my ($company,$title,$date,$location) = 
        $oSearch->getMoreInfo($res->url);

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

=head2 Format / Treatment of Query Terms

The default is to treat entire query as a boolean
expression with AND, OR, NOT and parentheses

=over 2

=item   {'SEARCH_INCLUDE' => 'and'}

Logical AND of all the query terms.

=item   {'SEARCH_INCLUDE' => 'or'}

Logical OR of all the query terms.

=item   {'SEARCH_INCLUDE' => 'bool'}

treat entire query as a boolean expression with 
AND, OR, NOT and parentheses.
This is the default option.

=back

=head2 Restrict by Date

The default is to return jobs posted in last 30 days

=over 2

=item   {'DAYSBACK' => $number}

Display jobs posted in last $number days

=back

=head2 Restrict by Location

The default is "ALL" which means all US states

=over 2

=item   {'STAT_PROV' => $state} - Only jobs in state $state.

=item   {'STAT_PROV' => 'CDA'} - Only jobs in Canada.

=item   {'STAT_PROV' => 'INT'} - To select international jobs.

=item   {'STAT_PROV' => 'TRV'} - Require travel.

=item   {'STAT_PROV' => 'TEL'} - Display telecommute jobs.

=back

Multiple selections are possible. To do so, add a "+" sign between
desired states, e.g. {'STAT_PROV' => 'NY+NJ+CT'}

You can also restrict by 3-digit area codes. The following option does that:

=over 2

=item   {'AREA_CODES' => $area_code}

=back

Multiple area codes (up to 5) are supported.

=head2 Restrict by Job Term

No restrictions by default.

=over 2

=item {'TAXTERM' => 'CON_W2' - Contract - W2

=item {'TAXTERM' => 'CON_IND' - Contract - Independent

=item {'TAXTERM' => 'CON_CORP' - Contract - Corp-to-Corp

=item {'TAXTERM' => 'CON_HIRE_W2' - Contract to Hire - W2

=item {'TAXTERM' => 'CON_HIRE_IND' - Contract to Hire - Independent

=item {'TAXTERM' => 'CON_HIRE_CORP' - Contract to Hire - Corp-to-Corp

=item {'TAXTERM' => 'FULLTIME'} - full time

=back

Use a '+' sign for multiple selection.

There is also a switch to select either W2 or Independent:

=over 2

=item {'addterm' => 'W2ONLY'} - W2 only

=item {'addterm' => 'INDOK'} - Independent ok

=back

=head2 Limit total number of hits

The default is to stop searching after 500 hits.

=over 2

=item  {'num_to_retrieve' => $num_to_retrieve}

Changes the default to $num_to_retrieve.

=back

=head1 AUTHOR

C<WWW::Search::Dice> is written and maintained by Alexander Tkatchev
(Alexander.Tkatchev@cern.ch).

Version 2.00: Scraper subclassing, updating to Dice's 27.Apr.01 CGI format, and other minor changes done by Glenn Wood, C<glenwood@alumni.caltech.edu>

Version 2.02: written by Brian Sammon

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Carp ();
use HTML::TokeParser;
use HTTP::Request::Common;
use WWW::SearchResult;
use WWW::Search('generic_option');
use base 'WWW::Search';

our
$VERSION = do{ my @r = (q$Revision: 2.732 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r};

sub native_setup_search
{
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  $self->{_first_call} = 1;

  $self->{'search_base_url'} = 'http://seeker.dice.com';
  if (!defined($self->{_options}))
  {
    print "  Setting self->{_options}\n";
      $self->{_options} = {
	  'search_url' => ($self->{search_base_url} .
			   '/jobsearch/servlet/JobSearch'),
	  'DETAILED_RESULTS' => '',
	  'SEARCH_INCLUDE' => 'BOOL',
	  'FREE_TEXT' => $native_query,
	  'TAXTERM' => 'ALL',
	  'STAT_PROV' => 'ALL',         # or two character abbreviation(s)
	  'AREA_CODES' => '',            # multiple acode INPUT fields
	  'DAYSBACK' => 30,         # (1, 2, 7, 10, 14, 21, 30)
	  'NUM_PER_PAGE' => 50,     # (10, 20, 30, 40, 50) 
	  'start_doc' => 1,         # Which result to start with 

			   #obsolete?
	  #'banner' => '0',
	  #'num_to_retrieve' => 2000 # (100, 200, 300, 400, 500, 600, 2000)
      };
  } # if

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
  foreach (sort keys %$options_ref) 
  {
    next if (generic_option($_));
    # convert things like 'state' => 'NY+NJ' into 'state' => 'NY&state=NJ'
    $options_ref->{$_} =~ s/\+/\&$_=/g
      unless($_ eq 'query' || $_ eq 'AREA_CODES');
  }

  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'};

  $self->{_debug} = $options_ref->{'search_debug'};
  $self->{'_allow_empty_query'} = 1;
} # native_setup_search


# private
sub native_retrieve_some
{
  my ($self) = @_;
  my $debug = $self->{'_debug'};
  print STDERR " *   Dice::native_retrieve_some()\n" if($debug);
  
  # fast exit if already done
  return 0 if (!defined($self->{_next_url}));
  
  my $options_ref = $self->{_options};
  my $options = "op=100&";  #Dice requires this
  foreach (sort keys %$options_ref) 
  {
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&';
  }

  print STDERR "Sending POST request to " . $self->{_next_url} .
             "\tPOST options: " . $options . "\n" 
   	      if ($debug);
  my $ua = $self->{user_agent};
  my $req = new HTTP::Request('POST', $self->{_next_url});
  $req->content_type('application/x-www-form-urlencoded');
  $req->content($options);
  my $response = $ua->request($req);

  if (!$response->is_success) {
      print STDERR $response->error_as_HTML;
      return 0;
  };
  print STDERR "Got response\n" if($debug);
  
  $self->{'_response'} = $response;    #is this necessary?

  if($response->content() =~ 
     m/Sorry, no documents matched your search criteria/) {
    print STDERR "Sorry, no hits found\n"; 
	  $self->{'_next_url'} = undef;
	  return 0;
  }
  print STDERR " *   got response\n" if($debug);

  my $content = $response->content();

  $content =~ m/Jobs\s*(\d+)\s*-\s*(\d+)\s*of\s*(\d+)/s;
  my $nrows = $2 - $1 + 1;
  $self->approximate_hit_count($3);

  $content =~ s/.*?Company\s*Name//s;
  $content =~ s|</table>.*||s;

  my ($token,$tag);

  my($hits_found) = 0;
  my($hit) = ();

  my $p = new HTML::TokeParser(\$content);
  #skim the content until we reach the header row of the main table
  while($p->get_tag("td"))
  {
      my $data = $p->get_trimmed_text("/td");
      last if($data eq 'Location' ||
	      $data eq 'Company Name' ||
	      $data eq 'Job Title');
  }

  while($p->get_tag("tr") && ($tag = $p->get_tag('a')))
  {
      my $url = $tag->[1]{href};
      $url = $self->{'search_base_url'} . $url;
      my $title = $p->get_trimmed_text("/a");

      $tag = $p->get_tag("td");
      my $company = $p->get_trimmed_text("/td");

      $tag = $p->get_tag("td");
      my $location = $p->get_trimmed_text("/td");

      $tag = $p->get_tag("td");
      my $date = $p->get_trimmed_text('/td', '/tr');

      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->company($company);
      $hit->change_date($date);
      $hit->title($title);
      $hit->location($location);
      push(@{$self->{cache}}, $hit);
      $hits_found++;
  }
  $self->{_options}->{start_doc} += $self->{_options}->{'NUM_PER_PAGE'};
  return $hits_found;
} # native_retrieve_some

1;
