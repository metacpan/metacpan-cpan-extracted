# UMLS::SenseRelate::ErrorHandler
# (Last Updated $Id: ErrorHandler.pm,v 1.2 2011/04/04 15:07:23 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2011,
#
# Bridget T. McIn nes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
# 
# Serguei Pakhomov, University of Minnesota, Twin Cities
# pakh0002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota, Twin Cities
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

package UMLS::SenseRelate::ErrorHandler;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;

#  Errors and their error codes
my $e1  = "Self is undefined (Error Code 1).";
my $e2  = "UMLS::Interface handler not defined (Error Code 2).";
my $e3  = "UMLS::Similarity measure handler not defined (Error Code 3).";
my $e4  = "Undefined input value (Error Code 4).";
my $e5  = "Data format error (Error Code 5).";

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

    print STDERR "ERROR: $pkg->$function\n";
    print STDERR "$errorstring\n";
    print STDERR "$string\n";

    exit;
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

UMLS::SenseRelate::ErrorHandler - A Perl module that provides the error 
handeling for the modules in the UMLS-SenseRelate package.

=head1 DESCRIPTION

This package provides the error handeling for the modules in the 
UMLS-SenseRelate package.

=head1 SYNOPSIS

  #!/usr/bin/perl

  use UMLS::SenseRelate::ErrorHandler();

  $errorhandler = UMLS::SenseRelate::ErrorHandler->new();
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

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 SEE ALSO

http://tech.groups.yahoo.com/group/umls-similarity/

http://search.cpan.org/dist/UMLS-Similarity/

=head1 AUTHOR

Bridget T McInnes <bthomson@cs.umn.edu>
Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT

 Copyright (c) 2007-2011
 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota Twin Cities
 liux0395 at umn.edu

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
