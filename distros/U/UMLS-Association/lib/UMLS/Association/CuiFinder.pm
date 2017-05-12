# UMLS::Association::CuiFinder
#
# Perl module that provides a perl interface to the
# semantic network extracted from the MetaMapped Medline Baseline
#
# This program borrows heavily from the UMLS::Interface package.x
#
# Copyright (c) 2015,
#
# Bridget T. McInnes, Virginia Commonwealth University 
# btmcinnes at vcu.edu
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

package UMLS::Association::CuiFinder;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;
use File::Spec;

#  error handling variables
my $errorhandler = "";
my $pkg = "UMLS::Association::CuiFinder";

#  debug variables
local(*DEBUG_FILE);

#  global variables
my $debug     = 0;
my $option_t; 


######################################################################
#  functions to initialize the package
######################################################################

#  method to create a new UMLS::Association::CuiFinder object
#  input : $parameters <- reference to a hash of parameters
#  output: $self
sub new {

    my $self = {};
    my $className = shift;
    my $params = shift;

    # bless the object.
    bless($self, $className);

    # initialize error handler
    $errorhandler = UMLS::Association::ErrorHandler->new();
    if(! defined $errorhandler) {
        print STDERR "The error handler did not get passed properly.\n";
        exit;
    }

    #  initialize global variables
    $debug = 0; 

    # initialize the object.
    $self->_initialize($params);

    return $self;
}

#  method to initialize the UMLS::Association::CuiFinder object.
#  input : $parameters <- reference to a hash
#  output:
sub _initialize {

    my $self = shift;
    my $params = shift;

    my $function = "_initialize";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    $params = {} if(!defined $params);

    #  to set and store the database object
    $self->_setDatabase($params);

    #  set up the options
    $self->_setOptions($params);

    #  check that all of the tables required exist in the db
    $self->_checkTablesExist();

}
 
#  method to set the association database
#  input : $params <- reference to a hash
#  output:
sub _setDatabase  {

    my $self   = shift;
    my $params = shift;

    my $function = "_setDatabase";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the params
    $params = {} if(!defined $params);

    #  get the database connection parameters
    my $database     = $params->{'database'};
    my $hostname     = $params->{'hostname'};
    my $socket       = $params->{'socket'};
    my $port         = $params->{'port'};
    my $username     = $params->{'username'};
    my $password     = $params->{'password'};

    #  set up defaults if the options were not passed
    if(! defined $database) { $database = "cuicounts";            }
    if(! defined $socket)   { $socket   = "/var/run/mysqld/mysqld.sock"; }
    if(! defined $hostname) { $hostname = "localhost";       }

    #  initialize the database handler
    my $db = "";

    #  create the database object...
    if(defined $username and defined $password) {
        if($debug) { print STDERR "Connecting with username and password\n"; }
        $db = DBI->connect("DBI:mysql:database=$database;mysql_socket=$socket;host=$hostname",$username, $password, {RaiseError => 0});
    }
    else {
        if($debug) { print STDERR "Connecting using the my.cnf file\n"; }
        my $dsn = "DBI:mysql:umls;mysql_read_default_group=client;database=$database";
        $db = DBI->connect($dsn);
    }

    #  check if there is an error
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  check that the db exists
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  set database parameters
    $db->{'mysql_enable_utf8'} = 1;
    $db->do('SET NAMES utf8');
    $db->{mysql_auto_reconnect} = 1;

    #  set the self parameters
    $self->{'db'}           = $db;
    $self->{'username'}     = $username;
    $self->{'password'}     = $password;
    $self->{'hostname'}     = $hostname;
    $self->{'socket'}       = $socket;
    $self->{'database'}     = $database;

}

#  function checks to see if a given table exists
#  input : $table <- string
#  output: 0 | 1  <- integers
sub _checkTableExists {

    my $self  = shift;
    my $table = shift;

    my $function = "_checkTableExists";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if(!defined $table) {
        $errorhandler->_error($pkg, $function, "Error with input variable \$table.", 4);
    }

    #  check that the database exists
    my $sdb = $self->{'sdb'};
    if(!$sdb) { $errorhandler->_error($pkg, $function, "Error with sdb.", 3); }

    #  set an execute the query to show all of the tables
    my $sth = $sdb->prepare("show tables");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    my $t      = "";
    my %tables = ();
    while(($t) = $sth->fetchrow()) {
        $tables{lc($t)} = 1;
    }
    $sth->finish();

    if(! (exists$tables{lc($table)})) { return 0; }
    else                              { return 1; }

}

#  return the database connection to the bigram database
#  input :
#  output: $db <- database handler
sub _getDB {
    my $self = shift;

    my $function = "_getDB";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  get the databawse
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  return the database
    return $db;
}

#  check if the bigram score tables required all exist
#  input :
#  output:
sub _checkTablesExist {

    my $self = shift;

    my $function = "_checkTablesExist";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  set up the database
    my $db = $self->{'db'};
    if(!$db) { $errorhandler->_error($pkg, $function, "Error with db.", 3); }

    #  check if the tables exist...
    my $sth = $db->prepare("show tables");
    $sth->execute();
    $errorhandler->_checkDbError($pkg, $function, $sth);

    my $table = "";
    my %tables = ();
    while(($table) = $sth->fetchrow()) {
        $tables{$table} = 1;
    }
    $sth->finish();

    if(!defined $tables{"N_11"}) { 
        $errorhandler->_error($pkg, $function, "Table N_11 not found in database", 7);
    }
    if(!defined $tables{"N_P1"}) { 
        $errorhandler->_error($pkg, $function, "Table N_P1 not found in database", 7);
    }
    if(!defined $tables{"N_1P"}) { 
        $errorhandler->_error($pkg, $function, "Table N_1P not found in database", 7);
    }
    if(!defined $tables{"N_PP"}) { 
        $errorhandler->_error($pkg, $function, "Table N_PP not found in database", 7);
    }
}

#  method to set the global parameter options
#  input : $params <- reference to a hash
#  output:
sub _setOptions  {
    my $self = shift;
    my $params = shift;

    my $function = "_setOptions";
    &_debug($function);

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    #  check the params
    $params = {} if(!defined $params);

    #  get all the parameters
    my $t                     = $params->{'t'};
    my $debugoption  = $params->{'debug'};
    
    if(defined $t) {
        $option_t = 1;
    }
        
    if(defined $debugoption) { 
	$debug = $debugoption;
    }
}



#  method to destroy the created object.
#  input :
#  output:
sub _disconnect {
    my $self = shift;

    my $function = "_disconnect";

    #  check self
    if(!defined $self || !ref $self) {
        $errorhandler->_error($pkg, $function, "", 2);
    }

    if($self) {
        my $db = $self->{'db'};
        $db->disconnect() if($db);
    }
}

sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In UMLS::Association::CuiFinder::$function\n"; }
}

#  Method to check if a CUI exists in the database.
#  input : $concept <- string containing a cui
#  output: $bool    <- string indicating if the cui exists
sub _exists {

    my $self = shift;
    my $concept = shift;

    my $function = "_exists";

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
   
    #  set up database
    my $db = $self->_getDB(); 

   my $arrRef = $db->selectcol_arrayref("select * from N_11 where cui_1='$concept' or cui_2='$concept' LIMIT 1"); 

    #  check the database for errors
    $errorhandler->_checkDbError($pkg, $function, $db);

    #  get the count
    my $count = scalar(@{$arrRef});

    return 1 if($count); return 0;
}
 
#  Method to return 'parents' of a CUI
#  input: $concept <- string containing cui
#  output: $array <- reference to an array containing a list of cuis
sub _getParents { 

    my $self    = shift;
    my $concept = shift;
    
    my $function = "_getParents";
    
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
    
    #  connect to the database
    my $db = $self->_getDB(); 
    
    my $arrRef = $db->selectcol_arrayref("select distinct cui_1 from N_11 where cui_2='$concept'"); 
    
    return $arrRef; 
}

#  Method to return 'children' of a CUI
#  input: $concept <- string containing cui
#  output: $array <- reference to an array containing a list of cuis
sub _getChildren { 

    my $self    = shift;
    my $concept = shift;
    
    my $function = "_getChildren";
    
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
    
    #  connect to the database
    my $db = $self->_getDB(); 
    
    my $arrRef = $db->selectcol_arrayref("select distinct cui_2 from N_11 where cui_1='$concept'"); 
    
    return $arrRef; 
}

1;

__END__

=head1 NAME

UMLS::Association::CuiFinder - provides the information about CUIs 
in the association database for the modules in the UMLS::Association package.

=head1 DESCRIPTION

For more information please see the UMLS::Association.pm documentation.

=head1 SYNOPSIS

 use UMLS::Association::CuiFinder;
 use UMLS::Association::ErrorHandler;

 %params = ();

 $cuifinder = UMLS::Association::CuiFinder->new(\%params);
 die "Unable to create UMLS::Association::CuiFinder object.\n" if(!$cuifinder);

 #  _getChildren returns all the concepts in the second 
 #  position where $concept is in the first
 $array = $cuifinder->_getChildren($concept);
 print "Children of $concept @{$array}\n";

 # _getParent returns all the concepts in the first 
 # position where $concept is in the second
 $array = $cuifinder->_getParents($concept);
 print "Parents of $concept: @{$array}\n\n";

 $bool = $cuifinder->_exists($concept);

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

    Bridget T McInnes <bmcinnes@vcu.edu>
    Andriy Y. Mulyar  <andriy.mulyar@gmail.com>

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
