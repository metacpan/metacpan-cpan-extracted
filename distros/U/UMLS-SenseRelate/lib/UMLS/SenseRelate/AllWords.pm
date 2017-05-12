# UMLS::SenseRelate::AllWords
# (Last Updated $Id: AllWords.pm,v 1.12 2012/04/13 22:09:37 btmcinnes Exp $)
#
# Perl module that performs SenseRelate style WSD
#
# Copyright (c) 2010-2012,
#
# Bridget T. McInnes, University of Minnesota Twin Cities
# bthomson at umn.edu
# 
# Serguei Pakhomov, University of Minnesota Twin Cities
# pakh0002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota
# liux0935 at umn.edu
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

package UMLS::SenseRelate::AllWords;

use UMLS::SenseRelate;
use UMLS::SenseRelate::TargetWord;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;

use UMLS::Interface;
use UMLS::Similarity;
use UMLS::SenseRelate::ErrorHandler;

use vars qw($VERSION);
$VERSION = '0.05';

#  module handler variables
my $umls         = "";
my $mhandler     = "";
my $twhandler    = "";
my $errorhandler = "";

#  senserelate options
my $stoplist      = undef;
my $stopregex     = undef;
my $window        = undef;
my $compound      = undef;
my $trace         = undef;
my $measure       = undef;
my $senses        = undef;
my $weight        = undef;

local(*TRACE);

my %cache = ();

my $pkg = "UMLS::SenseRelate::AllWords";

my $debug = 0;


# -------------------- Class methods start here --------------------

#  method to create a new UMLS::Similarity object
#  input : $params <- reference to hash containing the parameters 
#  output:
sub new {

    my $self        = {};
    my $className   = shift;
    my $umlshandler = shift;
    my $meashandler = shift;
    my $params    = shift;

    my $function = "new";

    # bless the object.
    bless($self, $className);

    #  check the measure handler was passed properly
    if(! defined $meashandler) {
	print STDERR "The UMLS::Similarity handler did not get passed properly.\n";
	exit;
    }
    
    #  check the measure handler was passed properly
    if(! defined $umlshandler) {
	print STDERR "The UMLS::Interface handler did not get passed properly.\n";
	exit;
    }

    #  set the umls interface and similarity handlers
    $umls = $umlshandler; $mhandler = $meashandler;

    # initialize error handler
    $errorhandler = UMLS::SenseRelate::ErrorHandler->new();
    if(! defined $errorhandler) {
	print STDERR "The error handler did not get passed properly.\n";
	exit;
    }
    
    #  check options
    $self->_setOptions($params);

    #  set the senserelate target word handler
    $twhandler = $self->_setTargetWordSenseRelate();

    return $self;
}


#  method sets the parameters for the UMLS::SenseRelate package
#  input : $params <- reference to hash containing the parameters 
#  output:
sub _setOptions {

    my $self = shift;
    my $params = shift;

    my $function = "_checkOptions";

    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 1);
    }
    
    $params = {} if(!defined $params);

    #  get all the parameters
    $stoplist      = $params->{'stoplist'};
    $window        = $params->{'window'};
    $weight        = $params->{'weight'};
    $compound      = $params->{'compound'};
    $trace         = $params->{'trace'};
    $measure       = $params->{'measure'};
    $senses        = $params->{'candidates'};

    #  set the measure
    if(! (defined $measure)) { 
	$measure = "path";
    }
}

#  load the Umls-Allwords-Senserelate package
sub _setTargetWordSenseRelate {

    my $self = shift;
    
    my $function = "_setTargetWordSenseRelate";
    
    my %option_hash = ();
    
    $option_hash{"window"}   = $window;

    if(defined $compound) { $option_hash{"compound"} = $compound; }
    if(defined $weight)   { $option_hash{"weight"} = $weight;     }
    if(defined $stoplist) { $option_hash{"stoplist"} = $stoplist; }
    if(defined $trace)    { $option_hash{"trace"}    = $trace;    }

    $option_hash{"measure"} = $measure;

    my $handler = UMLS::SenseRelate::TargetWord->new($umls, 
						     $mhandler, 
						     \%option_hash); 
    
    die "Unable to create UMLS::SenseRelate::TargetWord object.\n" if(!$handler);
    return $handler;
   
}

#  method sets the stoplist
#  input : $instance     <- string containing the instance
#  output: \@assignments <- reference to an array containing the assignments
#
sub assignSenses {
    
    my $self      = shift;
    my $instance  = shift;
    
    my $function = "assignSenses";
    
    #  check self
    if(!defined $self || !ref $self) {
	$errorhandler->_error($pkg, $function, "", 1);
    }
    
    #  initialize the assignments
    my @assignments = ();

    my @words = @{$instance};
    
    for my $i (0..$#words) { 
	
        #  get the target word
	my $tw = $words[$i];

	#  check if it is a word to be disambiguated
	if(! ($tw=~/<(head|sat) id/)) { next; }

	#  get the instance
	my @context = @{$instance};
	
	#  get the context before and after the target word
	my $j = $i-1;
	my $k = $i+1;
	my $z = $#context;
	
	my @front = (); my @end   = ();
	if($i > 0)         { @front = @context[0..$j];  }
	if($i < $#context) { @end   = @context[$k..$z]; }
	my $f = join " ", @front; my $e = join " ", @end;
	
	#  get the id 
	$tw=~/ id=\"(.*?)\"/;
	my $id = $1;
	
	#  get the sense information if defined
	my @candidates = ();
	if(defined $senses) { 
	    $tw=~/candidates=\"(.*?)\"/;
	    my $possibles = $1;
	    @candidates = split/\,/, $possibles;
	}

	#  remove the head information
	$f=~s/<(head|sat) id=\"(.*?)\"( sats=\".*?\")?( candidates=\"(.*?))?( sense=\"(.*?))?>//g;  
	$f=~s/<\/(head|sat)>//g;	
	$e=~s/<(head|sat) id=\"(.*?)\"( sats=\".*?\")?>//g;  
	$e=~s/<(head|sat) id=\"(.*?)\"( sats=\".*?\")?( candidates=\"(.*?))?( sense=\"(.*?))?>//g;  
	$e=~s/<\/(head|sat)>//g;
	$tw=~s/<(head|sat) id=\"(.*?)\"( sats=\".*?\")?( candidates=\"(.*?))?( sense=\"(.*?))?>//g;  
	$tw=~s/<\/(head|sat)>//g;
	
	#  set up the line for target word module
	my $line = "$f <head item=\"$tw\" instance=\"$id\">$tw<\/head> $e\n";

	#  clean the line and target word up
	$line=~s/\'//g; $tw=~s/\'//g;
	
	#  remove before and after white space
	$tw=~s/^\s+//g;	$tw=~s/\s+$//g;
       
	#  assign sense to the word
	my $hashref = undef;
	if(defined $senses) { 
	    ($hashref) = $twhandler->assignSense($tw, $line, \@candidates);
	}
	else {
	    ($hashref) = $twhandler->assignSense($tw, $line, undef);
	}

	#  get the assigned sense
	my $assignment = "";
	foreach my $el (sort keys %{$hashref}) { 
	    $assignment .= "$tw/$el ";
	}

	
	#  if no senses were assigned
	if($assignment eq "") { $assignment .= "/NA "; }

	#  remove the white space
	chop $assignment;

	push @assignments, "$id $tw%$assignment";
    
    }

    return \@assignments;
}

#  print out the function name to standard error
#  input : $function <- string containing function name
#  output:
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::SenseRelate::$function\n"; }
}

1;

__END__

=head1 NAME

UMLS::SenseRelate::AllWords - A Perl module that implement the
all-words word sense disambiguation using the sense relate wsd 
algorithm based on the  semantic similarity and relatedness options 
from the UMLS::Similarity package.

=head1 DESCRIPTION

This package provides an implementation of the senserelate word sense 
disambiguation algorithm using the semantic similarity and relatedness 
options from the UMLS::Similarity package.

=head1 SYNOPSIS

 use UMLS::Similarity;
 use UMLS::SenseRelate::AllWords;

 #  initialize option hash and umls
 my %option_hash = ();
 my $umls        = "";
 my $meas        = "";
 my $senserelate = "";
 my $params      = "";

 #  set interface     
 $option_hash{"t"} = 1;
 $option_hash{"realtime"} = 1;
 $umls = UMLS::Interface->new(\%option_hash);

 #  set measure
 use UMLS::Similarity::path;
 $meas = UMLS::Similarity::path->new($umls);

 #  set senserelate
 $params{"measure"} = "path";
 $params{"candidates"} = 1;
 $senserelate = UMLS::SenseRelate::AllWords->new($umls, $meas, \%params);


 #  set the context array
 my @context = ();
 push @context, "<head id=\"d001.s001.t001\" candidates=\"C1280500,C2348382\">effect</head>";
 push @context, "of";
 push @context, "the";
 push @context, "duration";
 push @context, "of";
 push @context, "prefeeding";
 push @context, "on";
 push @context, "<head id=\"d001.s001.t008\" candidates=\"C0001128,C0002520\">amino acid</head>";
 push @context, "digestibility";
 push @context, "of";
 push @context, "<head id=\"d001.s001.t011\" candidates=\"C0043137,C0087114\">wheat</head>";
 push @context, "distillers";

 my $arrayref = $senserelate->assignSenses(\@context);

 foreach my $element (@{$arrayref}) { 
     print "$element\n";
 }

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

=head1 PARAMETERS

=head2 UMLS::SenseRelate parameters

  'window'       -> This parameter determines the window size of the 
                    context on each side of the target word to be used 
                    for disambiguation
  'weight'       -> This parameter weights the similarity scores based
                    on how far the term or word is from the target word
  'stoplist'     -> This parameter disregards stopwords when creating 
                    the window created on the fly (in realtime). 

  'compound'     -> This parameter indicates that compounds exist in 
                    the input instance denoted by an underscore

  'trace'        -> This parameters indicates that the trace information
                    should be printed out to the file 

=head1 SEE ALSO

http://tech.groups.yahoo.com/group/umls-similarity/

http://search.cpan.org/dist/UMLS-Similarity/

=head1 AUTHOR

Bridget T McInnes <bthomson@umn.edu>
Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT

 Copyright (c) 2010-2012
 Bridget T. McInnes, University of Minnesota Twin Cities
 bthomson at umn.edu

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota Twin Cities
 liux0935 at umn.edu

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
