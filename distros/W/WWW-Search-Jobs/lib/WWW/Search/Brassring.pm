#
# Brassring.pm
# Author: Wayne Rogers
# e-mail: wayers@eskimo.com
#
# Based upon Dice.pm by Alexander.Tkatchev@cern.ch
# WWW::Search back-end Brassring
# http://www.brassring.com/jobsearch
#

package WWW::Search::Brassring;

use strict;
use warnings;

=head1 NAME

WWW::Search::Brassring - class for searching http://www.Brassring.com/jobsearch

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('Brassring');
 my $sQuery = WWW::Search::escape_query("java");
 $oSearch->native_query($sQuery,
 			{'city' => 'San Diego',
		         'st' => 'CA',
			 'prox' => '10', # proximity to 'city', 10, 25, 50 miles
		         'pp' => 10}); # hits per page, 10, 25, 50

while (my $res = $oSearch->next_result()) {
    print "$res->{url} $res->{title} $res->{change_date} $res->{description}\n";

     }


=head1 DESCRIPTION

This class is a Brassring specialization of WWW::Search.
It handles making and interpreting Brassring searches at
F<http://www.brassring.com/jobsearch>.

By default, returned WWW::SearchResult objects contain only url, title
and description which is a mixture of location and skills wanted.

=head1 OPTIONS

=over

=item Query on Keywords, Title or Company

{'q' => 'programmer'}

The following search options can be activated by sending
a hash as the second argument to native_query().

=item Restrict search by country

{'ctry' => 'United States'}

=item Sort jobs found

Sort by relevance: {'like' => 'likep'}

Sort by posting date: {'like' =>  'like'}

=item Restrict jobs found by state (US)

{'st' => $st} - Only jobs in st $st.

=back

=head1 AUTHOR

C<WWW::Search::Brassring> was written by Wayne Rogers (wayers@eskimo.com) 
based  on the work of Alexander Tkatchev.
(Alexander.Tkatchev@cern.ch).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Carp ();
use HTML::TokeParser;
use base 'WWW::Search';
use WWW::SearchResult;

our
$VERSION = do{ my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r};

sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  $self->{_first_call} = 1;

  if (!defined($self->{_options})) {
      $self->{'search_base_url'} = 'http://www.brassring.com';
      $self->{_options} = {
	  'search_url' => $self->{'search_base_url'} . '/cgi-bin/texis/vortex/jobsearch/results.html',
	  'q' => $native_query,
	  'st' => 'ALL',
	  'pp' => '',
	  'prox' => 10,
	  'like' => 'likep'
      };
  } # if
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
    
    $options_ref->{$_} =~ s/\+/\&$_=/g unless($_ eq 'query');
    $options .= $_ . '=' . $options_ref->{$_} . '&';
    }
  $self->{_to_post} = $options;
  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'};

  $self->{_debug} = $options_ref->{'search_debug'};
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  my $debug = $self->{'_debug'};
  print STDERR " *   Brassring::native_retrieve_some()\n" if ($debug);
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  
  my ($response,$tag,$url);

  my $req = new HTTP::Request('GET', $self->{_next_url});
  $req->content_type('application/x-www-form-urlencoded');
  $req->content($self->{_to_post});
  my $ua = $self->{user_agent};
  $response = $ua->request($req);

  if($self->{_first_call}) {
      $self->{_first_call} = 0;
      print STDERR "Sending GET request to " . $self->{_next_url} .
	  "\tGET options: " . $self->{_to_post} . "\n" 
	      if ($debug);

      if($response->content() =~ 
	 # no jobs
	 m/There.+are.+0 jobs/s) {
	  print STDERR "0 jobs found\n"; 
	  $self->{'_next_url'} = undef;
	  return 0;
      }
  }

  print STDERR " *   sending request (",$self->{_next_url},")\n" 
      if($debug);

  my $p = new HTML::TokeParser(\$response->content());
  while(1) {
      $tag = $p->get_tag("a");
      $url = $self->{'search_base_url'} . $tag->[1]{href};
      last if($url =~ m/JobId/);
  }

  my($hits_found) = 0;
  my($hit) = ();
  while(1) {
      my $title = $p->get_trimmed_text("/a");

      $p->get_tag("tr");
      $tag = $p->get_tag("td");
      $tag = $p->get_tag("td");
      
      my $description = $p->get_trimmed_text("/td");

      $p->get_tag("tr");
      $p->get_tag("td");
      $tag = $p->get_tag("td");
      my $location = $p->get_trimmed_text("/td");

      $p->get_tag("td");
      my $date = $p->get_trimmed_text("/td");
      $date =~ s|.+(\d\d/\d\d/\d\d\d\d)|$1|;
      
      print STDERR "$date\t$title\t$url\t$description\n" if($debug);
      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->title($title);
      $hit->change_date($date);
      $hit->description($description);

      push(@{$self->{cache}}, $hit);
      $hits_found++;

      $p->get_tag("tr");
      $p->get_tag("td");
      $tag = $p->get_tag("a");
      $url = $self->{'search_base_url'} . $tag->[1]{href};
      last unless($url =~ m/JobId/);
  }

  if($response->content() =~ m/Show next/) {
      while(1) {
	  my $linktitle = $p->get_trimmed_text("/a");
	  if($linktitle =~ m/Show next/) {
	      $self->{'_next_url'} = $url;
	      print STDERR "Next url is $url\n" if($debug);
	      last;
	  }
	  $tag = $p->get_tag("a");
	  $url = $tag->[1]{href};
      }
  } else {
      print STDERR "**************** No next link \n" if($debug);
      $self->{_next_url} = undef;
  }

  return $hits_found;
} # native_retrieve_some

1;

__END__
