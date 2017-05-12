#!/usr/local/bin/perl

=head1 NAME

create_tex_file.pl - [Web Interface] Create .tex file output for Web interface user

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

open(FP,">$prefix.CR.tex") || die "Error opening output file\n!!";

print FP "\\documentclass{article}\n";
print FP "\\usepackage{fullpage}\n";

print FP "\\begin{document}\n\n";

print FP "\\begin {figure}\n";
print FP "\\begin{center}\n";
print FP "\\leavevmode\n";
print FP "\\input{$prefix.cr.tex}\n";
print FP "\\end{center}\n";
print FP "\\end {figure}\n\n";

print FP "\\end{document}\n";

close FP;


if(-e "$prefix.pk1.tex")
{
    open(FP,">$prefix.PK1.tex") || die "Error opening output file\n!!";
    
    print FP "\\documentclass{article}\n";
    print FP "\\usepackage{fullpage}\n";

    print FP "\\begin{document}\n\n";
    
    print FP "\\begin {figure}\n";
    print FP "\\begin{center}\n";
    print FP "\\leavevmode\n";
    print FP "\\input{$prefix.pk1.tex}\n";
    print FP "\\end{center}\n";
    print FP "\\end {figure}\n\n";
    
    print FP "\\end{document}\n";

    close FP;
}

if(-e "$prefix.pk2.tex")
{
    open(FP,">$prefix.PK2.tex") || die "Error opening output file\n!!";
    
    print FP "\\documentclass{article}\n";
    print FP "\\usepackage{fullpage}\n";
    
    print FP "\\begin{document}\n\n";
    
    print FP "\\clearpage\n\n";
    
    print FP "\\begin {figure}\n";
    print FP "\\begin{center}\n";
    print FP "\\leavevmode\n";
    print FP "\\input{$prefix.pk2.tex}\n";
    print FP "\\end{center}\n";
    print FP "\\end {figure}\n\n";
    
    print FP "\\end{document}\n";
    
    close FP;
}

if(-e "$prefix.pk3.tex")
{
    open(FP,">$prefix.PK3.tex") || die "Error opening output file\n!!";
    
    print FP "\\documentclass{article}\n";
    print FP "\\usepackage{fullpage}\n";
    
    print FP "\\begin{document}\n\n";
    
    print FP "\\begin {figure}\n";
    print FP "\\begin{center}\n";
    print FP "\\leavevmode\n";
    print FP "\\input{$prefix.pk3.tex}\n";
    print FP "\\end{center}\n";
    print FP "\\end {figure}\n\n";
    
    print FP "\\end{document}\n";
    
    close FP;
}

if(-e "$prefix.exp-cr.tex")
{
    open(FP,">$prefix.Obs-Exp.tex") || die "Error opening output file\n!!";
    
    print FP "\\documentclass{article}\n";
    print FP "\\usepackage{fullpage}\n";
    
    print FP "\\begin{document}\n\n";
    
    print FP "\\begin {figure}\n";
    print FP "\\begin{center}\n";
    print FP "\\leavevmode\n";
    print FP "\\input{$prefix.exp-cr.tex}\n";
    print FP "\\end{center}\n";
    print FP "\\end {figure}\n\n";
    
    print FP "\\end{document}\n";
    
    close FP;
}

if(-e "$prefix.gap.tex")
{
    open(FP,">$prefix.GAP.tex") || die "Error opening output file\n!!";
    
    print FP "\\documentclass{article}\n";
    print FP "\\usepackage{fullpage}\n";

    print FP "\\begin{document}\n\n";
    
    print FP "\\begin {figure}\n";
    print FP "\\begin{center}\n";
    print FP "\\leavevmode\n";
    print FP "\\input{$prefix.gap.tex}\n";
    print FP "\\end{center}\n";
	print FP "\\end {figure}\n\n";
    
    print FP "\\end{document}\n";
    
    close FP;
}
