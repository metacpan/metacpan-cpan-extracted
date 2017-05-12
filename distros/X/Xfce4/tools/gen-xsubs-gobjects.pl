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

# in theory, this should generate .xs files for all the xfce classes
# automatically.  there will probably be some manual fixup required, but
# let's see how much we can avoid that...

use strict;

my $includedir = '/opt/xfce4-svn/include';
my @dirs = (
    $includedir.'/xfce4/libxfce4util/',
    $includedir.'/xfce4/libxfcegui4/',
    $includedir.'/xfce4/libxfce4mcs/',
);

my @headers = ();

foreach my $dir (@dirs) {
    opendir(DIR, $dir) and do {
        my @headers_local = grep { /\.h$/ } readdir(DIR);
        foreach my $header (@headers_local) {
            push(@headers, $dir.$header) if($header !~ /enum/);
        }
        closedir(DIR);
    };
}

foreach my $header (@headers) {
    open(HEADER, '<'.$header) or next;
    
    print "file: $header\n";
    
    my $have_type = 0;
    my $closeme = 0;
    my ($type_name,$type_prefix,$xs_filename);
    while(my $line = <HEADER>) {
        chomp($line);
        
        # ok, this is just plain retarded.  whoever thought that breaking up
        # (short!) lines like this was useful was sorely mistaken.
        $line =~ s/\s+$//;
        if($line =~ /\s*?G(tk)?Type\s*?$/) {
            while(my $nextline = <HEADER>) {
                chomp($nextline);
                $nextline =~ s/\s+//;
                $line .= ' '.$nextline;
                last if($nextline !~ /;$/);
            }
        }
        
        if($line =~ /^\s*?G(tk)?Type\s+(.*?)_get_type\s*\(/) {
            $type_prefix = $2.'_';
            
            $type_name = $2;
            $type_name =~ s/^(\w)/uc($1)/e;
            if($type_name =~ /^Netk/) {
                $type_name =~ s/^Netk_/Xfce4::Netk::_/;
            } elsif($type_name =~ /^Xfce/) {
                $type_name =~ s/^(\w+?)_/Xfce4::_/;
            } else {
                $type_name = 'Xfce4::'.$type_name;
            }
            $type_name =~ s/_(\w)/uc($1)/ge;
            
            $xs_filename = $type_name;
            $xs_filename =~ s/^Xfce4:://;
            $xs_filename = 'Xfce'.$xs_filename if($xs_filename !~ /Netk/);
            $xs_filename =~ s/:://;
            
            print "  got:\n    type name: $type_name\n    type prefix: $type_prefix\n    xs_filename: $xs_filename\n\n";
            
            $have_type = 1;
            
            open(XS, ">xs/$xs_filename.xs") or last;
            $closeme = 1;
            print XS "/* NOTE: THIS FILE WAS POSSIBLY AUTO-GENERATED! */

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
 */\n\n";
            print XS qq(#include "xfce4perl.h"\n\n);
            print XS "MODULE = $type_name    PACKAGE = $type_name    PREFIX = $type_prefix\n\n";
        }
        
        next if(!$have_type);
        
        # this is annoying, but necessary since some arglists are broken
        # across multiple lines
        $line =~ s/\s+$//;
        if($line =~ /^.*?$type_prefix.*?\s*\(\s*(.*?),$/) {
            while(my $nextline = <HEADER>) {
                chomp($nextline);
                $nextline =~ s/\s+$//;
                $line .= ' '.$nextline;
                last if($nextline =~ /.*?\);$/);
            }
        }
        
        if($line =~ /^(.*?)($type_prefix.*?)\s*\(\s*(.*?)\s*\)/ && $line !~ /${type_prefix}get_type/ && $line !~ /^#define/) {
            my ($retval,$func,$argstr) = ($1,$2,$3);
            $retval =~ s/\s+$//;
            $retval =~ s/^\s+//;
            chomp($func);
            chomp($argstr);
            print "      got function:\n";
            print "        retval: '$retval'\n";
            print "        func:   '$func'\n";
            print "        argstr: '$argstr'\n";
            
            $argstr = '' if($argstr eq 'void');
            
            my @argtypes;
            my @argnames;
            my @args = split(/,\s*/, $argstr);
            foreach my $a (@args) {
                $a =~ /(.+(\s*\*|\s))([A-Za-z0-9_]+)$/;
                my ($atype,$aname) = ($1,$3);
                $atype =~ s/\s+$//g;
                print "          arg type: '$atype' | arg name: '$aname'\n";
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
            
            print XS "$retval\n";
            print XS "$func(";
            my $first = 1;
            foreach my $aname (@argnames) {
                print XS ', ' if(!$first);
                print XS $aname;
                $first = 0 if($first);
            }
            print XS ")\n";
            for(; $i < scalar(@argtypes); $i++) {
                print XS "        ".$argtypes[$i].' '.$argnames[$i]."\n";
            }
            print XS "\n";
        }
    }
    
    close(XS) if($closeme);
    close(HEADER);
}
