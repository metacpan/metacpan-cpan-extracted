
# Monster.pm
# Author: Alexander Tkatchev
# e-mail: Alexander.Tkatchev@cern.ch
#
# WWW::Search back-end for Monster
# http://jobsearch.monster.com/jobsearch.asp

# Maint:
# 4/20/01
# Wayne Rogers
# fixed a problem that skewed results on column to the right.
# Monster now uses only a location ID (lid) vice city, state.

# 2006-02-25 Brian Sammon
# Parsing code update and pod updates.

=head1 NAME

WWW::Search::Monster - class for searching Monster

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Monster');
  my $sQuery = WWW::Search::escape_query("perl and (perl or perl)");
  $oSearch->native_query($sQuery,
  	                 {'st' => 'CA',
                          'tm' => '14d'});
  while (my $res = $oSearch->next_result()) {
      print $res->company . "\t" . $res->title . "\t" . $res->change_date
         . "\t" . $res->location . "\t" . $res->url . "\n";
  }

=head1 DESCRIPTION

This class is a Monster specialization of WWW::Search.
It handles making and interpreting Monster searches at
F<http://www.monster.com>. Monster supports Boolean logic with "and"s
"or"s. See F<http://jobsearch.monster.com/jobsearch_tips.asp> for a full
description of the query language.

The returned WWW::SearchResult objects contain B<url>, B<title>, B<company>,
B<location> and B<change_date> fields.

=head1 OPTIONS

The following search options can be activated by sending
a hash as the second argument to native_query().

=over 2

=item Restrict by Location

use {'lid' => $location_id}

Only jobs in $location_id.
To find out what $location_id you need, please look
at the source of F<http://jobsearch.monster.com>.
Note that $location_id does B<not> mean the area telephone code.
The default is no location restriction.

=item Restrict by Job Category

Use {'fn' => $cat_id}  to select one or more job categories you want.
For multiple selection use a '+' sign, e.g. {'fn' => '1+2'}.
Possible categories are:

=over 2

=item * 1    Accounting/Auditing

=item * 2    Administrative and Support Services

=item * 8    Advertising/Marketing/Public Relations

=item * 5620 Aerospace/Aviation/Defense

=item * 540  Agriculture, Forestry, & Fishing

=item * 9004 Airlines

=item * 541  Architectural Services

=item * 12   Arts, Entertainment, and Media

=item * 576  Banking

=item * 46   Biotechnology and Pharmaceutical

=item * 3979 Building and Grounds Maintenance

=item * 8125 Business Opportunity/Investment Required 

=item * 8126 Career Fairs 

=item * 9005 Computer Services 

=item * 543  Computers, Hardware

=item * 6    Computers, Software

=item * 544  Construction, Mining and Trades

=item * 546  Consulting Services

=item * 5622 Consumer Products 

=item * 545  Customer Service and Call Center

=item * 3    Education, Training, and Library

=item * 7305 Electronics 

=item * 547  Employment Placement Agencies

=item * 5624 Energy/Utilities 

=item * 4    Engineering

=item * 9002 Environmental Services 

=item * 3561 Executive Management 

=item * 548  Finance/Economics

=item * 549  Financial Services

=item * 550  Government and Policy

=item * 7306 Healthcare - Business Office & Finance 

=item * 2947 Healthcare - CNAs/Aides/MAs/Home Health 

=item * 3972 Healthcare - Laboratory/Pathology Services 

=item * 2963 Healthcare - LPNs & LVNs 

=item * 2990 Healthcare - Medical & Dental Practitioners 

=item * 3007 Healthcare - Medical Records, Health IT & Informatics 

=item * 9014 Healthcare - Optical 

=item * 551  Healthcare, Other

=item * 3973 Healthcare - Pharmacy 

=item * 3974 Healthcare - Radiology/Imaging 

=item * 3975 Healthcare - RNs & Nurse Management 

=item * 3976 Healthcare - Social Services/Mental Health 

=item * 3977 Healthcare - Support Services 

=item * 3978 Healthcare - Therapy/Rehab Services 

=item * 552  Hospitality/Tourism

=item * 5    Human Resources/Recruiting

=item * 660  Information Technology

=item * 553  Installation, Maintenance, and Repair

=item * 45   Insurance

=item * 554  Internet/E-Commerce

=item * 555  Law Enforcement, and Security

=item * 7    Legal

=item * 47   Manufacturing and Production

=item * 556  Military

=item * 542  Nonprofit 

=item * 9010 Operations Management 

=item * 11   Other

=item * 557  Personal Care and Service

=item * 9007 Product Management 

=item * 9008 Project/Program Management 

=item * 5623 Publishing/Printing 

=item * 7307 Purchasing 

=item * 558  Real Estate

=item * 13   Restaurant and Food Service

=item * 44   Retail/Wholesale

=item * 10   Sales

=item * 9009 Sales - Account Management 

=item * 9011 Sales - Telemarketing 

=item * 5957 Sales - Work at Home/Commission Only 

=item * 559  Science

=item * 560  Sports and Recreation/Fitness

=item * 5625 Supply Chain/Logistics 

=item * 561  Telecommunications

=item * 9013 Textiles 

=item * 562  Transportation and Warehousing

=item * 9003 Veterinary Services 

=item * 9006 Waste Management Services 

=back

=back

=head1 AUTHOR

C<WWW::Search::Monster> is written and maintained by Alexander Tkatchev
(Alexander.Tkatchev@cern.ch).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Monster;

use strict;
use warnings;

use Carp ();
use HTML::TokeParser;
use WWW::Search qw(generic_option);
use base 'WWW::Search';
use WWW::SearchResult;

our
$VERSION = do { my @r = (q$Revision: 2.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  if (!defined($self->{_options})) {
      $self->{'search_base_url'} = 'http://jobsearch.monster.com';
      $self->{_options} = {
	  'search_url' => $self->{'search_base_url'} . '/jobsearch.asp',
	  'q' => $native_query
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
    $options_ref->{$_} =~ s/\+/\,/g if($_ eq 'st');
    $options_ref->{$_} =~ s/\+/\&$_=/g unless($_ eq 'q');
    $options .= $_ . '=' . $options_ref->{$_} . '&';
    } # foreach
  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;;
  $self->{_debug} = $options_ref->{'search_debug'};
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  my $debug = $self->{'_debug'};
  print STDERR " *   Monster::native_retrieve_some()\n" if($debug);

  # fast exit if already done
  return 0 if (!defined($self->{_next_url}));

  # get some
  print STDERR " *   sending request (",$self->{_next_url},")\n" if($debug);
  my($response) = $self->http_request('GET', $self->{_next_url});
  $self->{'_next_url'} = undef;
  if (!$response->is_success) {
      print STDERR $response->error_as_HTML;
      return 0;
  };
  print STDERR " *   got response\n" if($debug);

  if($response->content =~ m/No jobs matched the query/) {
      print STDERR "No jobs matched the query\n";
      return 0;
  }

  my ($token,$tag);
  my $content = $response->content();
  my $p = new HTML::TokeParser(\$content);
  $content =~ s|<b>||ig;
  $content =~ s|</b>||ig;
  $content =~ s/  / /ig;
  $content =~ m/Jobs (\d+) to (\d+) of (\d+)/;
  my $nrows = $2 - $1 + 1;
  $self->approximate_hit_count($3);

  # Determine _next_url
  my ($nexturl) =
    ($content =~ /<a[^>]*href="([^"]*)[^>]*>Next page &gt;&gt;</ );
  $self->{'_next_url'} = $self->{search_base_url} . $nexturl;

  my($hits_found) = 0;
  my($hit) = ();

  $p = new HTML::TokeParser(\$content);

  #skim the content until we reach the header row of the main table
  while($p->get_tag("td"))
  {
      my $data = $p->get_trimmed_text("/td");
      last if($data eq 'Location' ||
	      $data eq 'Company' ||
	      $data eq 'Modified');   # 'Modified' is not used anymore (Jan06)
  }

  for(my $i = 0; $i< $nrows; $i++) {
      $tag = $p->get_tag("tr");    #Jump to beginning of next row

      $tag = $p->get_tag("td");
      my $date = $p->get_trimmed_text("/td");

      $tag = $p->get_tag("a");
      my $url = $self->{'search_base_url'} . $tag->[1]{href};
      my $title = $p->get_trimmed_text("/a");

      $tag = $p->get_tag("td");
      my $company = $p->get_trimmed_text("/td");

      $tag = $p->get_tag("a");
      my $location = $p->get_trimmed_text("/a");

      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->company($company);
      $hit->change_date($date);
      $hit->title($title);
      $hit->location($location);
      push(@{$self->{cache}}, $hit);
      $hits_found++;
  }
#  return 0;
  return $hits_found;
} # native_retrieve_some

1;

__END__

