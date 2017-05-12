#!/usr/local/bin/perl 

=head1 NAME

WebService::GoogleHack::Search - This module is used to query Google.

=head1 SYNOPSIS

    use WebService::GoogleHack::Search;

    #create an object of type search
    my $search = GoogleHack::Search->new();

    #Query Google.
    $search->searchPhrase($searchString);
  
    #The results variable will now contain the results of your query.

    #Printing the searchtime

    print "\n Search Time".$search->{'searchTime'};

    #Printing the snippet element 0

    print "\n\nSnippet".$search->{'snippet'}->[0];

=head1 DESCRIPTION

This module provides a simple interface to the Google API. It is used by the GoogleHack module.

=head1 PACKAGE METHODS

=head2 _METHOD__->new()

Purpose: This function creates an object of type Search and returns a blessed 
reference.

=head2 _METHOD__->init(key,wsdl_location)

Purpose: This this function can used to inititalize the member variables.

Valid arguments are :

=over 4

=item *

B<key>

I<string>. key to the google-api

=item *

B<wsdl_location>

I<string>.  This the wsdl file name

=back

=head2 _METHOD__->Search(searchString,num_results,integer)

Purpose: This function is used to query googles 

Valid arguments are :

=over 4

=item *

B<searchString> 

I<string>.  Need to pass the search string, which can be a single word or 
phrase, maximum ten words

=item *

B<num_results> 

I<integer>. The number of results you wast to retrieve, default is 10. 
Maximum is 1000. Give in terms of multiples of ten.


=back

Returns: Returns a Search object containing the search results.

=head2 _METHOD__->getEstimateNo()

Purpose: This function returns the number of results predicted by google for a specific search term.


No Valid arguments.

=over 4

=back

Returns: Returns the total number of results for a search string..

=head2 _METHOD__->IamFeelingLucky()

Purpose: This function imitates the "I am Feeling Lucky" search feature of 
Google. It basically returns the URL of the first result of your search.

No Valid arguments.

=over 4

=back

Returns: Returns the URL of the first result of your search.

=head2 _METHOD__->getCachedPage()

Purpose: This function retrieves a cached webpage, given the URL.

No Valid arguments.

=over 4

=back

Returns: Returns the contents of as web page given a URL.

=head1 AUTHOR

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt>

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt>

=head1 BUGS

=head1 SEE ALSO

GoogleHack home page - http://google-hack.sourceforge.net

Pratheepan Raveendranathan - http://www.d.umn.edu/~rave0029/research

Ted Pedersen - www.d.umn.edu./~tpederse

Google-Hack Maling List E<lt>google-hack-users@lists.sourceforge.netE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by Pratheepan Raveendranathan, Ted Pedersen

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

package WebService::GoogleHack::Search;

our $VERSION = '0.15';
use SOAP::Lite;


sub new
{
my $this = {};

$this-> {'Key'} = undef;
$this-> {'File_Location'} = undef;
$this-> {'yahooid'}=undef;
$this-> {'maxResults'} =10;
$this-> {'StartPos'} =0;
$this-> {'Filter'} ="false";
$this-> {'Restrict'} ="";
$this-> {'safeSearch'} ="false";
$this-> {'lr'} ="";
$this-> {'oe'} ="";
$this-> {'ie'} ="";
$this-> {'NumResults'} = undef;
$this-> {'snippet'} = undef;
$this-> {'searchTime'} = undef;
$this-> {'url'} = undef;
$this-> {'cachedPage'} = undef;
$this-> {'title'} = undef;


bless $this;

return $this;
}




sub init
{
my $this = shift;

$this->{'Key'} = shift;
$this->{'File_Location'} = shift;
$this-> {'yahooid'}= shift;
$this-> {'maxResults'} =shift;
$this-> {'StartPos'} =shift;
$this-> {'Filter'} =shift;
$this-> {'Restrict'} =shift;
$this-> {'safeSearch'} =shift;
$this-> {'lr'} =shift;
$this-> {'oe'} =shift;
$this-> {'ie'} =shift;

}

# this functions sets the maximum number of results retrived
sub setMaxResults
{
    my $this = shift;
    $maxResults = shift;

    $this-> {'maxResults'} =$maxResults;


}


sub setlr
{
    my $this = shift;
    $lr = shift;

    $this-> {'lr'} =$lr;


}

sub setoe
{
    my $this = shift;
    $oe = shift;

    $this-> {'oe'} =$oe;


}

sub setie
{
    my $this = shift;
    $ie = shift;

    $this-> {'ie'} =$ie;


}

sub setStartPos
{
    my $this = shift;
    $StartPos = shift;

    $this-> {'StartPos'} =$StartPos;


}

sub setFilter
{
    my $this = shift;
    $Filter = shift;

    $this-> {'Filter'} =$Filter;


}

sub setRestrict
{
    my $this = shift;
    $Restrict = shift;

    $this-> {'Restrict'} =$Restrict;


}

sub setSafeSearch
{
    my $this = shift;
    $Restrict = shift;

    $this-> {'Restrict'} =$Restrict;


}

sub searchPhrase
{
    my $searchInfo=shift;
    my $searchString=shift;
    my $num_results=shift;
    @snippet_array=();
    @url_array=();
    @title_array=();

    $count1=0;
    $count2=0;
    $count3=0;

    if(!defined($num_results))
    {
	$num_results=10;
    }

    print ".";
    $key  = $searchInfo->{'Key'}; 
    $wsdl_path =$searchInfo->{'File_Location'}; 

    
    print "\n Key is $key";
    print "\n path is $wsdl_path";
    print "\n Search phrase is $searchString\n";
#    print  $searchInfo-> {'StartPos'};
    
# Initialise with local SOAP::Lite file
    

open(WSDL,"$wsdl_path") || die("\n\n\n\nIllegal WSDL File Location : $wsdl_path\n\n\n\n");
close(WSDL);

$service = SOAP::Lite
    -> service("file:$wsdl_path");

$count=0;
   $searchInfo-> {'lr'}="lang_en";
 
while( $count < $num_results)

{
$result =  $service -> doGoogleSearch(
		      $key,                               # key
		      $searchString,                      # search query
		      $searchInfo-> {'StartPos'} + $count,# start results
		      $searchInfo-> {'maxResults'},       # max results
		      $searchInfo-> {'Filter'},           # filter: boolean
		      $searchInfo-> {'Restrict'},         # restrict (string)
		      $searchInfo-> {'safeSearch'},       # safeSearch: boolean
		      $searchInfo-> {'lr'},               # lr
		      $searchInfo-> {'oe'},               # ie
		      $searchInfo-> {'ie'}                # oe
		      );

foreach $temp (@{$result->{resultElements}}) {
  
 

    if(defined($temp->{URL}))
    {
	$url_array[$count2++]=$temp->{URL};      
    }
    else
    {
	$url_array[$count2++]="Undefined URL";
	
    }
    

    if(defined($temp->{title}))
    {
	$title_array[$count3++]=$temp->{title};
    }
    else
    { 
	$title_array[$count3++]="Undefined Title";
    }


    if(defined($temp->{snippet}))
    {
	$snippet_array[$count1++]=$temp->{snippet};
    }
    else
    { 
	$snippet_array[$count1++]="Undefined Snippet";
    }

#print "\n\n",$temp->{title};
#print "\n", $temp->{snippet};
#print "\n",$temp->{URL};


}


$count=$count+10;

}

$this->{'NumResults'} = $result->{estimatedTotalResultsCount};
$this->{'searchTime'} = $result->{searchTime};
$this->{'snippet'} = \@snippet_array;
$this->{'url'}=\@url_array;
$this->{'title'}=\@title_array; 

return $this;


}


sub getEstimateNo
{
    my $this = shift;

return   $this-> {'NumResults'};

}

sub IamFeelingLucky
{
   my $this = shift;
   return   $this->{'url'}->[0];
   
}



sub getCachedPage
{
    my $searchInfo=shift;
    $url=shift;
    
    $key  = $searchInfo->{'Key'}; 
    $wsdl_path =$searchInfo->{'File_Location'}; 
    
    
    $service = SOAP::Lite
	-> service("file:$wsdl_path");
    
    $cached = $service->doGetCachedPage($key,$url);
    
    #  print "\n\nDid you mean: $correction \n";
    if($cached)
    {
	require WebService::GoogleHack::Text;
	$cached=WebService::GoogleHack::Text::removeHTML($cached);
    }

    if($cached)
    {  
	$this-> {'cachedPage'} = $cached;
	return $cached;
    }
    
    
}



# remember to end the module with this
1;













