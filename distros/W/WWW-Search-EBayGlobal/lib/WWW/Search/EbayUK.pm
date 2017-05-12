# EbayUK.pm
# Adapted by Andy Pritchard. Original Ebay backend by Martin Thurn 
# $Id: EbayUK.pm,v 3.00 2003-03-18 15:00:00 Exp  $

package WWW::Search::EbayUK;

@ISA = qw( WWW::Search );

use WWW::Search qw( generic_option strip_tags );
use WWW::Search::Result;

$VERSION = '3.00';
$MAINTAINER = 'Andy Pritchard <pilchkinstein@hotmail.com>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  
  # Set some private variables:
  $self->{_debug} ||= $rhOptsArg->{'search_debug'};
  $self->{_debug} = 2 if ($rhOptsArg->{'search_parse_debug'});
  $self->{_debug} ||= 0;

  my $seBay_site = $rhOptsArg->{'ebay_site'};
  $seBay_site ||= 'uk'; 		# Default to English site
  my $sWorld_Wide = $rhOptsArg->{'World_Wide'};
  $sWorld_Wide ||= '2'; 		# Default to local site
  ($sWorld_Wide =~ /y/i) ? ($sWorld_Wide = 3) : ($sWorld_Wide = 2);

  
  %Country_Params = ( uk => 'search.ebay.co.uk',
  		      at => 'cq-search.ebay.at',
    		      au => 'search.ebay.com.au',
  		    # be => is a little tricky since it has the french or netherland variant
  		      ca => 'search.ebay.ca',  		    
  		      ch => 'cq-search.ebay.ch',
   		      de => 'search.ebay.de',
 		      fr => 'search.ebay.fr',
  		      us => 'search.ebay.com',
  		    ) ;
  
  my $DEFAULT_HITS_PER_PAGE = 50;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE;

  $self->user_agent('non-robot');

  $self->{'_next_to_retrieve'} = 0;
  $self->{'_num_hits'} = 0;
  $self->{'_base_url'} = "http://$Country_Params{$seBay_site}";
  
  print STDERR " + Country_Params:Site=>\'$seBay_site\':URL=>\'$self->{'_base_url'}\'\n" if 1 < $self->{_debug};

  if (!defined($self->{_options}))
    {
    $self->{_options} = {
                         'search_url' 	=> $self->{'_base_url'} . '/search/search.dll',
                         'MfcISAPICommand' => 'GetResult',
                         'ht' 		=> 1,
                         # Default sort order is reverse-order of listing date:
                         'SortProperty' => 'MetaNewSort',
                         'shortcut'	=> $sWorld_Wide,  # Whether we search worldwide or not set 3 or 2
                         'query' 	=> $native_query,
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
        # print STDERR "promote & delete\n";
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

  # Finally, figure out the url. With extra option to just go for the url supplied.
    if (defined($self->{_options}->{'follow_link'}))
    {
      print STDERR " + follow_link -->",$self->{_options}->{'follow_link'}, "<--\n" if 1 < $self->{_debug};
      $self->{_next_url} = $self->{_options}->{'follow_link'};
    }else{
      $self->{_next_url} = $self->{_options}->{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
    }
  } # native_setup_search


sub preprocess_results_page
  {
  my $self = shift;
  my $sPage = shift;
  # Ebay sends malformed HTML:
  my $iSubs = 0 + ($sPage =~ s!</FONT></TD></FONT></TD>!</FONT></TD>!gi);
  print STDERR " +   deleted $iSubs extraneous tags\n" if 1 < $self->{_debug};
  print STDERR " + RawHTML ===>$sPage<=== RawHTML\n" if 2 < $self->{_debug};
  return $sPage;
  } # preprocess_results_page

package WWW::SearchResult;  # Adding new details method
sub details { return shift->_elem('details', @_); }
package WWW::Search::EbayUK;

# private
sub parse_tree
  {
  my $self = shift;
  my $tree = shift;

  # A pattern to match HTML whitespace:
  my $W = q{[\ \t\r\n\240]};
  # A pattern to match Ebay currencies:
  my $currency = qr/(?:\$|C|EUR|GBP|\£|CHF|\€|AUD|AU)/;
  # One to match time zones for the end date
  my $time_zone = qr/(?:GMT|MEZ|Paris|PST|AEDST|EST)/;
  # One to match the next tag
  my $next_tag = qr/(?:Next|Nächste|Suivante)/;
  my $hits_found = 0;
  if (2 < $self->{_debug}) {
  	print STDERR "=========================== HTML::Tree Dump START ============================\n";
  	print STDERR $tree->as_HTML();
  	print STDERR "============================ HTML::Tree Dump END =============================\n";
  }
  # The hit count is in a FONT tag:
  my @aoFONT = $tree->look_down('_tag', 'font');
  if (defined($self->{_options}->{'follow_link'}))
  {
    my($oDetails) = {}; # We can put what we want in here now 'thumbnail' 'Start' 'End' so far
    my($s_nextdate,$sTitle2);   
    my @aoTD2 = $tree->look_down('_tag', 'td');
    my @aoIMG2 = $tree->look_down('_tag', 'img');
    
  FONT_2:
    foreach my $oFONT2 (@aoFONT)
    # If we run through the retrieve html step, the stuff we want is in here.
    {
      print STDERR " +   try FONT_2 as_text ===", $oFONT2->as_text, "===\n" if 1 < $self->{_debug};
      $sTitle2 = $oFONT2->as_text unless ($sTitle2);# The first font entry is the title
      foreach my $pDATE ('Start','End') # Alter the spelling here if ebay change it. Shouldnt be needed.
      {
        $s_nextdate = $pDATE if ($oFONT2->as_text =~ /${pDATE}/);
        if (($oFONT2->as_text =~ m!(\w+(?:\.|\-)\w+(?:\.|\-)\d+\s*\d+:\d+:\d+\s*$time_zone)!) and ($s_nextdate))
        { 
          next FONT_2 if (defined($oDetails->{$s_nextdate}));  
          $oDetails->{$s_nextdate} = $1;
          if (1 < $self->{_debug})
          {
	    print STDERR " + Trying to match \'$s_nextdate\'\n";
            print STDERR " == Got a Date ==>${1}\n";
            print STDERR " == Now \$oDetails->{\'$s_nextdate\'} ==>", $oDetails->{$s_nextdate}, "\n";
          } 
        }   
      }
      ## Deleting HTML element so that future searches go faster!
      $oFONT2->detach;
      $oFONT2->delete;
      ## Need to fill what we can of these when we get this far 
    } # foreach FONT_2 
  
  IMG_2:
    foreach my $oIMG2 (@aoIMG2)
    {
      my $sIMG = $oIMG2->as_HTML;
      chomp($sIMG);
      print STDERR " +   try IMG_2 as_HTML ===$sIMG===\n" if 1 < $self->{_debug};
      if (($sIMG =~ /border=1/) and ($sIMG =~ /width=\d\d\b/) and ($sIMG =~ /height=\d\d\b/))
      { 
        $sIMG =~ s/.*src=\"(.*)\".*/$1/;
        print STDERR " == Got a Thumbnail =>$sIMG<=\n" if 1 < $self->{_debug}; 
        $oDetails->{'thumbnail'} = $sIMG;
      }
    } # foreach IMG_2
    
    my $hit = new WWW::Search::Result;
    $hit->title($sTitle2);	# There's really no need to send this since you should have it from page 1.
    #$hit->description($sDesc);
    $hit->details($oDetails);	# This contains extra keys 'thumbnail','Start','End' 
    $hit->raw($tree->as_HTML);	# This is new to this Backend
    push(@{$self->{cache}}, $hit);
    $hits_found++;
    
    # Finished with this page now, no next to follow.  
    $tree->delete;
    return $hits_found;
 } # if follow_link defined
     
 FONT:
  foreach my $oFONT (@aoFONT)
    {
    print STDERR " +   try FONT ===", $oFONT->as_text, "===\n" if 1 < $self->{_debug};
    # If we run through the retrieve html step, the stuff we want is in here.
    
    if ($oFONT->as_text =~ m!(\d+) items found !)
        {
        $self->approximate_result_count($1);
        last FONT;
        } # if
    } # foreach
   
  # The list of matching items is in a table.  The first column of the
  # table is nothing but icons; the second column is the good stuff.
  my @aoTD = $tree->look_down('_tag', 'td',
                              sub { (
                                     ($_[0]->as_HTML =~ m!ViewItem! )
                                     &&
				     # Ignore thumbnails:
                                     ($_[0]->as_HTML !~ m!thumbs\.ebay\.! )
                                     &&
                                     # Ignore other images:
                                     ($_[0]->as_HTML !~ m/alt="\[Picture!\]"/i )
                                     &&
                                     ($_[0]->as_HTML !~ m/alt="\[Bild!\]"/i )
                                     &&
                                     ($_[0]->as_HTML !~ m!alt="buyItNow"!i )
                                    )
                                  }
                             );
 TD:
  foreach my $oTD (@aoTD)
    {
    my $sTD = $oTD->as_HTML;
    # First FONT tag contains the url & title:
    my $oFONT = $oTD->look_down('_tag', 'font');
    next TD unless ref $oFONT;
    # First A tag contains the url & title:
    my $oA = $oFONT->look_down('_tag', 'a');
    next TD unless ref $oA;
    my $sURL = $oA->attr('href');
    next TD unless $sURL =~ m!ViewItem!;
    my $sTitle = $oA->as_text;
    print STDERR " + TD ===$sTD===\n" if 1 < $self->{_debug};
    my ($iItemNum) = ($sURL =~ m!item=(\d+)!);
    my ($iPrice, $iBids, $sDate) = ('$unknown', 'no', 'unknown');
    # The rest of the info about this item is in sister TD elements to
    # the right:
    my @aoSibs = $oTD->right;
    # The next sister has the current bid amount (or starting bid):
    my $oTDprice = shift @aoSibs;
    if (ref $oTDprice)
      {
      if (1 < $self->{_debug})
        {
        my $s = $oTDprice->as_HTML;
        print STDERR " +   TDprice ===$s===\n";
        } # if
      $iPrice = $oTDprice->as_text;
      $iPrice =~ s!(\d)$W*($currency$W*[\d.,]+)!$1 (Buy-It-Now for $2)!;
      } # if
    # The next sister has the number of bids:
    my $oTDbids = shift @aoSibs;
    if (ref $oTDbids)
      {
      if (1 < $self->{_debug})
        {
        my $s = $oTDbids->as_HTML;
        print STDERR " +   TDbids ===$s===\n";
        } # if
      $iBids = $oTDbids->as_text;
      } # if
    # Bid listed as hyphen means no bids:
    $iBids = 'no' if $iBids =~ m!\A$W*-$W*\Z!;
    # Bid listed as whitespace means no bids:
    $iBids = 'no' if $iBids =~ m!\A$W*\Z!;
    my $sDesc = "Item \043$iItemNum; $iBids bid";
    $sDesc .= 's' if $iBids ne '1';
    $sDesc .= '; ';
    $sDesc .= 'no' ne $iBids ? 'current' : 'starting';
    $sDesc .= " bid $iPrice";
    # The last sister has the auction start date:
    my $oTDdate = pop @aoSibs;
    if (ref $oTDdate)
      {
      my $s = $oTDdate->as_HTML;
      print STDERR " +   TDdate ===$s===\n" if 1 < $self->{_debug};
      $sDate = $oTDdate->as_text;
      } # if
    my $hit = new WWW::Search::Result;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    $hit->change_date($sDate);
    $hit->raw($oTD->as_HTML);	# This is new to this Backend
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    # Delete this HTML element so that future searches go faster!
    $oTD->detach;
    $oTD->delete;
    } # foreach

  # Look for a NEXT link:
  my @aoA = $tree->look_down('_tag', 'a');
 TRY_NEXT:
  foreach my $oA (reverse @aoA)
    {
    next TRY_NEXT unless ref $oA;
    print STDERR " +   try NEXT A ===", $oA->as_HTML, "===\n" if 1 < $self->{_debug};
    my $href = $oA->attr('href');
    next TRY_NEXT unless $href;
    # If we get all the way to the item list, there must be no next
    # button:
    last TRY_NEXT if $href =~ m!ViewItem!;
    if ($oA->as_text =~ m!$next_tag$W+(>|&gt;)!i)
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

WWW::Search::EbayUK - backend for searching www.ebay.co.uk and european eBay sites

=head1 SYNOPSIS

    use WWW::Search;
    my $oSearch = new WWW::Search('EbayUK');
    my $sQuery = WWW::Search::escape_query("Bovine Spongiform Encephalitis");
    $oSearch->native_query($sQuery);
    while (my $oResult = $oSearch->next_result())
      { 
        print $oResult->url, "\n"; 
        print $oResult->title, "\n";
        print $oResult->description, "\n";
      }

=head1 DESCRIPTION

This class is a Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.co.uk>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The search is done against CURRENT running auctions only.

The query is applied to TITLES only. See below for retrieving html from links.

The results are ordered youngest auctions first (reverse order of
auction listing date).

In the resulting WWW::Search::Result objects, the description field
consists of a human-readable combination (joined with semicolon-space)
of the Item Number; number of bids; and high bid amount (or starting
bid amount).

Extra information is available by C<following> the links returned by:

  $oResult->url 

In such an instance extra information is returned 
that is not normally accessible from the result page.
To cater for this, an extra I<details> method is introduced:

  $oResult->details
  
Which stores the extra information in a hash.

=head1 OPTIONS

=over

=item Search descriptions

To search titles and descriptions, add 'srchdesc' => 'y' to the query options:

  $oSearch->native_query($sQuery, { srchdesc => 'y' } );
  
=item Other Ebay Sites

As of version 3.00 WWW::Search::EbayUK can be used to search the following european ebay sites
 F<http://www.ebay.co.uk>	 (United Kingdom)
 F<http://www.ebay.at>		 (Austria)
 F<http://www.ebay.com.au>	 (Australia)
 F<http://pages.ca.ebay.com> (Canada)
 F<http://www.ebay.ch>		 (Switzerland)
 F<http://www.ebay.de>		 (Germany)
 F<http://pages.ebay.fr>	 (France)
 F<http://www.ebay.com>	 (United States)

The search defaults to the UK website but the other sites above can be queried by setting
 C<ebay_site> = (at|au|ca|ch|de|fr|us) 
in the native_query options:

  $oSearch->native_query($sQuery, { ebay_site => 'at' } );

=item World-Wide Searches

To search across the world, set C<World_Wide> = 'y' in the query options:

  $oSearch->native_query($sQuery, { World_Wide => 'y' } );

The search defaults to '2' which is the local website.

=item Following Links

To retrieve information from a specific ebay link, 
add 'follow_link' => '<http:// full URL>' to the query options:

  $sURL = '<http:// full URL>';
  $oSearch->native_query($sURL, { follow_link => "$sURL" } );
  
No escaping is required in this case.
  
=item Information From Followed Links

Extra information is returned by this process. 
(Auction Start and End dates are a case in point.)
Query the $oResult->details hash to retrieve this.      
E.g. the start date of the auction is retrieved like so:

  print $oResult->details->{'Start'}, "\n";

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 INTENDED

The Belgian site has an extra layer to allow users to select Netherlands or France.
It would be nice to be able to incorporate a workaround in future releases. 

=head1 BUGS

Doubt it. Please tell me if you find any!

=head1 AUTHOR

C<WWW::Search::EbayUK> was Adapted by Andy Pritchard from Martin Thurn's Ebay module
(pilchkinstein@hotmail.com).

Original C<WWW::Search::Ebay> was written by Martin Thurn
(mthurn@megapipe.net).

C<WWW::Search::EbayUK> is maintained by Andy Pritchard

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

=head2 3.00, 18-03-2003

Added C<ebay_site> and C<World_Wide> functionality 
to allow use of this module with other e-Bay websites.

=head2 2.01, 17-03-2003
 
Altered Makefile.PL Prerequisites

=head2 2.00, 2003-02-26

Added C<follow_link> functionality and new I<details> method.
This also supports the I<raw> and I<title> calls.

=head2 1.00, 2003-02-14

Adapted Ebay module for ebay.co.uk site

=head2 2.13, 2003-02-06

Fixed parsing for slightly-changed ebay.com pages

=head2 2.11, 2002-10-21

Fixed parsing for Buy-It-Now prices, and foreign currencies

=head2 2.08, 2002-07-24

Fixed parsing for new images in the results table

=head2 2.07, 2001-12-20

Restructured using parse_tree()

=head2 2.06, 2001-12-20

Handle new ebay.com output format

=head2 2.01

First publicly-released version.

=cut

#####################################################################