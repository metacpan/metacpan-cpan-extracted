#
# YC.pm
# Author: Alexander Tkatchev
# e-mail: Alexander.Tkatchev@cern.ch
#
# WWW::Search back-end for Yahoo!! Classifields
# http://classifieds.yahoo.com/employment.html
#

package WWW::Search::Yahoo::Classifieds::Employment;

use strict;
use warnings;

=head1 NAME

WWW::Search::Yahoo::Classifieds::Employment - class for searching
employment classifieds on Yahoo!

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('Yahoo::Classifieds::Employment');
 my $sQuery = WWW::Search::escape_query("unix c++ java");
 $oSearch->native_query($sQuery,
 			{'g' => 14,
			 'cr' => 'California'});
 while (my $res = $oSearch->next_result()) {
     my $true_url = $oSearch->getMoreInfo($res->url);
     print $res->company . "\t" . $res->title . "\t" . $res->change_date
	 . "\t" . $res->location . "\t" . $true_url . "\n";
 }

=head1 DESCRIPTION

This class is a YC specialization of WWW::Search.
It handles making and interpreting YC searches at
F<http://careers.yahoo.com>

The returned WWW::SearchResult objects contain B<url>, B<title>, B<company>,
B<location> and B<change_date> fields.

The returned B<url> is the one found in the Yahoo! own database. However, it
quite often appears
in other databases where this B<url> was originally taken from.
To retrieve this "true" url use the function B<getMoreInfo> as written in the
above example.

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

=head2 Format / Treatment of Query Terms

The default is to match ALL keywords in your query.
To match ANY keywords use

=over 2

=item   {'za' => 'or'}

=back

=head2 Restrict by Date

The default is to return all ads in the Yahoo ! job database.
To change it use

=over 2

=item   {'g' => $number} - displays jobs posted in last $number days

=back

=head2 Restrict by Company Name

=over 2

=item   {'cpo' => $pattern} 

Display jobs where company name matches $pattern.

=back

=head2 Restrict by Job Title

=over 2

=item   {'cpj' => $pattern} 

Display jobs where job title matches $pattern.

=back

=head2 Restrict by Job Category

No preference by default. To select jobs from a specific job 
category use the following option:

=over 2

=item   {'ce_f' => $job_category}

=back

Category can be one of the following:

=over 2

=item * "Administrative"

=item * "Consulting"

=item * "Creative"

=item * "Education"

=item * "Engineer"

=item * "Finance"

=item * "General Management"

=item * "Health Care"

=item * "Human Resources"

=item * "Internships"

=item * "Information Systems"

=item * "Legal"

=item * "Marketing"

=item * "Operations"

=item * "Sales"

=item * "Scientific"

=item * "Service"

=item * "Training"

=item * "Work at Home"

=item * "Other / Not Specified"

=back

=head2 Restrict by Industry

No restriction by default. The following option is used to 
select jobs from a specific industry:

=over 2

=item {'ce_i' => $desired_industry}

=back

Possible industries include:

=over 2

=item * "Advertising and Public Relations"

=item * "Aerospace and Defense"

=item * "Agriculture"

=item * "Computer Hardware"

=item * "Computer Software"

=item * "Construction"

=item * "Consumer Electronics"

=item * "Consumer Products (Apperal, Household Products)"

=item * "Education"

=item * "Energy and Utilities"

=item * "Entertainment and Sports (Media and Sports)"

=item * "Financial Services (Brokerage, Real Estate, Banking)"

=item * "Health Care (Pharmaceuticals, Biotech, Devices)"

=item * "Heavy Manufacturing (Steel, Autos, Industrial) "

=item * "Hospitality (Hotels, Casinos, Food Service, Travel) "

=item * "Internet and New Media "

=item * "Journalism and Publishing "

=item * "Law"

=item * "Light Manufacturing (Furniture, Office)"

=item * "Non-Profit and Government "

=item * "Professional Services (Consulting, Accounting) "

=item * "Raw Materials "

=item * "Retail and Wholesale (Food/Drug Stores, Retailers) "

=item * "Telecommunications "

=item * "Transportation (Airlines, Delivery, Trucking) "

=item * "Other / Not Specified"

=back

=head2 Restrict by Location

No preference by default. The following option restrict your
search to a desired location:

=over 2

=item   {'cr' => $desired_location}

=back

Location can be one of the following:

=over 2

=item * "Alabama"                   Alabama

=item * "Alaska"                    Alaska

=item * "Arizona"                   Arizona

=item * "Phoenix"                   AZ - Phoenix

=item * "Arkansas"                  Arkansas

=item * "California"                California

=item * "Los Angeles"               CA - Los Angeles

=item * "Sacramento"                CA - Sacramento

=item * "San Diego"                 CA - San Diego

=item * "San Francisco Bay Area"    CA - San Francisco

=item * "Colorado"                  Colorado

=item * "Denver"                    CO - Denver

=item * "Connecticut"               Connecticut

=item * "Hartford"                  CT - Hartford

=item * "Delaware"                  Delaware

=item * "Florida"                   Florida

=item * "Miami"                     FL - Miami

=item * "Orlando"                   FL - Orlando

=item * "Tampa Bay"                 FL - Tampa Bay

=item * "West Palm Beach"           FL - West Palm Beach

=item * "Georgia"                   Georgia

=item * "Atlanta"                   GA - Atlanta

=item * "Hawaii"                    Hawaii

=item * "Idaho"                     Idaho

=item * "Illinois"                  Illinois

=item * "Chicago"                   IL - Chicago

=item * "Indiana"                   Indiana

=item * "Indianapolis"              IN - Indianapolis

=item * "Iowa"                      Iowa

=item * "Kansas"                    Kansas

=item * "Kentucky"                  Kentucky

=item * "Louisville"                KY - Louisville

=item * "Louisiana"                 Louisiana

=item * "New Orleans"               LA - New Orleans

=item * "Maine"                     Maine

=item * "Maryland"                  Maryland

=item * "Baltimore"                 MD - Baltimore

=item * "Massachusetts"             Massachusetts

=item * "Boston"                    MA - Boston

=item * "Michigan"                  Michigan

=item * "Detroit"                   MI - Detroit

=item * "Grand Rapids"              MI - Grand Rapids

=item * "Minnesota"                 Minnesota

=item * "Twin Cities"               MN - Minneapolis

=item * "Mississippi"               Mississippi

=item * "Missouri"                  Missouri

=item * "Kansas City"               MO - Kansas City

=item * "Saint Louis"               MO - St. Louis

=item * "Montana"                   Montana

=item * "Nebraska"                  Nebraska

=item * "Nevada"                    Nevada

=item * "Las Vegas"                 NV - Las Vegas

=item * "New Hampshire"             New Hampshire

=item * "New Jersey"                New Jersey

=item * "New Mexico"                New Mexico

=item * "Albuquerque"               NM - Albuquerque

=item * "New York"                  New York

=item * "New York City"             NY - New York City

=item * "Buffalo"                   NY - Buffalo

=item * "North Carolina"            North Carolina

=item * "Charlotte"                 NC - Charlotte

=item * "Greensboro"                NC - Greensboro

=item * "Raleigh/Durham"            NC - Raleigh/Durham

=item * "North Dakota"              North Dakota

=item * "Ohio"                      Ohio

=item * "Cincinnati"                OH - Cincinnati

=item * "Cleveland"                 OH - Cleveland

=item * "Columbus"                  OH - Columbus

=item * "Oklahoma"                  Oklahoma

=item * "Oklahoma City"             OK - Oklahoma City

=item * "Oregon"                    Oregon

=item * "Portland"                  OR - Portland

=item * "Pennsylvania"              Pennsylvania

=item * "Harrisburg"                PA - Harrisburg

=item * "Philadelphia"              PA - Philadelphia

=item * "Pittsburgh"                PA - Pittsburgh

=item * "Wilkes Barre"              PA - Wilkes Barre

=item * "Rhode Island"              Rhode Island

=item * "Providence"                RI - Providence

=item * "South Carolina"            South Carolina

=item * "Greenville"                SC - Greenville

=item * "South Dakota"              South Dakota

=item * "Tennessee"                 Tennessee

=item * "Memphis"                   TN - Memphis

=item * "Nashville"                 TN - Nashville

=item * "Texas"                     Texas

=item * "Austin"                    TX - Austin

=item * "Dallas/Fort Worth"         TX - Dallas/Fort Worth

=item * "Houston"                   TX - Houston

=item * "San Antonio"               TX - San Antonio

=item * "Utah"                      Utah

=item * "Salt Lake City"            UT - Salt Lake City

=item * "Vermont"                   Vermont

=item * "Virginia"                  Virginia

=item * "Norfolk"                   VA - Norfolk

=item * "Washington"                Washington

=item * "Seattle"                   WA - Seattle

=item * "Washington DC"             Washington D.C.

=item * "West Virginia"             West Virginia

=item * "Wisconsin"                 Wisconsin

=item * "Milwaukee"                 WI - Milwaukee

=item * "Wyoming"                   Wyoming

=back

=head1 AUTHOR

C<WWW::Search::YC> is originally written by Alexander Tkatchev
(Alexander.Tkatchev@cern.ch).

=head1 VERSION HISTORY

1.02 -- patches from Rick Myers (rik@sumthin.nu) that fixes important changes in Yahoo! Classifieds search engine. Plus some fixes of my own... 

1.01 -- original release

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

use Carp ();
require HTML::TokeParser;
use WWW::Search qw(generic_option);
use base 'WWW::Search';
require WWW::SearchResult;

our
$VERSION = do { my @r = (q$Revision: 1.112 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  if (!defined($self->{_options})) {
      $self->{'search_base_url'} = 'http://classifieds.yahoo.com';
      $self->{_options} = {
	  'search_url' => $self->{'search_base_url'} . '/display' .'/employment',
	  'cr' => '',
	  'ck' => $native_query,
	  'ce_f' => '',
	  'cpo' => '',
	  'cpj' => '',
	  'g'  => 30,
	  'cs' => 'time+2',
	  'cc' => 'employment',
	  'cf' => '',
	  'za'  => 'and',
	  'ct_hft' => 'table'
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
    my $escaped = $options_ref->{$_};
    $escaped = WWW::Search::escape_query($options_ref->{$_}) 
	if ($_ eq 'cr' || $_ eq 'ce_f' || $_ eq 'cpj' || 
	    $_ eq 'cpo' || $_ eq 'ce_i');
    $options .= $_ . '=' . $escaped . '&';
    }
  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;
  $self->{_debug} = $options_ref->{'search_debug'};
  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  my $debug = $self->{'_debug'};
  print STDERR " *   YC::native_retrieve_some()\n" if($debug);
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  
  # sleep so as to not overload the server:
  $self->user_agent_delay;
  
  # get some
  print STDERR " *   sending request (",$self->{_next_url},")\n" if($debug);
  my($response) = $self->http_request('GET', $self->{_next_url});
  $self->{'_next_url'} = undef;
  if (!$response->is_success) {
      print STDERR $response->error_as_HTML;
      return undef;   
  }
  
  print STDERR " *   got response\n" if($debug);

  if($response->content 
     =~ m/Your search found no results|No results match your search/) {
      print STDERR "No documents matched the query\n";
      return 0;
  }

  # parse the output
  my($hits_found) = 0;
  my($hit) = ();

  my $p = new HTML::TokeParser(\$response->content());
  my $tag;

  $tag = $p->get_tag("form");
  my $action = $tag->[1]{action};
  my $extra_url = '';
  while(1) {
      $tag = $p->get_tag("input");
      $extra_url .= $tag->[1]{name} . '=' .
                    WWW::Search::escape_query($tag->[1]{value}) . '&';
      last if $tag->[1]{name} eq 'search';
#      exit;
  }

  while(1) {
      $tag = $p->get_tag("td");
      my $data = $p->get_trimmed_text("/td");
      last if($data eq 'LOCATION' ||
	      $data eq 'COMPANY' ||
	      $data eq 'FULL LISTING');
  }


  while(1) {
      $tag = $p->get_tag("tr");
      $tag = $p->get_tag("td"); # first column contains only spaces
      $tag = $p->get_tag("td"); # this one does as well
      $tag = $p->get_tag("td");
      my $date = $p->get_trimmed_text("/td");
      last unless($date =~ m|(\d+)/(\d+)/(\d+)|);
      $tag = $p->get_tag("td");
      my $company = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("td");
      my $function = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("td");
      my $term = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("td");
      my $title = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("td");
      my $location = $p->get_trimmed_text("/td");
      $tag = $p->get_tag("input");
      my $name = $tag->[1]{name};
      my $value = $tag->[1]{value};
#      my $url = $tag->[1]{href};
#      $url =~ s/$CR?$LF//g;
#      $url =~ s/(pre\=)(\d+)(\&)//;
#      $url =~ s/\&cr\=national//;
      my $url = $self->{search_base_url}.
                "$action?$extra_url&$name=$value&position0.x=1&position0.y=1";
#     print STDERR "$location\t$title\t$company\t$date\t$url\n";
      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->company($company);
      $hit->change_date($date);
      $hit->title($title);
      $hit->description($function);
      $hit->location($location);
      push(@{$self->{cache}}, $hit);
      $hits_found++;
  }


  #
  # Find next link
  #
  $p = new HTML::TokeParser(\$response->content());
  while(1) {
      $tag = $p->get_tag("img");
      last if($tag->[1]{'alt'} eq 'Previous');
  }

 FIND_NEXT_URL: while(1) {
     $tag = $p->get_tag("a");
     my $nextlink = $tag->[1]{href};
     if(defined($nextlink)) {
	 my $linklabel = $p->get_trimmed_text("/a");
	 next FIND_NEXT_URL if($linklabel =~ m/Previous/);
	 if(!($linklabel =~ m/Next/)) {
	     print "No next link\n" if($debug);
	     last;
	 }
	 $nextlink =~ s/[\r\n]//g; # not sure here but $CR and $LF are undefined
	 print "$linklabel: $nextlink\n"  if($debug);
	 $self->{'_next_url'} = $self->{'search_base_url'} . $nextlink;
	 last;
     }
 }

  return $hits_found;
} # native_retrieve_some

sub getMoreInfo {
    my $self = shift;
    my $url = shift;
    my($response) = $self->http_request('GET',$url);
    if ($response->is_success) {
	my $content = $response->content();
	if($content =~ m/Additional information/) {
	    my $p = new HTML::TokeParser(\$content);
	    my ($tag,$testurl);
	    while(1) {
		$tag = $p->get_tag("a");
		$testurl = $tag->[1]{href};
		my $linktitle = $p->get_trimmed_text("/a");
		if($linktitle =~ m/Additional information/) {
		    last if($testurl =~ m/net-temps/);
		    $url = $testurl;
		    $url =~ s|yahoo/yahoo_frameset.cgi\?||;
		    $url =~ s/\&html\=yahoofoundhtml//;
		    last;
		}
	    }
	}
    }
    return $url;
}


1;
