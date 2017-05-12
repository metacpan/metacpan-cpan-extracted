#
# Aol.pm
# Author: Alexander Tkatchev
# e-mail: Alexander.Tkatchev@cern.ch
#
# WWW::Search back-end for Aol Jobs
# http://classifiedplus.aol.com/aolnc.aolc/clengine/icleng
#

=head1 NAME

WWW::Search::AOL::Classifieds::Employment - class for searching Jobs Classifieds on AOL

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('Aol');
 my $sQuery = WWW::Search::escape_query("unix c++ java");
 $oSearch->native_query($sQuery,
			{'qcqs' => ':ca:'});
 while (my $res = $oSearch->next_result()) {
     print $res->company . "\t" . $res->title . "\t" . $res->change_date
	 . "\t" . $res->location . "\n";
 }

=head1 DESCRIPTION

This class is a Aol specialization of WWW::Search.
It handles making and interpreting Aol searches at
F<http://classifiedplus.aol.com> in category employment->JobSearch.

The returned WWW::SearchResult objects contain B<url>, B<title>, B<company>,
B<location> and B<change_date> fields.

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

=head2 Format / Treatment of Query Terms

The default is to match ALL keywords in your query.

=over 2

=item   {'QY' => 2} - to match at least one word

=item   {'QY' => 5} - to match exact phrase

=back

=head2 Restrict by Job Category

No restriction by default. To select jobs from a specific job 
category use the following option:

=over 2

=item   {'QVSSCAT' => $job_category}

=back

Possible values of $job_category are the following:

=over 2

=item *  10   	Accounting/Finance/Banking/Insurance

=item *  20   	Administrative/Clerical

=item *  30   	Creative Arts/Media

=item *  40   	Education/Training

=item *  50   	Engineering/Architecture/Design

=item *  60   	Human resources

=item *  70   	Information Technology/Computer

=item *  80   	Legal/Law Enforcement/Security

=item *  90   	Marketing/Public relations/Advertising

=item *  100   	Medical/Heath Care/Dental

=item *  110   	Online/Internet/New Media

=item *  120   	Sales/Customer Service/Sales Management

=item *  130   	Sports

=item *  140   	Travel/Hospitality/Restaurant/Transportation

=item *  150   	Other

=back

=head2 Restrict by Company Name

=over 2

=item   {'QM' => $pattern} 

Display jobs where company name matches $pattern.

=back

=head2 Restrict by Location

No preference by default. Several options can restrict your search.
Only one of the below listed options can be enabled at a time.

=over 2

=item {'QREG' => $region} - to select a region

Regions can be:

=back

=over 2

=item * 1     Mid-Atl

=item * 2     Midwest

=item * 3     Northeast

=item * 4     Northwest

=item * 5     Southeast

=item * 6     Southwest

=item * 7     West

=item * 8     Outside USA

=item * 9999  National

=back

=over 2

=item {'qcqs' => $state_or_city} - more detailed selection

There are too many possible values to be listed here. See 
F<http://classifiedplus.aol.com> in category employment->JobSearch for a full
list. Here are some examples from that list: to select jobs only from 
California use {'qcqs' => ':ca:'}, for jobs from San Fransisco use
{'qcqs' => 'san francisco:ca:807'}.

=item {'QZ' => $zip_code} - restrict by zip code.

=back

=head1 AUTHOR

C<WWW::Search::Aol> is written and maintained by Alexander Tkatchev
(Alexander.Tkatchev@cern.ch).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

package WWW::Search::AOL::Classifieds::Employment;

use strict;
use warnings;

use Carp ();
require HTML::TokeParser;
use WWW::Search qw(generic_option);
use base 'WWW::Search';
require WWW::SearchResult;

our
$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  my $base_url = 'http://classifiedplus.aol.com/aolnc.aolc/clengine/icleng?cat=JOBS&op=search&PDBN=AOLJTITLE&QVSCAT=1&QVCAT=3&COND=&VTITLE=Employment+Ads&QVSSCAT=&QW=' . $native_query . '&QY=1&QM=&QREG=&qcqs=&QZ=&QFDMA=1&QENH=&TITLE=Job+Offers&_ADSRC=&FEATITLE=&_ADV_ST=2&_ADV_SRC=&_ADV_USR=&_debug=&_DEFDMA=';

  foreach (sort keys %$native_options_ref) {
      next if (generic_option($_));
      my $escaped = WWW::Search::escape_query($native_options_ref->{$_});
      $base_url =~ s/\&$_=/\&$_=$escaped/ 
	  if($_ eq 'QVSSCAT' || $_ eq 'QM' || $_ eq 'QREG' || 
	     $_ eq 'qcqs' || $_ eq 'QZ');
      $base_url =~ s/\&QY=1/\&QY=$escaped/ if($_ eq 'QY');
  }
  $self->{'search_base_url'} = $base_url;
  $self->{_next_url} = $self->{'search_base_url'};
  $self->{_debug} = $native_options_ref->{'search_debug'};
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  my $debug = $self->{_debug};
  print STDERR " *   Aol::native_retrieve_some()\n" if($debug);
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  
  # get some
  print STDERR " *   sending request (",$self->{_next_url},")\n" if($debug);
  my($response) = $self->http_request('GET', $self->{_next_url});
  $self->{'_next_url'} = undef;
  if (!$response->is_success) {
      print STDERR $response->error_as_HTML;
      return undef;
  };
  
  print STDERR " *   got response\n" if($debug);
  if($response->content =~ m/There were no matches for your selection/) {
      print STDERR "Nothing matched the query\n";
      return 0;
  }

  my ($tag,$nexturl);
  my $p = new HTML::TokeParser(\$response->content());
  if($response->content =~ m/Next (\d+) Results/ ) {
      while(1) {
	  $tag = $p->get_tag("a");
	  $nexturl = $tag->[1]{href};
	  my $linktitle = $p->get_trimmed_text("/a");
	  last if($linktitle =~ m/Next (\d+) Results/);
      }
      print STDERR "Next page url: $nexturl\n" if($debug);
      $self->{'_next_url'} = $nexturl;
  } else {
      print STDERR "No next page\n" if($debug);
  }

  while(1) {
      $tag = $p->get_tag("td");
      my $data = $p->get_trimmed_text("/td");
      last if($data eq 'Location' ||
              $data eq 'Date');
  }
  $tag = $p->get_tag("tr");

  my($hits_found) = 0;
  my($hit) = ();
  while(1) {
      $tag = $p->get_tag("a");
      my $url = $tag->[1]{href};
      my $title = $p->get_trimmed_text("/a");
      last if($title =~ m/Click here to see less details/);
      $tag = $p->get_tag("b");
      my $date = $p->get_trimmed_text("/b");
      last unless($date =~ m|(\d\d)/(\d\d)/(\d\d\d\d)|);
      $tag = $p->get_tag("b");
      my $company = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("td");
      my $location = $p->get_trimmed_text("/td");
      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->company($company);
      $hit->change_date($date);
      $hit->title($title);
      $hit->location($location);
      push(@{$self->{cache}}, $hit);
      $hits_found++;
  }
  return $hits_found;
} # native_retrieve_some

1;
