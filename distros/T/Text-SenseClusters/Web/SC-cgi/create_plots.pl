#!/usr/local/bin/perl -w

=head1 NAME

create_plots.pl - [Web Interface] Create gnuplot output for Web interface user 

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

system("../../create_gp.pl $prefix $crfun");

system("gnuplot $prefix.gp");

system("../../create_tex_file.pl $prefix");

system("latex $prefix.CR.tex");
system("latex $prefix.CR.tex");
system("dvips -Ppdf -G0 -t letter $prefix.CR.dvi");
system("ps2pdf $prefix.CR.ps");

if(-e "$prefix.PK1.tex")
{
    system("latex $prefix.PK1.tex");
    system("latex $prefix.PK1.tex");

    system("dvips -Ppdf -G0 -t letter $prefix.PK1.dvi");
    system("ps2pdf $prefix.PK1.ps");
}

if(-e "$prefix.PK2.tex")
{
    system("latex $prefix.PK2.tex");
    system("latex $prefix.PK2.tex");

    system("dvips -Ppdf -G0 -t letter $prefix.PK2.dvi");
    system("ps2pdf $prefix.PK2.ps");
}

if(-e "$prefix.PK3.tex")
{
    system("latex $prefix.PK3.tex");
    system("latex $prefix.PK3.tex");

    system("dvips -Ppdf -G0 -t letter $prefix.PK3.dvi");
    system("ps2pdf $prefix.PK3.ps");
}

if(-e "$prefix.Obs-Exp.tex")
{
    system("latex $prefix.Obs-Exp.tex");
    system("latex $prefix.Obs-Exp.tex");

    system("dvips -Ppdf -G0 -t letter $prefix.Obs-Exp.dvi");
    system("ps2pdf $prefix.Obs-Exp.ps");
}

if(-e "$prefix.GAP.tex")
{
    system("latex $prefix.GAP.tex");
    system("latex $prefix.GAP.tex");

    system("dvips -Ppdf -G0 -t letter $prefix.GAP.dvi");
    system("ps2pdf $prefix.GAP.ps");
}

system("rm -f $prefix.*.ps $prefix.*.dvi $prefix.*.aux $prefix.*.tex");
