package Lisp::Printer;

use strict;
use vars qw(@EXPORT_OK $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use Lisp::Symbol qw(symbolp);
use Lisp::Vector qw(vectorp);
use Lisp::Cons   qw(consp);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(lisp_print);

sub dump
{
    require Data::Dumper;
    Data::Dumper::Dumper($_[0]);
}

sub lisp_print
{
    my $obj = shift;
    my $str = "";
    if (ref($obj)) {
	if (symbolp($obj)) {
	    $str = $obj->name;
	} elsif (vectorp($obj)) {
	    $str = "[" . join(" ", map lisp_print($_), @$obj) . "]";
	} elsif (ref($obj) eq "Lisp::Cons") {
	    $str = "(" .join(" . ", map lisp_print($_), @$obj). ")";
	} elsif (ref($obj) eq "ARRAY") {
	    $str = "(" . join(" ", map lisp_print($_), @$obj) . ")";
	} elsif (ref($obj) eq "HASH") {
	    # make it into an alist
	    $str = "(" . join("",
			      map {"(" . lisp_print($_) .
                                         " . " .
					 lisp_print($obj->{$_}) .
                                    ")"
				  } sort keys %$obj) .
                   ")";
	} else {
	    $str = "#<$obj>";
	}
    } else {
	# XXX: need real number/string type info
	if (!defined($obj)) {
	    $str = "nil";
	} elsif ($obj =~ /^[+-]?\d+(?:\.\d*)?$/) {
	    # number
	    $str = $obj + 0;
	} else {
	    # string
	    $obj =~ s/([\"\\])/\\$1/g;  # quote special chars
	    $str = qq("$obj");
	}
    }
    $str;
}

1;
