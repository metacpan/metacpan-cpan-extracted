# UMLS::Association 
#
# Perl module for scoring the semantic association of terms in the Unified
# Medical Language System (UMLS).
#
# Copyright (c) 2015
#
# Sam Henry, Virginia Commonwealth University
# henryst at vcu.edu
#
# Bridget McInnes, Virginia Commonwealth University
# btmcinees at vcu.edu
#
# Keith Herbert, Virginia Commonwealth University
# herbertkb at vcu.edu
#
# Alexander D. McQuilkin, Virginia Commonwealth University 
# alexmcq99 at yahoo.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to 
#
# The Free Software Foundation, Inc., 
# 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.

=head1 NAME

UMLS::Association -  A suite of Perl modules that implement a number of semantic
association measures in order to calculate the semantic association between two
concepts in the UMLS. 


=head1 INSTALL

To install the module, run the following magic commands:

  perl Makefile.PL
  make
  make test
  make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 DESCRIPTION

This package provides a Perl interface to 

=head1 INITIALIZING THE MODULE

To create an instance of the interface object, using default values
for all configuration options:

  use UMLS::Association;
  my $associaton = UMLS::Association->new();

More information is provided in the INSTALL file. 

=cut
use lib '/home/henryst/UMLS-Association/lib';
use lib '/home/henryst/Text-NSP-1.31/lib';

package UMLS::Association;

use Fcntl;
use strict;
use warnings;
use bytes;

use UMLS::Association::StatFinder;
use UMLS::Association::ErrorHandler; 

my $pkg = "UMLS::Association";

use vars qw($VERSION);

$VERSION = '0.19';

my $errorhandler     = ""; 
my $statfinder_G = "";   
my $debug = 0;
my $precision_G = 4; #precision of the output


# -------------------- Class methods start here --------------------

#  method to create a new UMLS::Association object
#  input : $params <- reference to hash containing the parameters 
#  output: $self
sub new {
    my $self      = {};
    my $className = shift;
    my $params    = shift;

    # bless the object.
    bless($self, $className);

    # initialize error handler
    $errorhandler = UMLS::Association::ErrorHandler->new();
    if(! defined $errorhandler) {
	print STDERR "The error handler did not get passed properly.\n";
	exit;
    }
    
    # Initialize the object.
    $self->_initialize($params);

    return $self;
}

#  initialize the variables and set the parameters
#  input : $params <- reference to hash containing the parameters 
#  output: none, but $self is initialized
sub _initialize {
    my $self = shift;
    my $params = shift;

    #  check self
    my $function = "_initialize";
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 2);
    }
    my $paramCount = 0;
    if ($params->{'mwa'}) {$paramCount++;}
    if ($params->{'lta'}) {$paramCount++;}
    if ($params->{'lsa'}) {$paramCount++;}
    if ($params->{'sbc'}) {$paramCount++;}
    if ($params->{'wsa'}) {$paramCount++;}
    if ($paramCount > 1) {
	$errorhandler->_error($pkg, $function, "Only one of lta, mwa, lsa, sbc, wsa may be specified", 12);
    }

    # set parameters
    if ($params->{'precision'}) {
	$precision_G = $params->{'precision'};
    }
    if ($params->{'debug'}) {
	$debug = 1;
    }

    # set the statfinder
    $params->{'association'} = $self; #set associaiton for WSA
    $statfinder_G = UMLS::Association::StatFinder->new($params);
    if(! defined $statfinder_G) { 
	my $str = "The UMLS::Association::StatFinder object was not created.";
	$errorhandler->_error($pkg, $function, $str, 8);
    }
}

# returns the version currently being used
# input : none
# output: the version number being used
sub version {
    my $self = shift;
    return $VERSION;
}

##########################################################################
#                  Public Association Interface
##########################################################################
# All association scores are computed through a data structure, the pair hash 
# list. This forces all the modes of operation to use the same code, and allows
# all data to be retreived in a single pass of a matrix file 
# The pair hash list is an array of pairHashRefs. The pair hash is a 
# hash with two keys, 'set1' and 'set2' each of these keys holds an arrayRef of 
# cuis which correspond to cuis in that set. This allows for lists of pairs of 
# sets of CUIs to be computed
#  In the case where only a single pair computation is needed, or rather 
# than a set, just a single cui is needed, each function still wraps the 
# values into a pairHashList. 'set1' cuis are the leading cuis in the pair, and
# 'set2 are the trailing cuis in the pair'


# calculates association for a list of single cui pairs
# input:  $cuiPairListRef - an array ref of comma seperated cui pairs  
#                           the first in the pair is the leading, 
#                           second in the pair is the trailing
#         $measure - a string specifying the association measure to use
# output: \@scores - an array ref of scores corresponding to the assocaition
#                    score for each of the pairHashes that were input
sub calculateAssociation_termPairList {
    my $self = shift;
    my $cuiPairListRef = shift;
    my $measure = shift;

    #create the cuiPairs hash datastructure
    my @pairHashes = ();
    foreach my $pair (@{$cuiPairListRef}) {
	#grab the cuis from the pair
	(my $cui1, my $cui2) = split(',',$pair);
	push @pairHashes, $self->_createPairHash_singleTerms($cui1,$cui2);
    }

    #return the array of association scores for each pair
    return $self->_calculateAssociation_pairHashList(\@pairHashes, $measure);
}

# calculates association for a single cui pair
# input:  $cui1 - the leading cui
#         $cui2 - the trailing cui
#         $measure - a string specifying the association measure to use
# output: $score - the association between the cuis
sub calculateAssociation_termPair {
    my $self = shift;
    my $cui1 = shift;
    my $cui2 = shift;
    my $measure = shift;  
    
    #create the pairHash List
    my @pairHashes = ();
    push @pairHashes, $self->_createPairHash_singleTerms($cui1,$cui2);

    #return the association score, which is the first (and only)
    # values of the return array
    return ${$self->_calculateAssociation_pairHashList(\@pairHashes, $measure)}[0];
}

# calculates association for two sets of cuis (leading and trailing cuis)
# input:  \@cuis1Ref - a ref to an array of leading cuis
#         \@cuis2Ref - a ref to an array of trailing cuis
#         $measure - a string specifying the association measure to use
# output: $score - the association between the cui sets
sub calculateAssociation_setPair {
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    my $measure = shift;

    #create the cuiPairs hash datasetructure
    my @pairHashes = ();
    push @pairHashes, $self->_createPairHash_termLists($cuis1Ref, $cuis2Ref);

    #return the association score, which is the first (and only)
    # value of the return array
    return ${$self->_calculateAssociation_pairHashList(\@pairHashes, $measure)}[0];
}


# calculate association between a list of cui set pairs. The cui lists are
# passed in as parallel arrays of sets of cuis, where assoc(cuis1[i], and cuis2[i]
# are calcualted. 
# input: \@cuis1Ref - an array ref to an array of arrays, where each element
#                     of the array contains a set of cuis
#        \@cuis2Ref - an array ref to an array of arrays of the same format as 
#                     \@cuis1Ref
#        $measure - a string specifying the association measure to use
# \@scores - an array ref of scores corresponding to the assocaition
#                    score for each of the pairHashes that were input
sub calculateAssociation_setPairList {
    my $self = shift;
    my $cuis1Ref = shift;
    my $cuis2Ref = shift;
    my $measure = shift;
    
    #create the pair hash for each set of pairs
    my @pairHashes = ();
    for (my $i = 0; $i < scalar @{$cuis1Ref}; $i++) {
	#turn the cui arrays into a hash ref
	push @pairHashes, $self->_createPairHash_termLists(${$cuis1Ref}[$i],${$cuis2Ref}[$i]);
    }

    #return the array of association scores for each pair
    return $self->_calculateAssociation_pairHashList(\@pairHashes, $measure);
}






##########################################################################
#                          PairHash Creators
##########################################################################

# creates a pair hash object from two cuis
# input:  $cui1 - the leading cui in the pair hash
#         $cui2 - the trailing cui in the pair hash
# output: \%pairHash - a ref to a pairHash
sub _createPairHash_singleTerms {
    my $self = shift;
    my $cui1 = shift;
    my $cui2 = shift;

    #create the hash data structures
    my %pairHash = ();

    #populate the @cuiLists
    #set the cui lists to the concept
    my @cui1List = ();
    push @cui1List, $cui1;
    my @cui2List = ();
    push @cui2List, $cui2;

    $pairHash{'set1'} = \@cui1List;
    $pairHash{'set2'} = \@cui2List;

    return \%pairHash;
}


# Creates a pair hash from two cui lists
# input:  \@set1Ref - the leading cuis of the pair set 
#         \@set2Ref - the trailing cuis of the pair set
# output: \%pairHash - a ref to a pairHash
sub _createPairHash_termLists {
    my $self = shift;
    my $set1Ref = shift;
    my $set2Ref = shift;

    #create the hash data structures
    my %pairHash = ();

    #set the cui lists to the pair hash directly
    $pairHash{'set1'} = $set1Ref;
    $pairHash{'set2'} = $set2Ref;
    

    return \%pairHash;

}

##########################################################################
#                    Association Calculators
##########################################################################

# calculate association for each of the pairHashes in the input list of 
# cui pair hashes
# input: $pairHashListRef - an array ref of cui pairHashes
# output: \@scores - an array ref of scores corresponding to the assocaition
#                    score for each of the pairHashes that were input
sub _calculateAssociation_pairHashList {
    my $self = shift;
    my $pairHashListRef = shift;
    my $measure = shift;  

    #retreive observed counts for each pairHash
    my $statsListRef = $statfinder_G->getObservedCounts($pairHashListRef);
    
    #calculate associaiton score for each pairHash
    my @scores = ();
    foreach my $statsRef(@{$statsListRef}) {
	#grab stats for this pairHash from the list of stats
	my $n11 = ${$statsRef}[0];
	my $n1p = ${$statsRef}[1];
	my $np1 = ${$statsRef}[2];
	my $npp = ${$statsRef}[3];
	
	#calculate the association score
	push @scores, $self->_calculateAssociation_fromObservedCounts($n11, $n1p, $np1, $npp, $measure);
    }

    #return the association scores for all pairHashes in the list
    return \@scores
}

# calculates an association score from the provided values
# input:  $n11 <- n11 for the cui pair
#         $npp <- npp for the dataset
#         $n1p <- n1p for the cui pair
#         $np1 <- np1 for the cui pair
#         $statistic <- the string specifying the stat to calc
# output: the statistic (association score) between the two concepts
sub _calculateAssociation_fromObservedCounts {
    #grab parameters
    my $self = shift;
    my $n11 = shift;
    my $n1p = shift;
    my $np1 = shift;
    my $npp = shift;
    my $statistic = shift;

    #print the values used in computation if debugging
    if ($debug) {
	print "-----n11, n1p, np1, npp = $n11, $n1p, $np1, $npp\n";
    }

    #set frequency and marginal totals
    my %values = (n11=>$n11, 
		  n1p=>$n1p, 
		  np1=>$np1, 
		  npp=>$npp); 
   
    #return cannot compute, or 0
    #if($n1p < 0 || $np1 < 0) { #NOTE, this kind of makes sense, says if there as an error then return -1
    # the method I am doing now just says if any didn't occurr in the dataset then return -1
    if($n1p <= 0 || $np1 <= 0 || $npp <= 0) {
	return -1.000; 
    }
    if($n11 <= 0) { 
	return 0.000;
    }
    
    #set default statistic
    if(!defined $statistic) { 
	die ("ERROR: no association measure defined\n");
    }

    #set statistic module (Text::NSP)
    my $includename = ""; my $usename = "";  my $ngram = 2; #NOTE: calculation actually change slightly with 3-grams, 4-grams, etc... does it make enough of a difference to matter?
    if ($statistic eq "freq") {
	return $n11;
    }
    elsif($statistic eq "random") {
	return rand();
    }
    elsif($statistic eq "ll")  { 
	$usename = 'Text::NSP::Measures::'.$ngram.'D::MI::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','MI',$statistic.'.pm');
    }
    elsif($statistic eq "pmi" || $statistic eq "tmi" || $statistic eq "ps") { 
	$usename = 'Text::NSP::Measures::'.$ngram.'D::MI::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','MI',$statistic.'.pm');
    }
    elsif($statistic eq "x2"||$statistic eq "phi") {
	$usename = 'Text::NSP::Measures::'.$ngram.'D::CHI::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','CHI',$statistic.'.pm');
    }
    elsif($statistic eq "leftFisher"||$statistic eq "rightFisher"||$statistic eq "twotailed") { 
	if($statistic eq "leftFisher")	       { $statistic = "left";  }
	elsif($statistic eq "rightFisher")  { $statistic = "right"; }
	$usename = 'Text::NSP::Measures::'.$ngram.'D::Fisher::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','Fisher',$statistic.'.pm');
    }
    elsif($statistic eq "dice" || $statistic eq "jaccard") {
	$usename = 'Text::NSP::Measures::'.$ngram.'D::Dice::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','Dice',$statistic.'.pm');
    }
    elsif($statistic eq "odds") { 
	$usename = 'Text::NSP::Measures::'.$ngram.'D::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D',$statistic.'.pm');
    }
    elsif($statistic eq "tscore") { 
	$usename = 'Text::NSP::Measures::'.$ngram.'D::CHI::'.$statistic;
	$includename = File::Spec->catfile('Text','NSP','Measures',$ngram.'D','CHI',$statistic.'.pm');
    }
    
    # import module
    require $includename;
    import $usename;
    
    # get statistics (From NSP package)
    my $statisticValue = calculateStatistic(%values); 
    
    # check for errors/warnings from statistics.pm     
    my $errorMessage=""; 
    my $errorCode = getErrorCode(); 
    if (defined $errorCode) { 
	if($errorCode =~ /^1/) { 
	    printf(STDERR "Error from statistic library!\n  Error code: %d\n", $errorCode);
	    $errorMessage = getErrorMessage();
	    print STDERR "  Error message: $errorMessage\n" if( $errorMessage ne "");
	    exit; # exit on error
	}
	if ($errorCode =~ /^2/)  { 
	    printf(STDERR "Warning from statistic library!\n  Warning code: %d\n", $errorCode);
	    $errorMessage = getErrorMessage();
	    print STDERR "  Warning message: $errorMessage\n" if( $errorMessage ne "");
	    print STDERR "Skipping ngram\n";
	    next; # if warning, dont save the statistic value just computed
	}
    }

    #return statistic to given precision.  if no precision given, default is 4
    my $floatFormat = join '', '%', '.', $precision_G, 'f';
    my $statScore = sprintf $floatFormat, $statisticValue;

    return $statScore; 
}


1;

__END__

=head1 REFERENCING

If you write a paper that has used UMLS-Association in some way, we'd 
certainly be grateful if you sent us a copy. Currently we have no paper
referrencing the package hopefully we will soon. 

=head1 SEE ALSO

http://search.cpan.org/dist/UMLS-Association

=head1 AUTHOR

Bridget T McInnes <btmcinnes@vcu.edu>
Sam Henry <henryst@vcu.edu>

=head1 COPYRIGHT

 Copyright (c) 2015
 Sam Henry, Virginia Commonwealth University
 henryst at vcu.edu

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
