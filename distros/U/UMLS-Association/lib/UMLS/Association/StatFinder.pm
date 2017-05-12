#UMLS::Association 
#
# Perl module for scoring the semantic association of terms in the Unified
# Medical Language System (UMLS).
#
# Copyright (c) 2015
#
# Bridget T. McInnes, Virginia Commonwealth University
# btmcinnes at vcu.edu
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

package UMLS::Association::StatFinder;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;
use File::Spec;

#  error handling variables
my $errorhandler = "";
my $cuifinder      = ""; 

my $pkg = "UMLS::Association::StatFinder";

#  debug variables
local(*DEBUG_FILE);

#  global variables
my $debug     = 0;
my $NPP       = 0; 
my $umls = undef;
my $precision = 4;
my $getdescendants = 0;

######################################################################
#  functions to initialize the package
######################################################################

#  method to create a new UMLS::Association::StatFinder object
#  input : $params <- reference to hash of database parameters
#          $handler <- reference to cuifinder object 
#  output: $self
sub new {
    my $self = {};
    my $className = shift;
    my $params = shift;
    my $handler = shift; 

    # bless the object.
    bless($self, $className);

    # initialize error handler
    $errorhandler = UMLS::Association::ErrorHandler->new();
    if(! defined $errorhandler) {
        print STDERR "The error handler did not get passed properly.\n";
        exit;
    }

    #  initialize the cuifinder
    $cuifinder = $handler; 

    #  initialize global variables
    $debug = 0; 

    # initialize the object.
    $self->_initialize($params);
    return $self;
}

#  method to initialize the UMLS::Association::StatFinder object.
#  input : $parameters <- reference to a hash of database parameters
#  output:
sub _initialize {

    my $self = shift;
    my $params = shift;
    my %params = %{$params};

    #set global variables using option hash
    $umls = $params{'umls'};
    $getdescendants = $params{'getdescendants'};

    my $function = "_initialize";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    $params = {} if(!defined $params);
    if(defined $params{'precision'})
    {
	$precision = $params{'precision'};
    }
}
 
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Association::StatFinder::$function\n"; }

}

######################################################################
#  functions to get statistical information about the cuis
######################################################################
#  Method to return the frequency of a concept pair
#  input : $concept1 <- string containing a cui 1
#          $concept2 <- string containing a cui 2
#  output: $frequency <- frequency of cui pair
sub _getFrequency {

    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $function = "_getFrequency";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept1) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept1.", 4);
    }
    if(!defined $concept2) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept2.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept1)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept1) is not valid.", 6);
    }
    if(! ($errorhandler->_validCui($concept2)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept2) is not valid.", 6);
    }
    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept1)) ) {
        return -1; #$errorhandler->_error($pkg, $function, "Concept ($concept1) does not exist.", 6);
    }    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept2)) ) {
        return -1; $errorhandler->_error($pkg, $function, "Concept ($concept2) does not exist.", 6);
    }    
    #  set up database
    my $db = $cuifinder->_getDB(); 
    
    my $freqRef = $db->selectcol_arrayref("select n_11 from N_11 where cui_1='$concept1' and cui_2='$concept2'"); 
    
    my $freq = shift @{$freqRef}; 
    
    if(defined $freq) { return $freq; } else { return 0; }
}
    
#  Method to return the np1 of a concept 
#  input : $concept <- string containing a cui 1
#  output: $np1 <- number of times concept occurs in second bigram position
sub _getNp1 {

    my $self = shift;
    my $concept = shift; 

    my $function = "_getNp1"; 

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }   

    #  check if concept exists
    if(! ($cuifinder->_exists($concept)) ) {
        return -1; #$errorhandler->_error($pkg, $function, "Concept ($concept) does not exist.", 6);
    }    
    
    #  set up database
    my $db = $cuifinder->_getDB(); 
    
    my $np1Ref = $db->selectcol_arrayref("select n_p1 from N_P1 where cui_2='$concept'"); 
    
    my $np1 = shift @{$np1Ref}; 
    
    if(defined $np1) { return $np1; } else { return 0; }
}

#  Method to return the n1p of a concept 
#  input : $concept <- string containing a cui 1
#  output: $n1p <- number of times concept occurs in second bigram position
sub _getN1p {

    my $self = shift;
    my $concept = shift; 

    my $function = "_getN1p"; 

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check parameter exists
    if(!defined $concept) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept.", 4);
    }

    #  check if valid concept
    if(! ($errorhandler->_validCui($concept)) ) {
        $errorhandler->_error($pkg, $function, "Concept ($concept) is not valid.", 6);
    }    
    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept)) ) {
        return -1; #$errorhandler->_error($pkg, $function, "Concept ($concept) does not exist.", 6);
    } 
   
    #  set up database
    my $db = $cuifinder->_getDB(); 
    
    my $n1pRef = $db->selectcol_arrayref("select n_1p from N_1P where cui_1='$concept'"); 
    
    my $n1p = shift @{$n1pRef}; 
    
    if(defined $n1p) { return $n1p; } else { return 0; }
}

#  Method to return the n1p of a concept 
#  input : none
#  output: $npp <- number of total concept pairs
sub _getNpp {

    my $self = shift;
    
    my $function = "_getNpp"; 

    if($NPP > 0) { return $NPP; }
    
    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    #  set up database
    my $db = $cuifinder->_getDB(); 
    
    my $nppRef = $db->selectcol_arrayref("select n_pp from N_PP"); 
    
    $NPP = shift @{$nppRef}; 

    if($NPP <= 0) { errorhandler->_error($pkg, $function, "", 5); } 
    
    return $NPP; 
}

#  Method to optimized data retrieval
#  input : $concept1 <- string containing a cui 1
#          $concept2 <- string containing a cui 2
#  output: reference to @data = (n_11, n_1p, n_p1)

sub _getData{
    
    my $self = shift;
    
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $function = "_getData"; 
    
    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check parameter exists
    if(!defined $concept1) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept1.", 4);
    }
    if(!defined $concept2) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept2.", 4);
    }
    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept1)) ) {
        return -1; #$errorhandler->_error($pkg, $function, "Concept ($concept1) does not exist.", 6);
    }    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept2)) ) {
        return -1; $errorhandler->_error($pkg, $function, "Concept ($concept2) does not exist.", 6);
    }    
    #  set up database
    my $dbh = $cuifinder->_getDB(); 
    
    my $queryString = 
    "SELECT N_11.n_11, N_1P.n_1p, N_P1.n_p1 FROM N_11
     JOIN N_1P ON (N_11.cui_1 = N_1P.cui_1)
     JOIN N_P1 ON (N_11.cui_2 = N_P1.cui_2)
     WHERE N_11.cui_1 = '$concept1' AND N_11.cui_2 = '$concept2'
     LIMIT 1;";
    
    my $sth = $dbh->prepare($queryString);
    $sth->execute() or die $DBI::errstr;
    my @data = ($sth->fetchrow_array());
    return \@data;
    

}

#  Method to optimized data retrieval (using the descendants of each cui)
#  input : $concept1 <- string containing a cui 1
#          $concept2 <- string containing a cui 2
#  output: reference to @data = (n_11, n_1p, n_p1)
sub _getDescendantData{
    
    my $self = shift;
    
    my $concept1 = shift;
    my $concept2 = shift;
    
    #  get descendants of each cui
    my @descendants1 =@{_findDescendants($concept1)};
    my @descendants2 = @{_findDescendants($concept2)};

    my $function = "_getData"; 
    
    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    #  check parameter exists
    if(!defined $concept1) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept1.", 4);
    }
    if(!defined $concept2) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$concept2.", 4);
    }
    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept1)) ) {
        return -1; #$errorhandler->_error($pkg, $function, "Concept ($concept1) does not exist.", 6);
    }    
    #  check if concept exists
    if(! ($cuifinder->_exists($concept2)) ) {
        return -1; $errorhandler->_error($pkg, $function, "Concept ($concept2) does not exist.", 6);
    }    
    #  set up database
    my $dbh = $cuifinder->_getDB(); 

    #build query string
     my $queryString = 
    "SELECT table1.A, table2.B, table3.C FROM
     ((SELECT SUM(n_11) as 'A' FROM  N_11 WHERE (N_11.cui_1 = '$concept1' ";
     
     foreach my $desc (@descendants1)
     {
	 $queryString .= "OR N_11.cui_1 = '$desc' ";
     }
    
    $queryString .= ") AND (N_11.cui_2 = '$concept2' ";

     foreach my $desc (@descendants2)
     {
	 $queryString .= "OR N_11.cui_2 = '$desc' ";
     }

     $queryString .= 
    ")) table1,
     (SELECT SUM(n_1p) as 'B' FROM N_1P WHERE (N_1P.cui_1 = '$concept1' ";
    
    foreach my $desc (@descendants1)
    {
        $queryString .= "OR N_1P.cui_1 = '$desc' ";
    }

    $queryString .=
    ")) table2,
     (SELECT SUM(n_p1) as 'C' FROM N_P1 WHERE (N_P1.cui_2 = '$concept2' ";

     foreach my $desc (@descendants2)
     {
	 $queryString .= "OR N_P1.cui_2 = '$desc' ";
     }

    $queryString .=
    ")) table3);";

    my $sth = $dbh->prepare($queryString);
    $sth->execute() or die $DBI::errstr;
    my @data = ($sth->fetchrow_array());
    $sth->finish();

    return \@data;
}

#  Method to retrieve descendants of a cui
#  input : $cui <- string containing a cui 
#  output: reference to @descendants, the descendants of the given cui
sub _findDescendants
{
    my $cui = shift;

    my $hashref = $umls->findDescendants($cui);
    my @descendants = (sort keys %{$hashref});
    return \@descendants;
}
    
sub _calculateStatistic { 
    my $self = shift;
    my $concept1 = shift; 
    my $concept2 = shift; 
    my $statistic = shift; 
    
    my $function = "_calculateStatistic"; 

    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }
    
    # get frequency and marginal totals optimized
    my $valid = -1;

    if($getdescendants)
    {
	 $valid = $self->_getDescendantData($concept1, $concept2);
    }
    else
    {
	$valid = $self->_getData($concept1, $concept2);
    }

    if($valid == -1){
        return -1;
    }
    my @data = @{$valid};
    
    #  get frequency and marginal totals
#    my $n11 = $self->_getFrequency($concept1, $concept2); 
#    my $n1p = $self->_getN1p($concept1); 
#    my $np1 = $self->_getNp1($concept2); 
    my $n11 = $data[0];
    my $n1p = $data[1];
    my $np1 = $data[2];

    if(!defined $n11 || !defined $n1p || !defined $np1){
         return -1;
    }
    
    
    my $npp = $self->_getNpp(); 
    
    # set frequency and marginal totals
    my %values = (n11=>$n11, 
		  n1p=>$n1p, 
		  np1=>$np1, 
		  npp=>$npp); 
    
    if($n11 < 0 || $n1p < 0 || $np1 < 0) { 
	return -1.000; 
    }
    
    if($n11 == 0) { 
	return 0.000;
    }
    
    #  set default statistic
    if(! defined $statistic) { $statistic = "tscore";  }
    
    #  set statistic module
    my $includename = ""; my $usename = "";  my $ngram = 2; 
    if($statistic eq "ll")  { 
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
    
    #  import module
    require $includename;
    import $usename;
    
    #  get statistics
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
	    print STDERR "Skipping ngram $concept1<>$concept2\n";
	    next; # if warning, dont save the statistic value just computed
	}
    }

    #return statistic to given precision.  if no precision given, default is 4
    my $floatFormat = join '', '%', '.', $precision, 'f';
    
    my $statScore = sprintf $floatFormat, $statisticValue;
    return $statScore; 
    

}

1;

__END__

=head1 NAME

UMLS::Association::StatFinder - provides the statistical association information 
of the concept pairs in the UMLS 

=head1 DESCRIPTION
For more information please see the UMLS::Association.pm documentation.

=head1 SYNOPSIS

 use UMLS::Association::StatFinder;
 use UMLS::Association::ErrorHandler;

 %params = ();

 $statfinder = UMLS::Association::StatFinder->new(\%params);
 die "Unable to create UMLS::Association::StatFinder object.\n" if(!$statfinder);

 my $cui1 = C0018563;   
 my $cui2 = C0446516; 

 #  get the frequecy
 my $freq = $statfinder->_getFrequency($cui1, $cui2); 

 #  get marginal totals
 my $np1 = $statfinder->_getNp1($cui2);
 my $n1p = $statfinder->_getN1p($cui1); 

 # calculate measure assocation
 my $measure = "ll"; 
 my $score = $statfinder->_calculateStatistic($cui1, $cui2, $measure); 

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

    perl Makefile.PL PREFIX=/home/bridget

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 SEE ALSO

L<http://tech.groups.yahoo.com/group/umls-similarity/>

=head1 AUTHOR

    Bridget T McInnes <bmcinnes@vcu.edu>
    Andriy Y. Mulyar  <andriy.mulyar@gmail.com>
    Alexander D. McQuilkin <alexmcq99@yahoo.com>

=head1 COPYRIGHT

    Copyright (c) 2015
    Bridget T. McInnes, Virginia Commonwealth University
    btmcinnes at vcu.edu

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
