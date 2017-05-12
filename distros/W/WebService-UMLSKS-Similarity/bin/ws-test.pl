#!/usr/bin/env perl


#---------------------------PERLDOC STARTS HERE------------------------------------------------------------------

=head1 NAME

ws-test

=cut

#---------------------------------------------------------------------------------------------------------------------

=head1 SYNOPSIS

=head2 Basic Usuage

=pod

perl ws-test.pl --config configfilename --login loginfile  --testfile test_file

--config : Instead of providing sources, relations and directions on command line, they can be
specified using a configuration file, which can be provided with this option.
It takes complete path and name of the file. The config file is expected in following format:

=cut

=pod

=over

=item SAB :: include SNOMEDCT,MSH

=item REL :: include PAR,RB

=item DIR :: include U,H

=item RELA :: include RB-has_part
 
=back 

=cut

=pod

--login : User can specify login credentials through the file, which should be of form:

=over

=item username :: xyz

=item password :: pqr
 
=back


--testfile : User can specify the list of test CUIs stored in the test_file throught this option.
The program would call getAllowablePath.pl for all the CUI pairs sequentially.


Follwing is a sample output

=over

=item Enter username to connect to UMLSKS:mchoudhari

=item Enter password: 

=item An output file output.txt would be generated.

=back


=head1 DESCRIPTION

This program is used for testing a large data set. It accepts the test file as command line argument and sequentially 
calls getAllowablePath.pl for each test CUI pair.

=cut

#---------------------------------------------------------------------------------------------------------------------------

#------------------------------PERLDOC ENDS HERE------------------------------------------------------------------------------



use Getopt::Long;
use strict;


my $test_file ;
my $c_file;
my $l_file;
my $patterns_file;

GetOptions( 'testfile=s' => \$test_file, 'config=s' => \$c_file, 'login=s' => \$l_file, 'pattern=s' => \$patterns_file);

if($test_file eq "" || $l_file  eq "" || $c_file eq "" || $patterns_file eq "")
{
	print "\n Please specify options --testfile, --login , --config and --pattern for testing\n";
	exit;
}


if($test_file ne "" && $c_file ne "" && $l_file ne "" && $patterns_file ne ""){
	
	open(MYDATA, $test_file) or  die("Error: cannot open file 'data.txt'\n");
	
	
	# This is creating the file for writing output
	open(OUTPUT,">","output.txt") or die("Error: cannot open file 'output.txt'\n");
	close OUTPUT;
	
	#open(TIME,">","time.txt") or die("Error: cannot open file 'time.txt'\n");
	#close TIME;
	
	#open(OUT,">","inter_output.txt") or die("Error: cannot open file 'inter_output.txt'\n");
	#close OUT;
		
	my $line;
	
	my $lnum = 1;
	while( $line = <MYDATA> ){
	  	chomp($line);
	  
	  	$line =~ /\s*(.*)\s*<>\s*(.*?)$/;
	  	my $query1 = $1;
	  	my $query2 = $2;
	  	$query1 =~ s/\s*//g;
	  	$query2 =~ s/\s*//g;
	
	  # Call getAllowable.pl for each CUI pair in the test file.
system("/usr/bin/perl ws-getAllowablePath.pl --input1 $query1 --input2 $query2 --login $l_file --config $c_file --patterns $patterns_file");
	  
	
	  
	}	
	
}




#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO 

ValidateTerm.pm  GetUserData.pm  Query.pm  ConnectUMLS.pm 

=cut


=head1 AUTHORS

Mugdha Choudhari             University of Minnesota Duluth
                             E<lt>chou0130 at d.umn.eduE<gt>

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>




=head1 COPYRIGHT

Copyright (C) 2011, Mugdha Choudhari, Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to 
The Free Software Foundation, Inc., 
59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut

#---------------------------------PERLDOC ENDS HERE---------------------------------------------------------------



