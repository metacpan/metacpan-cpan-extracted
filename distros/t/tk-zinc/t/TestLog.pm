package TestLog;

# $Id: TestLog.pm,v 1.4 2005/01/16 10:27:35 mertz Exp $
# These test facilities has been developped by C. Mertz <mertz@cena.fr>

use IO::Handle;    # for autoflushing the logs
use Carp;

use Exporter;
@ISA = qw(Exporter);

use vars qw( $VERSION @ISA);
($VERSION) = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
@EXPORT = qw( openLog setZincLog log test_eval test_no_eval printableItem printableArray printableList
	      equal_flat_arrays nequal_cplx_arrays);
use strict;

use constant ERROR => '--an error--';

my $selected_loglevel;

sub openLog {
    my ($outfile, $loglevel, $no_logfile) = @_;

    $selected_loglevel = $loglevel;
    if (defined $no_logfile && $no_logfile) {
      open LOG, "> /dev/null";
    }
    else {
      if ( open LOG, "$outfile.prev" ) {
	close LOG;
	unlink "$outfile.prev";
      }
      if ( open LOG, $outfile ) {
	close LOG;
	link $outfile, "$outfile.prev";
	unlink "$outfile";
      }
      
      open LOG,"> $outfile";
      autoflush LOG 1;  # autoflush is important so that logs are up-to-date if Zinc crashes!
    }
}



### print log information to the logfile
### if $level is <= than selected_loglevel (def = 0) then print log on the stdout
###  - a loglevel of -100 means an error to be logged with #### prefix
###  - a loglevel of -10 means an error in the test to be logged with ## prefix
###  - a loglevel of 0 means an message to be usually printed (and logged in any case)
###  - a loglevel greater than 1 is for trace only


sub log {
    my ($loglevel, @strgs) = @_;
    if ($loglevel <= $selected_loglevel) {
	print "#### " if $loglevel == -100;
	print "## " if $loglevel == -10;
	print @strgs;
    }
    print LOG "#### " if $loglevel == -100;
    print LOG "## " if $loglevel == -10;
    print LOG @strgs;
} # end log

my $zinc;
## to init the $zinc
sub setZincLog {
    ($zinc)=@_;
}


my %method_with_tagOrId =
    ("anchorxy" => 1, "bbox" => 1, "bind" => 1, "chggroup" => 1,
     "clone" => 1, "contour" => 1, "coords"=> 1, "cursor" => 1,
     "dchars" => 1, "dtag" => 1, "focus" => 1, "gettags" => 1,
     "group" => 1, # blabla... to complete
     "itemcget" => 1, "itemconfigure" => 1, # blabla... to complete
     "remove" => 1,
     );

###  evaluate $zinc->$method(@args); and verifies that NO ERROR occurs
###  - a loglevel of -100 means an error to be logged with #### prefix
###  - a loglevel of -10 means an error in the test, to be logged with ##
###  - a loglevel of of 0 or greater is for trace only (usefull when an error occurs)
sub test_eval {
    my ($loglevel, $method, @args) = @_;

    my @strs;
    my $start_index = 0;
    my $string2log = "\$zinc->$method (";
    if (scalar @args) {
	if ($method_with_tagOrId{$method} and $args[0] =~ /^\d+$/) {
	    my $type = $zinc->type($args[0]);
	    $string2log .= &printableItem($args[0]) . " (a". ucfirst($type) . ")";
	} else {
	    $string2log .= &printableItem($args[0]) ;
	    }
	$string2log .= ", " if $#args > 0 ;
	my $rest = &printableList(@args[1..$#args]);
	$rest =~ s/^\(//;   ### suppressing the first ( char
	$string2log .= $rest;
    } else {
	$string2log .= ")";
    }
    if ($method eq 'itemcget' or $method eq 'get') {
	$string2log .=  "; #  :=  " ;
    } else {
	$string2log .=  ";\n";
    }
    &log ($loglevel, $string2log);
    
    my (@res, $res);
    if (wantarray()) {
	@res = eval { $zinc->$method (@args) } ;
	if ($method eq 'itemcget' or $method eq 'get') {
	    &log ($loglevel, printableList(@res) . "\n" );
	}
    } else {
	$res = eval { $zinc->$method (@args) } ;
	if ($method eq 'itemcget' or $method eq 'get') {
	    &log ($loglevel, &printableItem($res) . "\n");
	}
    }
    
    if ($@) { # in case of error, logging!
	&log (-100, "Error while evaluating: $string2log;");
	&log (-100, $@);
	my $msgl = &Carp::longmess;
	my ($msg2) = $msgl =~ /.*?( at .*)/s ; 
	&log (-100, "\t$msg2");
	return (ERROR);
    } else {
	if (wantarray()) {
	    return @res;
	}
	else {
	    return $res;
	}
    }
} # end of test_eval

###  evaluate $zinc->$method(@args); and verifies that AN ERROR occurs
###  - a loglevel of -100 means an NO error to be loggued with #### prefix
###  - a loglevel of -10 means NO error in the test to be loggued with ## prefix
###  - a loglevel of of 0 or greater is for trace only if NO error occured
sub test_no_eval {
    my ($reason, $loglevel, $method, @args) = @_;

    my @strs;
    my $start_index = 0;
    my $string2log = "\$zinc->$method (";
    if (scalar @args) {
	if ($method_with_tagOrId{$method} and $args[0] =~ /^\d+$/) {
	    my $type = $zinc->type($args[0]);
	    $string2log .= &printableItem($args[0]) . " (a". ucfirst($type) . ")";
	} else {
	    $string2log .= &printableItem($args[0]) ;
	    }
	$string2log .= ", " if $#args > 0 ;
	my $rest = &printableList(@args[1..$#args]);
	$rest =~ s/^\(//;   ### suppressing the first ( char
	$string2log .= $rest;
    } else {
	$string2log .= ")";
    }
    
    eval { $zinc->$method (@args) } ;

    # in case of NO error, logging!
    if ($@) {
#	print "errormsg=$@"; 
	my ($error_msg) = $@ =~ /(.*)\s*at \/usr\//;
	$error_msg = $@ if !defined $error_msg ;
	&log ($loglevel, "  # When $reason : $string2log;\n  # the error msg is: $error_msg\n");
    } else {
	&log (-100, "An error SHOULD have occured  while evaluating:\n####\t$string2log;\n####\tbecause $reason\n");
    }
} # end of test_no_eval


### return a printable string of something in a readable form
sub printableItem {
    my ($value) = @_;
    my $ref = ref($value);
    if ($ref eq 'ARRAY') {
	return printableArray ( @{$value} );
    }
    elsif ($ref eq 'Tk::Photo') {
	return 'Tk::Photo("'. $value->cget(-file) . '")';
    }
    elsif ($ref eq '') {  # scalar 
	if (defined $value) {
	    if ($value eq '') {
		return  "''";
	    } elsif ($value =~ /^-[a-zA-Z_]+$/) {
		## for the -attribut
		return $value;
	    } elsif ($value =~ /\s/
		     or $value =~ /[a-zA-Z]/
		     or $value =~ /^[\W]$/ ) {
		return "'$value'";
	    }  else {
		return $value;
	    }
	}
	else {
	    return "undef";
	}
    }
    else { # some  class instance
	return $value;
    }
} # end printableItem

### to print an array of something
sub printableArray {
    my (@values) = @_;
    if (! scalar @values) {
	return "[]";
    }
    else {  # the array is not empty
	my $res = "[ ";
	while (@values) {
	    my $value = shift @values;
	    $res .= &printableItem($value);
	    next unless (@values); 
	    if ($value =~ /^-\w+/) {
		$res .= " => ";
	    } elsif (@_) {
		$res .= ", ";
	    }
	    
	}
	return ($res . " ]") ;
    }
} # end printableArray

sub printableList {
    my $res = "(";
    while (@_) {
	my $v = shift @_;
	$res .= &printableItem($v);
	if (defined $v and $v =~ /^-\w+/ and @_) {
	    $res .= " => ";
	} elsif (@_) {
	    $res .= ", ";
	}
    }
    return $res . ")";
} # end printableList


## return 1 if arrays of scalars have the same length and every items are eq 
sub equal_flat_arrays {
    my ($refArray1, $refArray2) = @_;
    my @array1 = @{$refArray1};
    my @array2 = @{$refArray2};

    return 0 if ($#array1 != $#array2);

    for my $i (0..$#array1) {
	return 0 if ($array1[$i] ne $array2[$i]);
    }
    return 1;
} # equal_arrays


## return 0 if arrays of anything are equal
## return 'length' if their length are different
## return xx if some elements are différents
## arrays may be arrays of arrays of arrays ...
sub nequal_cplx_arrays {
    my ($refArray1, $refArray2) = @_;
    my @array1 = @{$refArray1};
    my @array2 = @{$refArray2};

#    print "array1=", &printableArray(@array1), "\narray2=",&printableArray(@array2),"\n";
    return 'length' if ($#array1 != $#array2);

    for my $i (0..$#array1) {
	my $el1 = $array1[$i];
	my $el2 = $array2[$i];
	
	if (ref($el1)) {
#	    print "REF el1=",ref($el1),"\n";
	    if (!ref($el2)) {
		return "elts at index $i are different: $el1 != $el2\n";
	    } elsif (ref($el2) ne ref($el1)) {
		return "elts at index $i are of different type: ".
		    ref($el2), " ne ", ref($el1), "\n";
	    } elsif (ref($el2) eq 'ARRAY') {
		if (my $res = &nequal_cplx_arrays ($el1,$el2)) {
		    return "elts at index $i are different: $res";
		}
	    }
	} elsif (ref($el2) or $el1 ne $el2) {
	    return "elts at index $i are different $el1 != $el2\n";
	}
    }
    return 0;
} # nequal_cplx_arrays


1;
