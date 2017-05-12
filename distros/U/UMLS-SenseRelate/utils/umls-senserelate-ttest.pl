#!/usr/bin/perl 

=pod

=head1 NAME

umls-senserelate-ttest.pl - This program calculates the 
pairwise t-test of two info files. 

=head1 SYNOPSIS

This program calculates the significance between two 
info files created by the umls-senserelate-evaluation.pl 
program with the --info option set. The program uses the 
Statistics::TTest cpan module. 

=head1 USAGE

Usage: umls-senserelate-ttest.pl FILE1 FILE2

=head2 OUTPUT

=head2 Required Options

=head3 FILE(1|2)

This is a file created using the --info option when running the 
umls-senserelate-evaluation.pl program. 

=head2 General Options:

=head3 --version

Displays the version information.

=head3 --help

Displays the help information

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :
    
      umls-similarity@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-similarity/
     
  You may also contact us directly if you prefer :
    
      Bridget T. McInnes: bthomson at umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2013,

 Bridget T. McInnes, University of Minnesota Twin Cities
 bthomson at umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu
 
This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================


use Statistics::TTest;
use Getopt::Long;

eval(GetOptions( "version", "help")) or die ("Please check the above mentioned option(s).\n");

#  if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp();
    exit;
} 

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

# At least 1 terms should be given on the command line.
if(scalar(@ARGV) < 2) {
    print STDERR "Two info files must be given on the command line.\n";
    &minimalUsageNotes();
    exit;
}

my $file1 = shift; 
my $file2 = shift;

my @Data1 = (); 
my @Data2 = (); 
my %hash1 = (); 
my %hash2 = (); 

open(FILE1, $file1) || die "Could not open file ($file1)\n";
while(<FILE1>) { 
    chomp;
    my($tw, $acc) = split/\s+/;
    if($acc=~/0\.[0-9]+/) { 
	$hash1{$tw} = $acc;
    }
} close FILE1;

open(FILE2, $file2) || die "Could not open file ($file2)\n";
while(<FILE2>) { 
    chomp;
    my($tw, $acc) = split/\s+/;
    if($acc=~/0\.[0-9]+/) { 
	$hash2{$tw} = $acc; 
    }
} close FILE2;

foreach my $tw (sort keys %hash1) { 
    if(exists $hash2{$tw}) { 
	push @Data1, $hash1{$tw}; 
	push @Data2, $hash2{$tw}; 
    }
}

my $ttest = new Statistics::TTest;
$ttest->set_significance(95);
$ttest->load_data(\@Data1,\@Data2);
$ttest->output_t_test();

my $t    = $ttest->t_statistic;
my $df   = $ttest->df;
my $prob = $ttest->{t_prob};
my $test = $ttest->null_hypothesis();
print "t=$t (df = $df); p-value = $prob\n"; 
print "Null hypothesis is $test\n";


##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: umls-senserelate-ttest.pl [OPTIONS] FILE1 FILE2\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility \n";
  
    print "Usage: umls-senserelate-ttest.pl [OPTIONS] FILE1 FILE2\n\n";
    
    print "\n\nGeneral Options:\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-senserelate-ttest.pl,v 1.2 2013/05/23 17:53:33 btmcinnes Exp $';
    print "\nCopyright (c) 2013, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-senserelate-ttest.pl --help for help.\n";
}
    

