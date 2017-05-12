#!/usr/local/bin/perl

=head1 NAME 

create_gp.pl - [Web Interface] Creates gnuplot file (*.gp file) for Web user 

=head1 AUTHOR

 Anagha Kulkarni, Carnegie-Mellon University

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2004-2008, Anagha Kulkarni and Ted Pedersen

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

$prefix = shift;
$crfun = shift;

open (FP,">$prefix.gp") || die "Error opening the output file!!\n";

$prefix =~ s/_/\\_/g;

# common setting
print FP "set terminal latex 8\n";
print FP "set size 1.2,1.3\n";
print FP "set style line 99 lt -1 pt 22\n";
print FP "set style line 98 pt 23\n";
print FP "set xtics 1,2\n";
print FP "set key left top\n";


# crfun
print FP "set output \"$prefix.cr.tex\"\n";
print FP "plot \"$prefix.cr.dat\" title \" $crfun vs m\" w linespoints ls 99\n\n";

if(-e "$prefix.gap.dat")
{
    # cr & exp	
    print FP "set output \"$prefix.exp-cr.tex\"\n";
    print FP "plot \"$prefix.cr.dat\" title \" $crfun(obs) vs m\" w linespoints ls 99, \"$prefix.exp.dat\" title \" $crfun(exp) vs m\" w linespoints ls 98\n\n";

    print FP "set key right top\n";
    
    # gap
    print FP "set output \"$prefix.gap.tex\"\n";
    print FP "plot \"$prefix.gap.dat\" title \"Gap vs m\" w lines, \"$prefix.gap.dat\" notitle w errorbars ls 99\n\n";

}

print FP "set format y \"%.3f\"\n";
print FP "set key left top\n";
	
if(-e "$prefix.pk1.dat")
{    
    # pk1
    print FP "set output \"$prefix.pk1.tex\"\n";
    print FP "plot \"$prefix.pk1.dat\" title \"  PK1 vs m\" w linespoints ls 99\n\n";
#	print FP "plot \"$prefix.pk1.dat\" title \"  PK1 vs m\" w linespoints ls 99, \"$prefix.pk1\\_thres.dat\" notitle w linespoints ls 98\n\n";
}    

if(-e "$prefix.pk2.dat")
{    
    # pk2
    print FP "set output \"$prefix.pk2.tex\"\n";
    print FP "plot \"$prefix.pk2.dat\" title \"  PK2 vs m\" w linespoints ls 99, \"$prefix.pk2.dat\" notitle w errorbars ls 99\n\n";
}

if(-e "$prefix.pk3.dat")
{    
    # pk3
    print FP "set output \"$prefix.pk3.tex\"\n";
    print FP "plot \"$prefix.pk3.dat\" title \"  PK3 vs m\" w linespoints ls 99, \"$prefix.pk3.dat\" notitle w errorbars ls 99\n\n";
}


