#!/usr/bin/perl -w

# Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# in theory, this should generate .xs files for xfce header files that
# contain only utility functions.  right now this isn't quite automated,
# but at least this will get the boilerplate stuff out of the way.

use strict;

if(scalar(@ARGV) != 3) {
    print STDERR "usage: $0 header_file package_name type_prefix\n";
    exit(1);
}

my ($header, $pkgname, $type_prefix) = @ARGV;

open(HEADER, '<'.$header) or die("Can't open $header: $!");

# print file header    
print qq(/* NOTE: THIS FILE WAS POSSIBLY AUTO-GENERATED! */

/*
 * Copyright (c) 2005 Brian Tarricone <bjt23\@cornell.edu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "xfce4perl.h"

MODULE = $pkgname    PACKAGE = $pkgname    PREFIX = $type_prefix

);

while(my $line = <HEADER>) {
    chomp($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    
    # if it's the first line of a function, see if we need to get more lines
    if($line =~ /^.*?(\s|\*)$type_prefix.*/ && $line !~ /\);$/) {
        while(my $nextline = <HEADER>) {
            chomp($nextline);
            $nextline =~ s/^\s+//;
            $nextline =~ s/\s+$//;
            $line .= ' '.$nextline;
            last if($nextline =~ /.*?\);$/);
        }
    }
    
    # now see if we have a function
    if($line =~ /^(.*?)($type_prefix.*?)\s*\(\s*(.*?)\s*\);/ && $line !~ /${type_prefix}get_type/ && $line !~ /^#define/) {
        my ($retval,$func,$argstr) = ($1,$2,$3);
        $retval =~ s/\s+$//;
        $retval =~ s/^\s+//;
        print STDERR "      got function:\n";
        print STDERR "        retval: '$retval'\n";
        print STDERR "        func:   '$func'\n";
        print STDERR "        argstr: '$argstr'\n";
        
        $argstr = '' if($argstr =~ /^\s*void\s*$/);
        
        my @argtypes;
        my @argnames;
        my @args = split(/,\s*/, $argstr);
        foreach my $a (@args) {
            $a =~ /(.+(\s*\*|\s))([A-Za-z0-9_]+)$/;
            my ($atype,$aname) = ($1,$3);
            $atype =~ s/\s+$//g;
            print STDERR "          arg type: '$atype' | arg name: '$aname'\n";
            push(@argtypes, $atype);
            push(@argnames, $aname);
        }
        
        my $i;
        if($func =~ /_new/) {
            $i = 1;
            unshift(@argtypes, '');
            unshift(@argnames, 'class');
        } else {
            $i = 0;
        }
        
        print "$retval\n";
        print "$func(";
        my $first = 1;
        foreach my $aname (@argnames) {
            print ', ' if(!$first);
            print $aname;
            $first = 0 if($first);
        }
        print ")\n";
        for(; $i < scalar(@argtypes); $i++) {
            print "        ".$argtypes[$i].' '.$argnames[$i]."\n";
        }
        print "\n";
    }
}
    
close(HEADER);
