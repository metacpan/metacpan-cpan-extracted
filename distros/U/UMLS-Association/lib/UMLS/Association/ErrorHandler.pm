# UMLS::Association::ErrorHandler
#
# Perl module that provides a perl interface to the CUI network extracted 
# from the MetaMapped Medline Baseline
#
# This program borrows heavily from the UMLS::Interface package.
#
# Copyright (c) 2015,
#
# Bridget T. McInnes, Virginia Commonwealth University 
# btmcinnes at vcu.edu
#
# Keith Herbert, Virginia Commonwealth University
# herbertkb at vcu.edu
#
# Sam Henry, Virginia Commonwealth University
# henryst at vcu.edu
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

package UMLS::Association::ErrorHandler;

use Fcntl;
use strict;
use warnings;
use bytes;

#  Errors and their error codes
my $e1  = "Database error (Error Code 1).";
my $e2  = "Self is undefined (Error Code 2).";
my $e3  = "A db is required (Error Code 3).";
my $e4  = "Undefined input value (Error Code 4).";
my $e5  = "NPP is zero or less error (Error Code 5).";
my $e6  = "Invalid CUI (Error Code 6).";
my $e7  = "UMLS::Association Database Content Error (Error Code 7).";
my $e8  = "UMLS::Association Package Error (Error Code 8).";
my $e9  = "Index Error (Error Code 9).";
my $e10 = "Option Error (Error Code 10).";
my $e11 = "Unsupported Option Error (Error Code 11).";
my $e12 = "Input parameter error (Error Code 12).";

#  throws an error and exits the program
#  input : $pkg       <- package the error originated
#          $function  <- function the error originated
#          $string    <- error message
#          $errorcode <- error code
#  output:
sub _error {

    my $self      = shift;
    my $pkg       = shift;
    my $function  = shift;
    my $string    = shift;
    my $errorcode = shift;
    
    my $errorstring = "";

    if($errorcode eq 1)  { $errorstring = $e1;  }
    if($errorcode eq 2)  { $errorstring = $e2;  }
    if($errorcode eq 3)  { $errorstring = $e3;  }
    if($errorcode eq 4)  { $errorstring = $e4;  }
    if($errorcode eq 5)  { $errorstring = $e5;  }
    if($errorcode eq 6)  { $errorstring = $e6;  }
    if($errorcode eq 7)  { $errorstring = $e7;  }
    if($errorcode eq 8)  { $errorstring = $e8;  }
    if($errorcode eq 9)  { $errorstring = $e9;  }
    if($errorcode eq 10) { $errorstring = $e10; }
    if($errorcode eq 11) { $errorstring = $e11; }
    if($errorcode eq 12) { $errorstring = $e12; }

    print STDERR "ERROR: $pkg->$function\n";
    print STDERR "$errorstring\n";
    print STDERR "$string\n";

    exit;
}

#  checks the database for an error
#  input : $pkg      => the Finder program
#          $function => the function in the finder program
#          $db       => the database handler
#  output: 
sub _checkDbError {

    my $self     = shift;
    my $pkg      = shift;
    my $function = shift;
    my $db       = shift;

    my $errorcode = 1;
    
    if($db->err()) {
	my $errstring = "Error executing database query: $db->errstr()).";
	$self->_error($pkg, $function, $errstring, $errorcode);
    }
    else {
	return;
    }
}

#  subroutine to check if CUI is valid
#  input : $concept       <- string containing a cui
#  output: true | false   <- integer indicating if the cui is valid
sub _validCui {

    my $self = shift;
    my $concept = shift;
    
    if($concept=~/C[0-9][0-9][0-9][0-9][0-9][0-9][0-9]/) {
	return 1;
    }
    else {
	return 0;
    }
}

#  sets up the error handler module
#  input : $parameters <- reference to a hash
#  output: $self
sub new {

    my $self = {};
    my $className = shift;
 
    # Bless the object.
    bless($self, $className);

    return $self;
}
1;
__END__

=head1 NAME

UMLS::Association::ErrorHandler - provides the error handeling for the modules 
in the UMLS-Association package.

=head1 DESCRIPTION

This package provides the error handeling for the modules 
in the UMLS-Association package.

For more information please see the UMLS::Association documentation. 

=head1 SYNOPSIS

  use UMLS::Association::ErrorHandler();

  $errorhandler = UMLS::Association::ErrorHandler->new();
  if(! defined $errorhandler) {
    print STDERR "The error handler did not get passed properly.\n";
    exit;
  }

  $concept = "C012";
  $pkg = "Package";
  $function = "function";

  if(! ($errorhandler->_validCui($concept)) ) {
    $errorhandler->_error($pkg, 
                          $function,   
                          "Incorrect input value ($concept)", 
                          6);
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

=head1 SEE ALSO

=head1 AUTHOR

Bridget T McInnes <btmcinnes@vcu.edu>

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
