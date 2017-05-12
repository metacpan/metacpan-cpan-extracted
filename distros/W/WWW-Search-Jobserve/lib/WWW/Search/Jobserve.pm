# Jobserve.pm
# Written by Andy Pritchard.
# $Id: Jobserve.pm,v 1.02 2003-09-25 16:13:30 ninja $

package WWW::Search::Jobserve;

@ISA = qw( WWW::Search );

use WWW::Search qw( generic_option strip_tags );
use WWW::Search::Result;

$VERSION = '1.02';
$MAINTAINER = 'Andy Pritchard <pilchkinstein@hotmail.com>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  
  # Set some private variables:
  $self->{_debug} ||= $rhOptsArg->{'search_debug'};
  $self->{_debug} = 2 if ($rhOptsArg->{'search_parse_debug'});
  $self->{_debug} ||= 0;
  

  my $DEFAULT_HITS_PER_PAGE = 50;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;
  
  my $sjob_category  = $rhOptsArg->{'job_category'};
  my $sjobserve_site = $rhOptsArg->{'jobserve_site'};
  my $sjob_type      = $rhOptsArg->{'job_type'};
  my $sjob_lookahead = $rhOptsArg->{'job_lookahead'};
  my $sjob_order     = $rhOptsArg->{'job_order'};
     $sjobserve_site ||= 'uk'; 	# Default to English site
     $sjob_type      ||= '*'; 	# Default to all
     $sjob_lookahead ||= '5'; 	# Default to 5 Days
     $sjob_order     ||= 'Rank';# Default to Rank (Best Match) 
  
  my %Country_Params = ( uk => 'jobserve.com/jobserve/',
  		         au => 'job-serve.com.au/jobserve/',
  		       ) ;

  $self->user_agent('non-robot');

  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;
  $self->{'_base_url'} = "http://www.$sjob_category.$Country_Params{$sjobserve_site}";

  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'search_url' 	=> $self->{'_base_url'} . 'searchresults.asp',
                         'jobType'	=> $sjob_type,		# Job Type (*|C|P) == (Any|Contract|Permanent)
                         'd'		=> $sjob_lookahead,	# No of days to look ahead
                         'order'	=> $sjob_order,# Sort order (Rank|DateTime) == (Best Match|Latest Job)
                         'q' 		=> $native_query,	# The escaped query
                        };
    } # if
  if (defined($rhOptsArg))
    {
    # Copy in new options.
    foreach my $key (keys %$rhOptsArg)
      {
      #print STDERR " +   inspecting option $key...";
      if (WWW::Search::generic_option($key))
        {
         print STDERR "promote & delete\n";
        $self->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        delete $rhOptsArg->{$key};
        }
      else
        {
        #print STDERR "copy\n";
        $self->{_options}->{$key} = $rhOptsArg->{$key} if defined($rhOptsArg->{$key});
        }
      } # foreach
    } # if

    die " - Must specify a job category to search...\n" unless (defined($self->{_options}->{'job_category'}));
    # Finally, figure out the url.
    $self->{_next_url} = $self->{_options}->{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
  } # native_setup_search

sub preprocess_results_page
  {
    my $self = shift;
    my $sPage = shift;
    print STDERR " + RawHTML ===>$sPage<=== RawHTML\n" if 2 < $self->{_debug};
    return $sPage;
  } # preprocess_results_page

# private
sub parse_tree
  {
  my $self = shift;
  my $tree = shift;

  # A pattern to match HTML whitespace:
  my $W = q{[\ \t\r\n\240]};
  my $hits_found = 0;
  if (2 < $self->{_debug}) {
  	print STDERR "=========================== HTML::Tree Dump START ============================\n";
  	print STDERR $tree->as_HTML();
  	print STDERR "============================ HTML::Tree Dump END =============================\n";
  }
  # The hit count is in a FONT tag:
  my @aoFONT = $tree->look_down('_tag', 'font');
  my @aoTABLE = $tree->look_down('_tag', 'table');
         
 FONT:
  foreach my $oFONT (@aoFONT)
    {
    print STDERR " +   try FONT ===", $oFONT->as_text, "===\n" if 1 < $self->{_debug};
    if ($oFONT->as_text =~ m!of (\d+) Matching Jobs!)
        {
        $self->approximate_result_count($1);
        last FONT;
        } # if
    } # foreach
  TABLE:
   foreach my $oTABLE (@aoTABLE) # Go <table> -> <td> -> <font1> -> <font2> -> <font3> -> <font4>
   {
     print STDERR " +   try TABLE ===", $oTABLE->as_HTML, "===\n" if 1 < $self->{_debug}; 
     my @aoFONT = $oTABLE->look_down('_tag', 'font');
     my $oFONT = shift(@aoFONT);
     next TABLE unless ref $oFONT;
     print STDERR " +   try TABLE->FONT ===", $oFONT->as_text, "===\n" if 1 < $self->{_debug}; 
     # First A tag contains the url & title:
     my @aoA = $oFONT->look_down('_tag', 'a');
     my $oA = shift(@aoA);
     next TABLE unless ref $oA;
     next TABLE if (($oA->as_HTML) =~ m!class="ToolBar"!ig);
     print STDERR " +   try TABLE->FONT->A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug}; 
     # Occasionally they have these atsco links in there, this skips over in this case.
     if (($oA->as_HTML) !~ m!\?jobid\=!ig) {
       $oA = shift(@aoA);
       print STDERR " +   Re-try TABLE->FONT->A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug}; 
     }     
     # Jobserve only gives us a path relative to the _base_url
     my $sURL = $self->{'_base_url'} . $oA->attr('href');
     print STDERR " +   GOT URL:$sURL:\n" if 1 < $self->{_debug}; 
     my $sTitle = $oA->as_text;
     print STDERR " +   GOT Title:$sTitle:\n" if 1 < $self->{_debug}; 
      # Now go down another font
     my $oFONT2 = shift(@aoFONT);
      # And another
     my $oFONT3 = shift(@aoFONT);
     print STDERR " +   try TABLE->FONT3 ===", $oFONT3->as_text, "===\n" if 1 < $self->{_debug};        
     my $sDesc = $oFONT3->as_text;
      # And yet another
     my $oFONT4 = shift(@aoFONT);
     $oFONT4 = shift(@aoFONT) if (($oFONT4->as_text) =~ m!more\.\.\.!);
     print STDERR " +   try TABLE->FONT4 ===", $oFONT4->as_text, "===\n" if 1 < $self->{_debug};        
     $sDesc .= $oFONT4->as_text;

     my $hit = new WWW::Search::Result;
     $hit->add_url($sURL);
     $hit->title($sTitle);
     $hit->description($sDesc);
     #$hit->change_date($sDate);
     push(@{$self->{cache}}, $hit);
     $self->{'_num_hits'}++;
     $hits_found++;
     # Delete this HTML element so that future searches go faster!
     $oTABLE->detach;
     $oTABLE->delete;
   } # foreach TABLE

  # Look for a Next Page link:
  my @aoA = $tree->look_down('_tag', 'a');
 TRY_NEXT:
  foreach my $oA (reverse @aoA)
    {
    next TRY_NEXT unless ref $oA;
    print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
    my $href = $oA->attr('href');
    next TRY_NEXT unless $href;
    last TRY_NEXT if $href =~ m!JobDetail!;
    if ($oA->as_text =~ m!Next Page!i)
      {
      $self->{_next_url} = $self->absurl(undef, $href);
      print STDERR " +   got NEXT A ===", $self->{_next_url}, "===\n" if 1 < $self->{_debug};
      last TRY_NEXT;
      } # if
    } # foreach

  # All done with this page.
  $tree->delete;
  return $hits_found;
  } # parse_tree

1;

__END__

#####################################################################

=head1 NAME

WWW::Search::Jobserve - backend for searching www.jobserve.com

=head1 SYNOPSIS

    use WWW::Search;
    my $oSearch = new WWW::Search('Jobserve');
    my $sQuery = WWW::Search::escape_query("(Fast Food Operative) and PERL");
    $oSearch->native_query($sQuery, { job_category => 'it' });
    while (my $oResult = $oSearch->next_result())
      { 
        print $oResult->url, "\n"; 
        print $oResult->title, "\n";
        print $oResult->description, "\n";
      }

    			  	      
=head1 DESCRIPTION

This class is a Jobserve specialisation of WWW::Search.
It handles making, retrieving and interpreting Jobserve searches
F<http://www.jobserve.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

This class can be used to query both the UK and Australian Jobserve sites, see below.

The search will terminate unless C<job_category> is set in the native_query options.

The results are ordered Best Match first                    
   (unless 'job_order' => 'DateTime' is specified).

=head1 OPTIONS

=over

Parameters Available: 

F<job_category>
F<job_type>
F<job_lookahead>
F<job_order>
F<jobserve_site>

=item Job Category

Job Categories must be specified by setting C<job_category> 
in the native_query options:

  $oSearch->native_query($sQuery, { job_category => 'it' });
  
The value of this is simply the prefix you see jobserve insert
into the url once you've clicked beyond the front page. E.g.

  http://www.it.jobserve.com  		{ job_category => 'it' }
  http://www.engineering.jobserve.com   { job_category => 'engineering' }
  
etc. 

=item Job Type

Job Types are (Any|Contract|Permanent).
To specifically search for one contract type, 
set 'job_type' => (*|C|P) to the query options:

  $oSearch->native_query($sQuery, { job_type => 'C',  job_category => 'it' } );

The search defaults to C<All>
                         
=item Days Ahead

Choices of how many days to look ahead are (5|4|3|2|1|0).
To specifically search for x working days ahead, 
set 'job_lookahead' => (5|4|3|2|1|0) to the query options:

  $oSearch->native_query($sQuery, { job_lookahead => '2', job_category => 'it' } );
  
The search defaults to C<5>
  
=item Result Order

Choices of how to order results are (Best Match|Latest Job).
To alter the result order,
set 'job_order' => (Rank|DateTime) to the query options:

  $oSearch->native_query($sQuery, { job_order => 'DateTime', job_category => 'it' } );

The search defaults to C<Best Match>.
  
=item Different Jobserve Sites

There are currently two Jobserve websites supported by this module
namely United Kingdom and Australia.
  The search will default to the UK site unless the parameter, 
'jobserve_site' => (uk|au) is set in the query options:

  $oSearch->native_query($sQuery, { jobserve_site => 'au', job_category => 'it' } );
  
The search defaults to C<uk>  

=item 

Invoke all parameters like so:

    $oSearch->native_query($sQuery, { job_category  => 'it', 
    			  	      job_type 	    => 'C',
    			  	      job_lookahead => '2',
    			  	      job_order     => 'DateTime',
    			  	      jobserve_site => 'au', } );
    
=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Doubt it. Please tell me if you find any! Better still have a go at fixing them.

=head1 AUTHOR

C<WWW::Search::Jobserve> was written by Andy Pritchard
(pilchkinstein@hotmail.com).

C<WWW::Search::Jobserve> is maintained by Andy Pritchard

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

=head2 1.02

Altered parse_tree for cases where another href link is inserted before 
the job title and link

=head2 1.01

Altered POD and added a README

=head2 1.00

Released to the public.

=cut

#####################################################################