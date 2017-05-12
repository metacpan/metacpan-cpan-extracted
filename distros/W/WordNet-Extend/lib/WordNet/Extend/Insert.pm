# WordNet::Extend::Insert.pm version 0.030
# Updated: 10/13/16
#                                           
# Ted Pedersen, University of Minnesota Duluth             
# tpederse at d.umn.edu
#
# Jon Rusert, University of Minnesota Duluth
# ruse0008 at d.umn.edu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package WordNet::Extend::Insert;

=head1 NAME

WordNet::Extend::Insert - Perl module for inserting a lemma into 
WordNet.

=head1 SYNOPSIS

=head2 Basic Usage Example

 use WordNet::Extend::Insert;

 my $insert = WordNet::Extend::Insert->new();

 @in1 = ("crackberry","noun","withdef.1", "A BlackBerry, a handheld device considered addictive for its networking capability.");    

 @in2 = ("slackberry","noun","withdef.2", "A mocking name for crackberry.");

 @loc1 = ("withdef.5","cellphone#n#1");

 @loc2 = ("withdef.6","crackberry#n#1");

 $insert->attach(\@in1, \@loc1);

 $insert->merge(\@in2, \@loc2);

=head1 DESCRIPTION

=head2 Introduction

WordNet is a widely used tool in NLP and other research areas. A drawback of WordNet is the amount of time between updates. WordNet was last updated and released in December, 2006, and no further updates are planned. WordNet::Extend::Insert aims to allow developers insert their own lemmas into WordNet which can help keep WordNet updated with new language in the world. It can also revert back to the original untouched WordNet (by calling restoreWordNet) if the user makes a mistake or simply wants the untouched WordNet to access.

=over
=cut

use WordNet::QueryData;
use Getopt::Long;
use File::Spec;
use File::Copy;
use File::Find;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);

%EXPORT_TAGS = ();

@EXPORT_OK = ();

@EXPORT = ();

$VERSION = '0.030';

#**************Variables**********************
$wn = WordNet::QueryData->new; #to be used to access data from wordnet
$WNHOME = "/usr/local/WordNet-3.0";
$WNSEARCHDICT = "$WNHOME/dict";
$wnCRLength = 29; #number of lines the copyright takes up in data.pos and index.pos.
#*********************************************

GetOptions('help' => \$help);
if($help == 1)
{
    printHelp();
    exit(0);
}

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=item $obj->new()

The constructor for WordNet::Extend::Insert objects.

Parameters: none.

Return value: the new blessed object

=cut

sub new
{
    my $class = shift;
    my $self = {};

    $self->{errorString} = '';
    $self->{error}=0;

    bless $self, $class;
    
    return $self;
}

=item $obj->getError()

Allows the object to check if any errors have occurred.
Returns an array ($error, $errString), where $error 
value equal to 1 represents a warning and 2 represents
an error with the requested commands. (If a user would
run attach() without enough arguments, the error code 
would return 2). $errorString contains what error occurred.

Parameter: None

Returns: array of the form ($error, $errorString).

=cut
sub getError()
{
    my $self = shift;
    my $error = $self->{error};
    my $errString = $self->{errorString};
    $self->{error}=0;
    $self->{errorString} = "";
    $errString =~ s/^[\r\n\t ]+//;
    return ($error, $errString);
}

=item $obj->attach($newSynset, $location)

Takes in a new synset and inserts it into WordNet at the specified location
by attaching it to the specified location lemma as a hyponym. The location should
be represented by "lemma#pos#senseNum". For example, to attach to the 2nd sense
of the noun window, the location would be "window#n#2".

Parameters: Synset array in form (lemma, part-of-speech, item-id, definition)
or "word\tpos\titem-id\tdef", and location to be inserted in form  
(item-id, WordNet sense).

Returns: nothing

=cut
sub attach()
{
    #need to load in new QueryData
    $wn = WordNet::QueryData->new;
    my $base = 0; 
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }
    
    my @newSyn = @{$_[$base]};
    $base = $base +1;
    if(scalar @newSyn == 1) #in second form
     {
	my @tempSyn = split("\t", $newSyn[0]);
	@newSyn = @tempSyn;
    }
    my $pos = substr($newSyn[1], 0, 1);
    my @location = @{$_[$base]};
    my $write = 1; #write flag changes to 0 if error occurs so no write() will occur.

    if(scalar @newSyn < 4)
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "New synset does not contain enough elements.";
	$write = 0;
    }
    
    if(scalar @location < 2)
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "Location does not contain enough elements.";
	$write = 0;
    }

    unless (defined $wn->offset("$location[1]"))
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "Location does not exist in WordNet.";
	$write = 0;
    }

    if($write == 1)
    {
       	my $newOffset = findNewOffset($newSyn[1]);
	my %CRNotice;
	my %DataSpace;
	my %offsetMap; #used to stored changes in offsets.
	my $indexPos = "";
	my $dataPos = "";
	my $indexSense = "";
	my $posNum = 0;
	my $locationLemma = $location[1];
	$locationLemma =~ s/#.*//; #extract lemma
	my $locationPos = $newSyn[1]; #must be same pos as new.
	my $locationOffset = $wn->offset("$location[1]");
	while(length($locationOffset) < 8) #QueryData->offset() does not keep the 8 digits, need to add back lost 0's
	{
	    $locationOffset = "0".$locationOffset;
	}
	my $indexFile = "$WNSEARCHDICT/index.$locationPos";
	my $dataFile = "$WNSEARCHDICT/data.$locationPos";
	my $senseFile = "$WNSEARCHDICT/index.sense";
	open (WNINDEXNEW, '>', "$indexFile.new") or die $!;
	open (WNDATANEW, '>', "$dataFile.new") or die $!;
	open (WNSENSENEW, '>', "$senseFile.new") or die $!;

	#make filehandles hot
	my $fhIndex = select(WNINDEXNEW);
	$|=1;
	select($fhIndex);

	my $fhData = select(WNDATANEW);
	$|=1;
	select($fhData);

	my $fhSense = select(WNSENSENEW);
	$|=1;
	select($fhSense);
       	
	if($pos eq "n")
	{
	    $posNum = 1;
	}
	else 
	{
	    if($pos eq "v")
	    {
		$posNum = 2;
	    }
	    else
	    {
		my $self = shift;
		$self->{error} = 2;
		$self->{errorString} = "Part of speech must be verb or noun";
		$write = 0;
	    }
	}
	

	if(isNewWord($newSyn[0], $newSyn[1]) == 0)
	{
	    my %hypData = %{getDataInfo($locationOffset, $locationPos)};
	    my %hypInfo = %{getIndexInfo($locationLemma, $locationPos)};
	    #print from three required files.
	    open WNINDEX, "$indexFile" or die $!;
	    open WNDATA, "$dataFile" or die $!;
	    open WNSENSE, "$senseFile" or die $!;
	    open (WNDATATEMP, '>', "$dataFile.temp") or die $!;
	    
	    my $changed = 0;
	    my $curLine = 1;
	    while(<WNDATA>)
	    {
		for $tempIn (split("\n"))
		{
		    my $spaceTmp = $tempIn;
		    $spaceTmp =~ /( *)$/;
		    $DataSpace{$curLine} = length($1);
		    if($curLine > $wnCRLength)
		    {
			my @tempLine = split /\s/, $tempIn;
			if($changed == 1)
			{
			    my $newNewOffset = $tempLine[0] +18;
			    while(length($newNewOffset) < 8)
			    {
				$newNewOffset = "0".$newNewOffset;
			    }
			    $offsetMap{$tempLine[0]} = $newNewOffset;
			}
			else
			{
			    $offsetMap{$tempLine[0]} = $tempLine[0];
			}
			
			if($tempLine[0] == $locationOffset)
			{
			    my $newPcnt = $hypData{'p_cnt'} + 1;
			    while(length $newPcnt < 3)#needs to be represented by 3 digits.
			    {
				$newPcnt = "0".$newPcnt;
			    }
			    $newOffset = $newOffset + 18; #18 is the length of new data being added.
			    $tempIn = "$hypData{'synset_offset'} $hypData{'lex_filenum'} $hypData{'ss_type'} $hypData{'w_cnt'} $hypData{'word_lex_id'} $newPcnt $hypData{'ptr'} ~ $newOffset $pos 0000 | $hypData{'gloss'}";
			    $changed = 1;
			}
		    }
		    else
		    {
			$CRNotice{$curLine} = $tempIn;
		    }

		    $curLine+=1;
		    
		    print WNDATATEMP "$tempIn\n";
		}
	    }

	    $indexPos ="$newSyn[0] $pos 1 1 \@ 1 0 $newOffset";
	    $dataPos = "$newOffset $hypData{'lex_filenum'} $pos 01 $newSyn[0] 0 001 \@ $hypData{'synset_offset'} $pos 0000 | $newSyn[3]"; 
	    $indexSense = "$newSyn[0]%$posNum:$hypData{'lex_filenum'}:00:: $newOffset 1 0";

	    close WNDATATEMP;
	    open WNDATATEMP, "$dataFile.temp" or die $!;

	    $curLine = 1;
	    while(<WNDATATEMP>)
	    {
		for $tempIn (split("\n"))
		{
		    my @tempLine = split /\s/, $tempIn;
		    for my $i (0 .. $#tempLine)
		    {
			if(exists $offsetMap{$tempLine[$i]})
			{
			    $tempLine[$i] = "$offsetMap{$tempLine[$i]}";
			}
			
		    }
		    $tempIn = join(' ', @tempLine);
		    		    	    	
		    if($curLine > $wnCRLength)
		    {
			for($i=1; $i <= $DataSpace{$curLine}; $i++)
			{
			    $tempIn = $tempIn . " ";
			}
			print WNDATANEW "$tempIn\n";
		    }
		    else
		    {
			print WNDATANEW "$CRNotice{$curLine}\n";
		    }
		    $curLine+=1;
		}
	    }
	    print WNDATANEW "$dataPos  \n";

	    $curLine = 1;
	    $alpha = 1;
	    while(<WNINDEX>)
	    {
		for $tempIn (split("\n"))
		{
		    if($curLine > $wnCRLength)
		    {
			#need to add hyponym pointer if it did not exist before on hypernym
			if($tempIn =~ /^$locationLemma\b[^-]/)
			{
			    unless($tempIn =~ /\~/)
			    {
				my $newPcnt = $hypInfo{'p_cnt'};
				$newPcnt+=1;
				$tempIn ="$hypInfo{'lemma'} $hypInfo{'pos'} $hypInfo{'synset_cnt'} $newPcnt $hypInfo{'ptr_symbol'} ~ $hypInfo{'sense_cnt'} $hypInfo{'tagsense_cnt'} $hypInfo{'synset_offset'}";
			    }
			}

			my @tempLine = split /\s/, $tempIn;
			
			#add in $indexPos alphabetically
			if($alpha == 1)
			{
			    if(($tempLine[0] cmp $newSyn[0]) == 1 )
			    {
				print WNINDEXNEW "$indexPos  \n";
				$alpha = 0;
			    }
			}
			
			my $tmpPcnt = $tempLine[2];
			my $offsetPtr = scalar(@tempLine) - 1;
			while($tmpPcnt > 0)
			{
			    if(exists $offsetMap{$tempLine[$offsetPtr]})
			    {
				$tempLine[$offsetPtr] = "$offsetMap{$tempLine[$offsetPtr]}";
			    }
			    $tmpPcnt-=1;
			    $offsetPtr-=1;
			}
			$tempIn = join(' ', @tempLine);
								
		    }
		    else
		    {
			$curLine+=1;
		    }
		    print WNINDEXNEW "$tempIn   \n";
		}
	    }

	    $alpha = 1;
	    while(<WNSENSE>)
	    {
		for $tempIn (split("\n"))
		{
		    
		    my @tempLine = split /\s/, $tempIn;
		    #add in $indexSense alphabetically
		    if($alpha == 1)
		    {
			if(($tempLine[0] cmp $newSyn[0]) == 1 )
			{
			    print WNSENSENEW "$indexSense\n";
			    $alpha = 0;
			}
		    }
		    
		    if(exists $offsetMap{$tempLine[1]})
		    {
			$tempLine[1] = "$offsetMap{$tempLine[1]}";
		    }
		    $tempIn = join(' ', @tempLine);
		    
		    print WNSENSENEW "$tempIn\n";
		}
	    }
	    
	    close WNINDEX;
	    close WNDATA;
	    close WNSENSE;
	    close WNDATATEMP;
	}
	else #lemma already exists
	{
	    my %hypData = %{getDataInfo($locationOffset, $locationPos)};
	    my %hypInfo = %{getIndexInfo($locationLemma, $locationPos)};
	    my %lemmaIndex = %{getIndexInfo($newSyn[0], $newSyn[1])};
	    my $newSynNum = $lemmaIndex{'synset_cnt'} + 1;
	    	    	    
	    #print to three required files.
	    open WNINDEX, "$indexFile" or die $!;
	    open WNDATA, "$dataFile" or die $!;
	    open WNSENSE, "$senseFile" or die $!;
	    open (WNDATATEMP, '>', "$dataFile.temp") or die $!;
	    
	    my $changed = 0;
	    my $curLine = 1;
	    while(<WNDATA>)
	    {
		for $tempIn (split("\n"))
		{
		    my $spaceTmp = $tempIn;
		    $spaceTmp =~ /( *)$/;
		    $DataSpace{$curLine} = length($1);
		    if($curLine > $wnCRLength)
		    {
			my @tempLine = split /\s/, $tempIn;	    	    	    
			if($changed == 1)
			{
			    my $newNewOffset = $tempLine[0] +18;
			    while(length($newNewOffset) < 8)
			    {
				$newNewOffset = "0".$newNewOffset;
			    }
			    $offsetMap{$tempLine[0]} = $newNewOffset;
			}
			else
			{
			    $offsetMap{$tempLine[0]} = $tempLine[0];
			}
			
			if($tempLine[0] == $locationOffset)
			{
			    my $newPcnt = $hypData{'p_cnt'} + 1;
			    while(length $newPcnt < 3)#needs to be represented by 3 digits.
			    {
				$newPcnt = "0".$newPcnt;
			    }
			    $newOffset = $newOffset + 18; #14 is the length of new data being added.
			    $tempIn = "$hypData{'synset_offset'} $hypData{'lex_filenum'} $hypData{'ss_type'} $hypData{'w_cnt'} $hypData{'word_lex_id'} $newPcnt $hypData{'ptr'} ~ $newOffset $pos 0000 | $hypData{'gloss'}";
			    $changed = 1;
			}
		    }
		    else
		    {
			$CRNotice{$curLine} = $tempIn;
		    }

		    $curLine+=1;
		    
		    print WNDATATEMP "$tempIn\n";
		}
	    }
	   	    
	    $indexPos ="$newSyn[0] $pos $newSynNum $lemmaIndex{'p_cnt'} $lemmaIndex{'ptr_symbol'} $newSynNum $lemmaIndex{'tagsense_cnt'} $lemmaIndex{'synset_offset'} $newOffset";
	    $dataPos = "$newOffset $hypData{'lex_filenum'} $pos 01 $newSyn[0] 0 001 @ $hypData{'synset_offset'} $pos 0000 | $newSyn[3]"; 
	    $indexSense = "$newSyn[0]%$posNum:$hypData{'lex_filenum'}:00:: $newOffset $newSynNum 0";

	    close WNDATATEMP;
	    open WNDATATEMP, "$dataFile.temp" or die $!;

	    $curLine = 1;
	    while(<WNDATATEMP>)
	    {
		for $tempIn (split("\n"))
		{
		    my @tempLine = split /\s/, $tempIn;
		    for my $i (0 .. $#tempLine)
		    {
			if(exists $offsetMap{$tempLine[$i]})
			{
			    $tempLine[$i] = "$offsetMap{$tempLine[$i]}";
			}
			
		    }
		    $tempIn = join(' ', @tempLine);

		    if($curLine > $wnCRLength)
		    {
			for($i=1; $i <= $DataSpace{$curLine}; $i++)
			{
			    $tempIn = $tempIn . " ";
			}
			print WNDATANEW "$tempIn\n";
		    }
		    else
		    {
			print WNDATANEW "$CRNotice{$curLine}\n";
		    }
		    $curLine+=1;	    		    	    		    	       	   
		}
	    }
	    print WNDATANEW "$dataPos  \n";

	    $curLine = 1;
	    while(<WNINDEX>)
	    {
		for $tempIn (split("\n"))
		{
		    if($curLine > $wnCRLength)
		    {
			#need to add hyponym pointer if it did not exist before on hypernym
			if($tempIn =~ /^$locationLemma\b[^-]/)
			{
			    unless($tempIn =~ /\~/)
			    {
				my $newPcnt = $hypInfo{'p_cnt'};
				$newPcnt+=1;
				$tempIn ="$hypInfo{'lemma'} $hypInfo{'pos'} $hypInfo{'synset_cnt'} $newPcnt $hypInfo{'ptr_symbol'} ~ $hypInfo{'sense_cnt'} $hypInfo{'tagsense_cnt'} $hypInfo{'synset_offset'}";
			    }
			}

			if($tempIn =~ /^$newSyn[0]\b[^-]/)
			{
			    $tempIn = "$indexPos";
			}
			my @tempLine = split /\s/, $tempIn;
			my $tmpPcnt = $tempLine[2];
			my $offsetPtr = scalar(@tempLine) - 1;
			while($tmpPcnt > 0)
			{
			    if(exists $offsetMap{$tempLine[$offsetPtr]})
			    {
				$tempLine[$offsetPtr] = "$offsetMap{$tempLine[$offsetPtr]}";
			    }
			    $tmpPcnt-=1;
			    $offsetPtr-=1;
			}
			$tempIn = join(' ', @tempLine);
								
		    }
		    else
		    {
			$curLine+=1;
		    }

		    print WNINDEXNEW "$tempIn  \n";
		}
	    }	    
	    	    
	    $alpha = 1;
	    while(<WNSENSE>)
	    {
		for $tempIn (split("\n"))
		{
		    my @tempLine = split /\s/, $tempIn;
		    #add in $indexSense alphabetically
		    if($alpha == 1)
		    {
			if(($tempLine[0] cmp $newSyn[0]) == 1 )
			{
			    print WNSENSENEW "$indexSense\n";
			    $alpha = 0;
			}
		    }
		    
		    if(exists $offsetMap{$tempLine[1]})
		    {
			$tempLine[1] = "$offsetMap{$tempLine[1]}";
		    }
		    $tempIn = join(' ', @tempLine);
		    
		    print WNSENSENEW "$tempIn\n";
		}
	    }
	    
	    close WNINDEX;
	    close WNDATA;
	    close WNSENSE;
	    close WNDATATEMP;
	}
	   

	close WNSENSENEW;
	close WNDATANEW;
	close WNSENSENEW;

	if($write == 1)#if write was successful, overwrite old files with new.
	{
	    #make backup files for last change
	    #first remove old last files
	    unlink glob "$WNSEARCHDICT/*.last";

	    #next make new last files                
	    copy($indexFile, "$indexFile.last");
	    copy($dataFile, "$dataFile.last");
	    copy($senseFile, "$senseFile.last");
	    
	    #if no backup files exists for restoreWordnet() make for easy revert.
	    my $backupcheck = "$indexFile.backup";
	    unless(-f $backupcheck)
	    {
		copy($indexFile, "$indexFile.backup");
		copy($dataFile, "$dataFile.backup");
	    }

	    unless(-f "$senseFile.backup")
	    {
		copy($senseFile, "$senseFile.backup");
	    }

	    if(-f "$dataFile.temp")
	    {
		unlink "$dataFile.temp";
	    }
	    
	    #overwrite old files with new updated files
	    unlink $indexFile;
	    unlink $dataFile;
	    unlink $senseFile;
	    move("$indexFile.new", $indexFile);
	    move("$dataFile.new", $dataFile);
	    move("$senseFile.new", $senseFile);
	}
    }

}

=item $obj->merge($newSynset, $location)

Takes in a new synset and inserts it into WordNet at the specified location
by merging it into the specified location lemma as a synset. The location should
be represented by "lemma#pos#senseNum". For example, to merge to the 2nd sense
of the noun window, the location would be "window#n#2".

Parameters: Synset array in form (lemma, part-of-speech, item-id, definition)
or "word\tpos\titem-id\tdef", and location to be inserted in form  
(item-id, WordNet sense).

Returns: nothing

=cut
sub merge()
{
    #need to load in new QueryData
    $wn = WordNet::QueryData->new;
    my $base = 0; 
    if(scalar @_ == 3)#checks if method entered by object.
    {
	$base = 1;
    }
    
    my @newSyn = @{$_[$base]};
    $base = $base +1;
    if(scalar @newSyn == 1) #in second form
     {
	my @tempSyn = split("\t", $newSyn[0]);
	@newSyn = @tempSyn;
    }
    my $pos = substr($newSyn[1], 0, 1);
    my @location = @{$_[$base]};
    my $write = 1; #write flag changes to 0 if error occurs so no write() will occur.

    if(scalar @newSyn < 4)
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "New synset does not contain enough elements.";
	$write = 0;
    }
    
    if(scalar @location < 2)
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "Location does not contain enough elements.";
	$write = 0;
    }

    unless (defined $wn->offset("$location[1]"))
    {
	my $self = shift;
	$self->{error} = 2;
	$self->{errorString} = "Location does not exist in WordNet.";
	$write = 0;
    }
    
    if($write == 1)
    {
       	my $newOffset = findNewOffset($newSyn[1]);
	my %offsetMap; #used to stored changes in offsets.
	my %CRNotice;
	my %DataSpace;
	my $indexPos = "";
	my $dataPos = "";
	my $indexSense = "";
	my $posNum = 0;
	my $locationLemma = $location[1];
	$locationLemma =~ s/#.*//; #extract lemma
	my $locationPos = $newSyn[1]; #must be same pos as new.
	my $locationOffset = $wn->offset("$location[1]");
	while(length($locationOffset) < 8) #QueryData->offset() does not keep the 8 digits, need to add back lost 0's
	{
	    $locationOffset = "0".$locationOffset;
	}
	my $indexFile = "$WNSEARCHDICT/index.$locationPos";
	my $dataFile = "$WNSEARCHDICT/data.$locationPos";
	my $senseFile = "$WNSEARCHDICT/index.sense";
	open (WNINDEXNEW, '>', "$indexFile.new") or die $!;
	open (WNDATANEW, '>', "$dataFile.new") or die $!;
	open (WNSENSENEW, '>', "$senseFile.new") or die $!;

	#make filehandles hot
	my $fhIndex = select(WNINDEXNEW);
	$|=1;
	select($fhIndex);

	my $fhData = select(WNDATANEW);
	$|=1;
	select($fhData);

	my $fhSense = select(WNSENSENEW);
	$|=1;
	select($fhSense);
	
	if($pos eq "n")
	{
	    $posNum = 1;
	}
	else 
	{
	    if($pos eq "v")
	    {
		$posNum = 2;
	    }
	    else
	    {
		my $self = shift;
		$self->{error} = 2;
		$self->{errorString} = "Part of speech must be verb or noun";
		$write = 0;
	    }
	}
	

	if(isNewWord($newSyn[0], $newSyn[1]) == 0)
	{
	    my %synIndex = %{getIndexInfo($locationLemma, $locationPos)};
	    my %synData = %{getDataInfo($locationOffset, $locationPos)};
	       	    
	    #print to three required files.
	    open WNINDEX, "$indexFile" or die $!;
	    open WNDATA, "$dataFile" or die $!;
	    open WNSENSE, "$senseFile" or die $!;
	    open (WNDATATEMP, '>', "$dataFile.temp") or die $!;
	    
            my $changed = 0;
	    my $curLine = 1;
	    my $newWordLength = length($newSyn[0]) + 2;
	    while(<WNDATA>)
	    {
		for $tempIn (split("\n"))
		{
		    my $spaceTmp = $tempIn;
		    $spaceTmp =~ /( *)$/;
		    $DataSpace{$curLine} = length($1);
		    if($curLine > $wnCRLength)
		    {
			my @tempLine = split /\s/, $tempIn;
			if($changed == 1)
			{
			    my $newNewOffset = $tempLine[0] + $newWordLength;
			    while(length($newNewOffset) < 8)
			    {
				$newNewOffset = "0".$newNewOffset;
			    }
			    $offsetMap{$tempLine[0]} = $newNewOffset;
			}
			else
			{
			    $offsetMap{$tempLine[0]} = $tempLine[0];
			}

			if($tempLine[0] == $locationOffset)
			{		    
			    $changed = 1;
			}
		    }
		    else
		    {
			$CRNotice{$curLine} = $tempIn;			 
		    }
		    $curLine+=1;

		    print WNDATATEMP "$tempIn\n";
		}
	    }
	   	    
	    $indexPos = "$newSyn[0] $pos 1 $synIndex{'p_cnt'} $synIndex{'ptr_symbol'} 1 0 $locationOffset";
	    my $wcnt = $synData{'w_cnt'} + 1;
	    $dataPos = "$locationOffset $synData{'lex_filenum'} $synData{'ss_type'} $wcnt $synData{'word_lex_id'} $newSyn[0] 0 $synData{'p_cnt'} $synData{'ptr'} | $synData{'gloss'}";
	    $indexSense = "$newSyn[0]%$posNum:$synData{'lex_filenum'}:00:: $locationOffset 1 0";

	    close WNDATATEMP;
	    open WNDATATEMP, "$dataFile.temp" or die $!;

	    $curLine = 1;
	    while(<WNDATATEMP>)
	    {
		for $tempIn (split("\n"))
		{
		    if($tempIn =~ /^$locationOffset\b/)
		    {
			$tempIn = $dataPos;
		    }
		    
		    my @tempLine = split /\s/, $tempIn;
		    for my $i (0 .. $#tempLine)
		    {
			if(exists $offsetMap{$tempLine[$i]})
			{
			    $tempLine[$i] = "$offsetMap{$tempLine[$i]}";
			}

		    }
		    $tempIn = join(' ', @tempLine);

		    if($curLine > $wnCRLength)
		    {
			for($i=1; $i <= $DataSpace{$curLine}; $i++)
			{
			    $tempIn = $tempIn . " ";
			}
			print WNDATANEW "$tempIn\n";
		    }
		    else
		    {
			print WNDATANEW "$CRNotice{$curLine}\n";
		    }
		    $curLine+=1;
		}
	    }   

	    my $alpha = 1;
	    $curLine = 1;
	    while(<WNINDEX>)
	    {
		for $tempIn (split("\n"))
		{
		    if($curLine > $wnCRLength)
		    {
			my @tempLine = split /\s/, $tempIn;
			
			#add in $indexPos alphabetically
			if($alpha == 1)
			{
			    if(($tempLine[0] cmp $newSyn[0]) == 1 )
			    {
				print WNINDEXNEW "$indexPos  \n";
				$alpha = 0;
			    }
			}
			
			my $tmpPcnt = $tempLine[2];
			my $offsetPtr = scalar(@tempLine) - 1;
			while($tmpPcnt > 0)
			{
			    if(exists $offsetMap{$tempLine[$offsetPtr]})
			    {
				$tempLine[$offsetPtr] = "$offsetMap{$tempLine[$offsetPtr]}";
			    }
			    $tmpPcnt-=1;
			    $offsetPtr-=1;
			}
			$tempIn = join(' ', @tempLine);
		    }
		    else
		    {
			$curLine+=1;
		    }
		    print WNINDEXNEW "$tempIn  \n";
		}
	    }

	    $alpha = 1;
	    while(<WNSENSE>)
	    {
		for $tempIn (split("\n"))
		{
		    my @tempLine = split /\s/, $tempIn;
		    #add in $indexSense alphabetically
		    if($alpha == 1)
		    {
			if(($tempLine[0] cmp $newSyn[0]) == 1 )
			{
			    print WNSENSENEW "$indexSense\n";
			    $alpha = 0;
			}
		    }
		    
		    if(exists $offsetMap{$tempLine[1]})
		    {
			$tempLine[1] = "$offsetMap{$tempLine[1]}";
		    }
		    $tempIn = join(' ', @tempLine);

		    print WNSENSENEW "$tempIn\n";
		}
	    }
	    print WNSENSENEW "$indexSense\n";
	    close WNINDEX;
	    close WNDATA;
	    close WNSENSE;
	    close WNDATATEMP;
	}
	else #lemma already exists
	{
	    my %synIndex = %{getIndexInfo($locationLemma, $locationPos)};
	    my %synData = %{getDataInfo($locationOffset, $locationPos)};
	    my %lemmaIndex = %{getIndexInfo($newSyn[0], $newSyn[1])};
	    my $newSynNum =$lemmaIndex{'synset_cnt'} + 1;

	    #print to three required files.
	    open WNINDEX, "$indexFile" or die $!;
	    open WNDATA, "$dataFile" or die $!;
	    open WNSENSE, "$senseFile" or die $!;
	    open (WNDATATEMP, '>', "$dataFile.temp") or die $!;
	    
            my $changed = 0;
            my $curLine = 1;
            my $newWordLength = length($newSyn[0]) + 3;
            while(<WNDATA>)
            {
                for $tempIn (split("\n"))
                {
		    my $spaceTmp = $tempIn;
		    $spaceTmp =~ /( *)$/;
		    $DataSpace{$curLine} = length($1);
                    if($curLine > $wnCRLength)
                    {
                        my @tempLine = split /\s/, $tempIn;
                        if($changed == 1)
                        {
                            my $newNewOffset = $tempLine[0] + $newWordLength;
                            while(length($newNewOffset) < 8)
                            {
                                $newNewOffset = "0".$newNewOffset;
                            }
                            $offsetMap{$tempLine[0]} = $newNewOffset;
                        }
                        else
                        {
                            $offsetMap{$tempLine[0]} = $tempLine[0];
                        }

                        if($tempLine[0] == $locationOffset)
                        {
                            $changed = 1;
                        }
                    }
                    else
                    {
			$CRNotice{$curLine} = $tempIn;
                    }
		    $curLine+=1;

                    print WNDATATEMP "$tempIn\n";
                }
            }
	    
	    
	    
	    $indexPos = "$newSyn[0] $pos $newSynNum $lemmaIndex{'p_cnt'} $lemmaIndex{'ptr_symbol'} $newSynNum $lemmaIndex{'tagsense_cnt'} $lemmaIndex{'synset_offset'} $locationOffset";
	    my $wcnt = $synData{'w_cnt'} + 1;
	    if(length $wcnt < 2)
	    {
		$wcnt = "0".$wcnt; #needs to be represented by 2 digit number.
	    }
	    $dataPos = "$locationOffset $synData{'lex_filenum'} $synData{'ss_type'} $wcnt $synData{'word_lex_id'} $newSyn[0] 0 $synData{'p_cnt'} $synData{'ptr'} | $synData{'gloss'}";
	    $indexSense = "$newSyn[0]%$posNum:$synData{'lex_filenum'}:00:: $locationOffset $newSynNum 0";

	    close WNDATATEMP;
	    open WNDATATEMP, "$dataFile.temp" or die $!;

	    $curLine = 1;
	    while(<WNDATATEMP>)
	    {
		for $tempIn (split("\n"))
		{
		    if($tempIn =~ /^$locationOffset\b/)
		    {
			$tempIn = $dataPos;
		    }

		    my @tempLine = split /\s/, $tempIn;
		    for my $i (0 .. $#tempLine)
		    {
			if(exists $offsetMap{$tempLine[$i]})
			{
			    $tempLine[$i] = "$offsetMap{$tempLine[$i]}";
			}

		    }
		    $tempIn = join(' ', @tempLine);

		    if($curLine > $wnCRLength)
		    {
			for($i=1; $i <= $DataSpace{$curLine}; $i++)
			{
			    $tempIn = $tempIn . " ";
			}
			print WNDATANEW "$tempIn\n";
		    }
		    else
		    {
			print WNDATANEW "$CRNotice{$curLine}\n";
		    }
		    $curLine+=1;
		}
	    }
	        	    
	    $curLine = 1;
	    while(<WNINDEX>)
	    {
		for $tempIn (split("\n"))
		{
		    if($curLine > $wnCRLength)
		    {
			if($tempIn =~ /^$newSyn[0]\b[^-]/)
			{
			    $tempIn = $indexPos;
			}
			my @tempLine = split /\s/, $tempIn;
			my $tmpPcnt = $tempLine[2];
			my $offsetPtr = scalar(@tempLine) - 1;
			while($tmpPcnt > 0)
			{
			    if(exists $offsetMap{$tempLine[$offsetPtr]})
			    {
				$tempLine[$offsetPtr] = "$offsetMap{$tempLine[$offsetPtr]}";
			    }
			    $tmpPcnt-=1;
			    $offsetPtr-=1;
			}
			$tempIn = join(' ', @tempLine);
		    }
		    else
		    {
			$curLine+=1;
		    }
		    print WNINDEXNEW "$tempIn  \n";
		}
	    }

	    $alpha = 1;
	    while(<WNSENSE>)
	    {
		for $tempIn (split("\n"))
		{
		    my @tempLine = split /\s/, $tempIn;
		    #add in $indexSense alphabetically
		    if($alpha == 1)
		    {
			if(($tempLine[0] cmp $newSyn[0]) == 1 )
			{
			    print WNSENSENEW "$indexSense\n";
			    $alpha = 0;
			}
		    }
		    
		    if(exists $offsetMap{$tempLine[1]})
		    {
			$tempLine[1] = "$offsetMap{$tempLine[1]}";
		    }
		    $tempIn = join(' ', @tempLine);

		    print WNSENSENEW "$tempIn\n";
		}
	    }
	    print WNSENSENEW "$indexSense\n";
	    close WNINDEX;
	    close WNDATA;
	    close WNSENSE;
	    close WNDATATEMP;
	}

	close WNSENSENEW;
	close WNDATANEW;
	close WNSENSENEW;

	if($write == 1)#if write was successful, overwrite old files with new.
	{
	    #make backup files for last change
	    #first remove old last files
	    unlink glob "$WNSEARCHDICT/*.last";

	    #next make new last files
	    copy($indexFile, "$indexFile.last");
	    copy($dataFile, "$dataFile.last");
	    copy($senseFile, "$senseFile.last");
	    	    
	    #if no backup files for restoreWordnet() exists make for easy revert.
	    my $backupcheck = "$indexFile.backup";
	    unless(-f $backupcheck)
	    {
		copy($indexFile, "$indexFile.backup");
		copy($dataFile, "$dataFile.backup");
	    }

	    unless(-f "$senseFile.backup")
	    {
		copy($senseFile, "$senseFile.backup");
	    }

	    if(-f "$dataFile.temp")
	    {
		unlink "$dataFile.temp";
	    }
	    
	    #overwrite old files with new updated files
	    unlink $indexFile;
	    unlink $dataFile;
	    unlink $senseFile;
	    move("$indexFile.new", $indexFile);
	    move("$dataFile.new", $dataFile);
	    move("$senseFile.new", $senseFile);
	}
    }

}

=item $obj->restoreWordNet()

Causes all WordNet\dict files to be restored to their original
state before any inserts were performed. This is equivalent to 
installing WordNet\dict fresh on your machine.

Parameter: none

Returns: nothing

=cut

sub restoreWordNet()
{
    my $backupFlag = 0;
    
    if(-f "$WNSEARCHDICT/index.noun.backup")
    {
	unlink "$WNSEARCHDICT/index.noun";
	unlink "$WNSEARCHDICT/data.noun";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.noun.backup", "$WNSEARCHDICT/index.noun");
	move("$WNSEARCHDICT/data.noun.backup", "$WNSEARCHDICT/data.noun");
    }

    if(-f "$WNSEARCHDICT/index.verb.backup")
    {
	unlink "$WNSEARCHDICT/index.verb";
	unlink "$WNSEARCHDICT/data.verb";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.verb.backup", "$WNSEARCHDICT/index.verb");
	move("$WNSEARCHDICT/data.verb.backup", "$WNSEARCHDICT/data.verb");
    }

    if(-f "$WNSEARCHDICT/index.adj.backup")
    {
	unlink "$WNSEARCHDICT/index.adj";
	unlink "$WNSEARCHDICT/data.adj";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.adj.backup", "$WNSEARCHDICT/index.adj");
	move("$WNSEARCHDICT/data.adj.backup", "$WNSEARCHDICT/data.adj");
    }

    if(-f "$WNSEARCHDICT/index.adv.backup")
    {
	unlink "$WNSEARCHDICT/index.adv";
	unlink "$WNSEARCHDICT/data.adv";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.adv.backup", "$WNSEARCHDICT/index.adv");
	move("$WNSEARCHDICT/data.adv.backup", "$WNSEARCHDICT/data.adv");
    }
    
    if($backupFlag == 1)
    {
	unlink "$WNSEARCHDICT/index.sense";

	move("$WNSEARCHDICT/index.sense.backup", "$WNSEARCHDICT/index.sense");

	unlink glob "$WNSEARCHDICT/*.last";
    }
}

=item $obj->revertLastChange()

Allows the user to undo the last insert made to WordNet.

Parameter: none

Returns: nothing

=cut

sub revertLastChange()
{
    my $backupFlag = 0;
    
    if(-f "$WNSEARCHDICT/index.noun.last")
    {
	unlink "$WNSEARCHDICT/index.noun";
	unlink "$WNSEARCHDICT/data.noun";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.noun.last", "$WNSEARCHDICT/index.noun");
	move("$WNSEARCHDICT/data.noun.last", "$WNSEARCHDICT/data.noun");
    }

    if(-f "$WNSEARCHDICT/index.verb.last")
    {
	unlink "$WNSEARCHDICT/index.verb";
	unlink "$WNSEARCHDICT/data.verb";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.verb.last", "$WNSEARCHDICT/index.verb");
	move("$WNSEARCHDICT/data.verb.last", "$WNSEARCHDICT/data.verb");
    }

    if(-f "$WNSEARCHDICT/index.adj.last")
    {
	unlink "$WNSEARCHDICT/index.adj";
	unlink "$WNSEARCHDICT/data.adj";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.adj.last", "$WNSEARCHDICT/index.adj");
	move("$WNSEARCHDICT/data.adj.last", "$WNSEARCHDICT/data.adj");
    }

    if(-f "$WNSEARCHDICT/index.adv.last")
    {
	unlink "$WNSEARCHDICT/index.adv";
	unlink "$WNSEARCHDICT/data.adv";
	$backupFlag = 1;

	move("$WNSEARCHDICT/index.adv.last", "$WNSEARCHDICT/index.adv");
	move("$WNSEARCHDICT/data.adv.last", "$WNSEARCHDICT/data.adv");
    }

    if($backupFlag == 1)
    {
	unlink "$WNSEARCHDICT/index.sense";

	move("$WNSEARCHDICT/index.sense.last", "$WNSEARCHDICT/index.sense");
    }

}
    
=item $obj->isNewWord($lemma, $pos)

Takes in a lemma and searches wordnet to see if it exists.

Parameter: the lemma to search against along with the part of speech.

Returns: 1 if lemma is found or 0 if not.

=cut

sub isNewWord()
{
    my $base = 0;
    if(scalar @_ == 3)
    {
	$base = 1;#checks if method entered by object.
    }
    my $lemma = $_[$base];
    $base = $base +1;
    my $pos = $_[$base];
    my $indexFile = "$WNSEARCHDICT/index.$pos"; #wn file to be searched\

    open WNINDEX, "$indexFile" or die $!;

    while(<WNINDEX>)
    {
	for $tempIn (split("\n"))
	{
	    if($tempIn =~ /^$lemma\b[^-]/)
	    {
		close WNINDEX;
		return 1;
	    }
	}
    }

    close WNINDEX;
    return 0;
    
}

=item $obj->getIndexInfo($lemma, $pos)

Takes in lemma and returns the information from the index.pos file.

Parameter: the lemma info required and part of speech

Returns: hash lemma info from index.pos with following information:
lemma  pos  synset_cnt  p_cnt  ptr_symbol sense_cnt  tagsense_cnt  synset_offset   

=cut

sub getIndexInfo()
{
    my $base = 0;
    if(scalar @_ == 3)
    {
	$base = 1;#checks if method entered by object.
    }
    my $lemma = $_[$base];
    $base = $base+1;
    my $pos = $_[$base];
    my $indexFile = "$WNSEARCHDICT/index.$pos";
    my $indexInfoLine = "";
    my %indexInfo;
    open WNINDEX, "$indexFile" or die $!;

    while(<WNINDEX>)
    {
	for $tempIn (split("\n"))
	{
	    if($tempIn =~ /^$lemma\b[^-]/)
	    {
		$indexInfoLine = $tempIn;
		close WNINDEX;
	    }
	}
    }

    my @index = split /\s/, $indexInfoLine;

    $indexInfo{'lemma'} = $index[0];
    $indexInfo{'pos'} = $index[1];
    $indexInfo{'synset_cnt'} = $index[2];
    $indexInfo{'p_cnt'} = $index[3];

    #We gather all pointer symbols into one string for storing in the hash.
    my $pcnt = $index[3];
    my $ptrSym = "";
    my $offset = 0;
    while($pcnt >0)
    {
	my $sym = 4 + $offset;
	$ptrSym = $ptrSym . " $index[$sym]";
	$pcnt-=1;
	if($pcnt > 0)
	{
	    $offset += 1;
	}
    }
    $ptrSym =~ s/^\s+//; #remove extra front whitespace
    $indexInfo{'ptr_symbol'} = $ptrSym;
    
    my $indexPtr = 5 + $offset; #new pointer to account for different number of ptr symbols
    $indexInfo{'sense_cnt'} = $index[$indexPtr];
    $indexPtr+=1;
    $indexInfo{'tagsense_cnt'} = $index[$indexPtr];
    $indexPtr+=1;

    #Finally we gather all offsets into one string to store in the hash.
    my $scnt = $index[2];
    my $indexOffsets = "";
    while($scnt > 0)
    {
	$indexOffsets = $indexOffsets . " $index[$indexPtr]";
	$indexPtr+=1;
	$scnt-=1;
    }
    $indexOffsets =~ s/^\s+//; #remove extra front whitespace
    $indexInfo{'synset_offset'} = $indexOffsets;
    
    return \%indexInfo;
}

=item $obj->getDataInfo($synsetOffset, $pos)
    
Takes in synset offset and pos to find data associated with it in data.pos.

Parameters: the synset offset and part of speech

Returns:  hash offset info from data.pos with following information:
synset_offset  lex_filenum  ss_type  w_cnt  'word_lex_id'  p_cnt  ptr |  gloss

=cut

sub getDataInfo()
{
    my $base = 0;
    if(scalar @_ == 3)
    {
	$base = 1;#checks if method entered by object.
    }

    my $synOffset = $_[$base];
    $base+=1;
    my $pos = $_[$base];

    my $dataFile = "$WNSEARCHDICT/data.$pos";
    my $dataInfoLine = "";
    
    open WNDATA, "$dataFile" or die $!;
   
    while(<WNDATA>)
    {
	for $tempIn (split("\n"))
	{
	    if($tempIn =~ /^$synOffset\b/)
	    {
		$dataInfoLine = $tempIn;
		close WNDATA;
	    }
	}
    }

    my @data = split /\s/, $dataInfoLine;

    my %dataInfo;
    $dataInfo{'synset_offset'} = $data[0];
    $dataInfo{'lex_filenum'} = $data[1];
    $dataInfo{'ss_type'} = $data[2];
    $dataInfo{'w_cnt'} = $data[3];

    #we must consolidate the words and their lex ids into one string. it should be noted that
    # the lex ids for each word are stored within the string in the hash not separately.
    my $offset = 0;
    my $wcnt = $data[3];
    my $words = "";
    while($wcnt > 0)
    {
	my $wptr = 4 + $offset;
	$words = $words . " $data[$wptr]"; #appends word
	$wptr+=1;
	$words = $words . " $data[$wptr]"; #appends lex_id
	$wcnt-=1;
	if($wcnt > 0)
	{
	    $offset+=2; #makes up for both the word and lex_id
	}   
    }
    $words =~ s/^\s+//; #remove extra front whitespace
    $dataInfo{'word_lex_id'} = $words;

    my $dataPtr = 6 + $offset;
    $dataInfo{'p_cnt'} = $data[$dataPtr];
    $dataPtr+=1;

    #likewise, we consolidate all ptrs together into a single string.
    $offset = 0;
    my $pcnt = $dataInfo{'p_cnt'};;
    my $ptrs = "";
    while($pcnt > 0)
    {
	my $pptr = $dataPtr + $offset;
	$ptrs = $ptrs . " $data[$pptr]";#appends ptr symbol
	$pptr+=1;
	$ptrs = $ptrs . " $data[$pptr]";#appends synset offset
	$pptr+=1;
	$ptrs = $ptrs . " $data[$pptr]";#appends pos
	$pptr+=1;
	$ptrs = $ptrs . " $data[$pptr]";#appends source/target
	$pptr+=1;
	$pcnt-=1;
	$offset+=4;#makes up for all extracted data above.
    }
    $ptrs =~ s/^\s+//; #remove extra front whitespace
    $dataInfo{'ptr'} = $ptrs;

    $dataPtr = $dataPtr + $offset; #move ptr past retrieved info.
    $dataPtr+=1; #skip over '|' in file.
    my $size = scalar @data;
    my $gloss = "";

    #all the info that is left is the gloss, extract until no more info remains.
    while($dataPtr < $size)
    {
	$gloss = $gloss . " $data[$dataPtr]";
	$dataPtr+=1;
    }
    $gloss =~ s/^\s+//; #remove extra front whitespace
    $dataInfo{'gloss'} = $gloss;

    return \%dataInfo;
}    

=item $obj->getSenseInfo($synsetOffset)

Takes in a synset offset and returns the sense associated with the offset.

Parameter: the synset offset of the desired lemma

Returns: a hash offset info from index.sense with data:
sense_key  synset_offset  sense_number  tag_cnt 

=cut

sub getSenseInfo()
{
    my $base = 0;
    if(scalar @_ == 2)
    {
	$base = 1;#checks if method entered by object.
    }

    my $synOffset = $_[$base];

    my $senseFile = "$WNSEARCHDICT/index.sense";
    my $senseInfoLine = "";
    
    open WNSENSE, "$senseFile" or die $!;
   
    while(<WNSENSE>)
    {
	for $tempIn (split("\n"))
	{
	    if($tempIn =~ /\b$synOffset\b/)
	    {
		$senseInfoLine = $tempIn;
		close WNSENSE;
	    }
	}
    }

    my @sense = split /\s/, $senseInfoLine;

    my %senseInfo;
    $senseInfo{'sense_key'} = $sense[0];
    $senseInfo{'synset_offset'} = $sense[1];
    $senseInfo{'sense_number'} = $sense[2];
    $senseInfo{'tag_cnt'} = $sense[3];

    return \%senseInfo;
}

=item $obj->findNewOffset()

Searches through and calculates the offset for inserting.

Parameters: pos of new lemma

Returns: new unused offset

=cut

sub findNewOffset()
{
    my $offset = 0;
    my $base = 0;
    if(scalar @_ == 3)
    {
	$base = 1;#checks if method entered by object.
    }

    my $pos = $_[$base];

    my $dataFile = "$WNSEARCHDICT/data.$pos";
    my $dataLastLine = "";
    
    open WNDATA, "$dataFile" or die $!;
   
    while(<WNDATA>)
    {
	for $tempIn (split("\n"))
	{
	    $dataLastLine = $tempIn;
	}
    }

    close WNDATA;
    my @data = split /\s/, $dataLastLine;

    $offset = $data[0] + length($dataLastLine) + 1;
        
    return $offset;
}

=item $obj->changeWNLocation()

NOTE: Method not yet implemented, planned for next update.

Allows the user to temporarily choose the location for WordNet
which can be used to change between different WordNet 
dictionaries.

Parameters: New location ex. "/usr/local/WordNet-3.0"

Returns: nothing

=cut

#sub changeWNLocation()
#{
#    my $base = 0;
#    if(scalar @_ == 2)
#    {
#	$base = 1;#checks if method entered by object.
#    }
#    my $newLocation = $_[$base];
#
#    #check to see if /dict exists in the new WN location
#    $newLocation = "/home/csgrads/ruse0008/WordNet-Insert/WordNet-3.0";
#    
#    if(-d "$newLocation/dict")
#    {
#	$WNHOME = $newLocation;	
#    }
#    else
#    {
#	my $self = shift;
#	$self->{error} = 2;
#	$self->{errorString} = "Desired WordNet location does not contain dict/.";	
#    }
#}    

#**************printHelp()**********************
# Prints indepth help guide to screen.
#***********************************************
sub printHelp()
{
    printUsage();
    print "Takes in lemmas from file and attempts to\n";
    print "insert them into WordNet by first finding\n";
    print "a hypernym, then either a) merging the   \n";
    print "lemma with the hypernym or b) attaching  \n";
    print "the lemma to the hypernym.\n";
}

1;
