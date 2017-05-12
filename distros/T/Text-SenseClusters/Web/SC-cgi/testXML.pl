#!/usr/local/bin/perl -w

=head1 NAME

testXML.pl - [Web Interface] Check XML data to see if well-formed

=head1 SYNOPSIS

This tiny perl script checks if the created xml is well-formed.
Knowing this helps in deciding whether to display an xml formated
file or a plain-text file.

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

use XML::Simple;

$inpfile = shift @ARGV;

my $xml = XMLin($inpfile);
