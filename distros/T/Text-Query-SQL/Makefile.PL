#
#   Copyright (C) 1998, 1999 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/TextQuery/Text-Query-SQL/Makefile.PL,v 1.5 2000/12/27 13:14:11 loic Exp $
#
# This -*- perl -*- script writes the Makefile for Text-Query-SQL
require 5.004;
use strict;

#--- Configuration section ---

use ExtUtils::MakeMaker;

version_check('Text::Query', '0.07', 'require Text::Query;');
version_check('DBI', '1.13', 'require DBI;');
version_check('Data::Dumper', '2.101', 'require Data::Dumper;');

#
# Check that package $what is installed and that
# it's version is at least $min_version.
# Use $test to check that package exists : usually something like
# $test = 'require MIME::Base64;';
# Dies if package not present or wrong version.
#
sub version_check {
    my($what, $min_version, $test) = @_;

    print "Checking for $what... ";
    $test .= "; die '' if(\$${what}::VERSION < \$min_version); \$${what}::VERSION";
    my $got_version = eval $test;
	$got_version = "undef" unless defined $got_version;
    if ($@) {
	print " failed\n";
	print <<EOT;
$@
Text-Query-SQL needs $what module, version >= $min_version
EOT
        exit;
    } else {
        eval "print \" \$${what}::VERSION ok\n\"";
    }
}

WriteMakefile(
  'VERSION_FROM' => 'lib/Text/Query/BuildSQL.pm',
  'NAME'	 => 'Text::Query::SQL',
);

