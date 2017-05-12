#
# Copyright (C) 2006-2011 Tom Zoerner.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# For a copy of the GPL refer to <http://www.gnu.org/licenses/>
#
# $Id: Makefile.PL,v 1.6 2011/01/02 16:42:18 tom Exp tom $
#

# oldest supported perl version
use 5.007_001;  # note: keep in sync with ZVBI.pm and META.yml

use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

#
# Since MakeMaker considers missing libraries "probably harmless"
# we perform a search for libzvbi beforehand and abort if it's missing.
#
my $libs = '-lzvbi';
if ($^O =~ /bsd$/i) {
        $libs .= ' -lpthread -lpng -lz';
}
my $inc = '';

if (($#ARGV >= 0) && ($ARGV[0] =~ /^LIBPATH=(.*)/)) {
        my $libpath = $1;
        shift @ARGV;
        $libs = "-L$libpath $libs";
        $libpath =~ m#^(/.*)/lib$# and $inc = "$1/include";
        die "Cannot access $libpath: $!\n" unless -d $libpath;
        print STDERR "Probing for prerequisite libzvbi in $libpath...\n";
} else {
        print STDERR "Probing for prerequisite libzvbi at standard paths...\n";
}
my $ll = ExtUtils::Liblist->ext($libs, 1, 1);  # verbose, return names
if ($#$ll < 0) {
        print STDERR "\nFATAL: Prerequisite zvbi library not found on your system.\n".
                     "If it's located at a non-standard path, run Makefile.PL\n".
                     "with 'LIBPATH=/your/path' on the command line (and replace\n".
                     "'/your/path' with the directory which holds libzvbi.so)\n";
        exit 0;  # don't die to avoid FAIL reports from CPAN testers
}

#
# Compile path and base name of the library (sans minor version) into the
# module for dynamic loading
#
my $def = "";
my $lso_path;
foreach (@$ll) {
        if (m#(^|/)(libzvbi\.so($|[^a-zA-Z].*))#) {
                $lso_path = $_;
                if (($lso_path =~ /(.*libzvbi\.so.\d+)/) && (-r $1)) {
                        $lso_path = $1;
                }
                print STDERR "Library path for dlopen(): $lso_path\n";
                last;
        }
}

# load optional symbols dynamically from shared library
# this requires to pass the library path and file name to dlopen()
die "\nFATAL: libzvbi.so not found in:\n".join(",",@$ll)."\n" unless defined $lso_path;
$def .= " -DUSE_DL_SYM -DLIBZVBI_PATH=\\\"$lso_path\\\"";

# use packaged header file instead of the one that may or may not be installed
# should only be enabled together with USE_DL_SYM
$def .= " -DUSE_LIBZVBI_INT";

#
# Generate the Makefile
#
WriteMakefile(
        'NAME'          => 'Video::ZVBI',
        'VERSION_FROM'  => 'ZVBI.pm',
        'LIBS'          => [ $libs ],
        'DEFINE'        => $def,
        'INC'           => $inc,
);

