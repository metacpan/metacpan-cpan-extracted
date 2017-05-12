##
#
#    Copyright 2001-2007, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

require 5.006_001;

package XML::Comma;

$XML::Comma::VERSION = '1.998';

use strict;
use vars '$AUTOLOAD';

# pull in Config and define some global XML::Comma methods
use XML::Comma::Configuration;

BEGIN {
  # append architecture specific directory to sys_directory to allow
  # e.g. sharing of comma install between different architecture machines
  use Config qw();
  XML::Comma::Configuration->_set("sys_directory",
    XML::Comma::Configuration->get("sys_directory")."/".$Config::Config{archname}); 

  # make sure we have our basic systems directories
  make_system_directories ( qw[ comma_root
                                document_root
                                sys_directory
                                tmp_directory ] );

  # pull in hash module
  my $hash_module = XML::Comma->hash_module();
  eval "use $hash_module"; 
  die "can't use hash_module class: $@\n" if $@;

  # pull in parser
  my $parser = XML::Comma->parser();
  eval "use $parser"; 
  die "can't use parser class: $@\n" if $@; 

  sub parser {
    return 'XML::Comma::Parsing::' .XML::Comma::Configuration->get ( 'parser' );
  }

  my $lock_singlet; 
  sub lock_singlet {
    return $lock_singlet ||= XML::Comma::SQL::Lock->new();
  }

  sub def_pnotes {
    return XML::Comma::DefManager->get_pnotes ( $_[1] );
  }

  sub AUTOLOAD {
    my ( $self, @args ) = @_;
    # strip out local method name and stick into $m
    $AUTOLOAD =~ /::(\w+)$/;  my $m = $1;
    # check that this configuration variable exists
    my $value = XML::Comma::Configuration->get ( $m );
    unless ( defined $value ) {
      XML::Comma::Log->err
          ( 'UNKNOWN_CONFIG_VAR',
            "no such config variable as '$m' for XML::Comma\n" );
    }
    return $value; 
  }

  use File::Path qw();
  sub make_system_directories {
    foreach my $var ( @_ ) {
      my $dirname = XML::Comma::Configuration->get ( $var ) ||
        die "Comma can't function without a '$var' configuration value";
      File::Path::mkpath ( $dirname );
    }
  }

}


# comma modules that need to be pulled in in a given order or that
# should have their APIs automatically available to anyone who does a
# 'use XML::Comma'
use XML::Comma::Log;
use XML::Comma::SQL::Lock;
use XML::Comma::Configable;
use XML::Comma::Hookable;
use XML::Comma::Methodable;
use XML::Comma::AbstractElement;
use XML::Comma::NestedElement;
use XML::Comma::BlobElement;
use XML::Comma::Element;
use XML::Comma::Doc;
use XML::Comma::Def;
use XML::Comma::Storage::Util;
use XML::Comma::Storage::FileUtil;
use XML::Comma::Storage::Store;
use XML::Comma::Indexing::Index;
use XML::Comma::Bootstrap;
use XML::Comma::DefManager;
#use XML::Comma::VirtualDoc;


1;
__END__


=head1 NAME

XML::Comma - A framework for structured document manipulation

=head1 SYNOPSIS

  use XML::Comma;
  blah blah blah

=head1 DESCRIPTION

  This is the "entry point" for using the XML::Comma modules.

=head1 AUTHOR

  comma@xml-comma.org

=head1 SEE ALSO

  http://xml-comma.org

=cut


