package Tk::Zinc::TraceUtils;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Font;
use Tk::Photo;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(printItem printArray printList Item Array List);

use strict;

sub printItem {
    print &Item (@_);
}

sub printArray {
    print &Array (@_);
}

sub printList {
    print &List (@_);
}


### to print something
sub Item {
    my ($value) = @_;
    my $ref = ref($value);
#    print "VALUE=$value REF=$ref\n";
    if ($ref eq 'ARRAY') {
	return Array ( @{$value} );
    } elsif ($ref eq 'CODE') {
	return "{CODE}";
    } elsif ($ref eq 'Tk::Photo') {
#	print " **** $value ***** ";
	return "Tk::Photo(\"". scalar $value->cget('-file') . "\")";
    } elsif ($ref eq 'Tk::Font') {
	return "'$value'";
    } elsif ($ref eq '') {  # scalar 
	if (defined $value) {
          if ($value =~ /^-[a-zA-Z]([\w])*$/) { # -option1 or -option-1
            return $value;
          } elsif ($value =~ /^-?\d+(\.\d*(e[+-]?\d+)?)?$/) { # -1. or 1.0 or -1.2e+22  or 1.02e+034
            if ($value =~ /(.*[-+]e)0+(\d+)/) {   # removing the 0 after e+ or e-
              return $1.$2;
            } else {
              return $value;
            }
          } elsif ($value eq ''
                   or $value =~ /\s/
                   or $value =~ /^[a-zA-Z]/
                   or $value =~ /^[\W]/
                  ) {
            return "'$value'";
          } else {
            return $value;
          }
	} else {
	    return "_undef";
	}
    } else { # some  class instance
	return $value;
    }
    
} # end Item


### to print a list of something
sub Array {
    my (@values) = @_;
    if (! scalar @values) {
	return "[]";
    }
    else {  # the list is not empty
	my $res = "[";
	while (@values) {
	    my $value = shift @values;
	    $res .= &Item ($value);
	    $res .= ", " if (@values);
	}
	return $res. "]" ;
    }
    
} # end Array


sub List {
    my $res = "(";
    while (@_) {
	my $v = shift @_;
	$res .= Item ($v);
	if (@_ > 0) {
	    ## still some elements
	    if ($v =~ /^-\d+$/) {
		$res .= ", ";
	    } elsif ($v =~ /^-\w+$/) {
		$res .= " => ";
	    } else {
		$res .= ", ";
	    }
	}
    }
    return $res. ")";
    
} # end List


1;



