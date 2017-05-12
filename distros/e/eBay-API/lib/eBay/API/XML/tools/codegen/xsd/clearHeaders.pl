#!/usr/bin/perl

################################################################################
# Location: ............. <user defined location>eBay/API/XML/tools/codegen/xsd
# File: ................. cleanHeaders.pl
# Original Author: ...... Milenko Milanovic
# Last Modified By: ..... Robert Bradley / Jeff Nokes
# Last Modified: ........ 03/06/2007 @ 17:07
#
################################################################################


=pod

=head1 cleanHeaders.pl

This is a script used to remove train and time specific information from 
auto-generated classes. Basically each generated class contains the following
two lines in its header:

   Last Generated: ........ 06/06/2006 @ 12:00
   API Release Number: .... 461

This script removes timestamp and api release number from each generated file.
When those 'generation artifacts' are removed it is easy to compare 
generated classes for two different trains and to spot real train related 
differences between those two sets of generated code

=cut



use strict;
use warnings;

use File::Find;
use IO::File;
use Getopt::Long;
use File::Spec;


my @aFiles = ();

main();

sub create_file_list {

    my $fileName = $File::Find::name;
    if ( ! ($fileName =~ m/\.pm/) ) { # not a generated file, skip it (basically a directory)
        return;
    }
    push @aFiles, $fileName;
}

sub inner_process_file {

    my $fileName = shift;
    if ( ! ($fileName =~ m/\.pm/) ) { # not a generated file, skip it (basically a directory)
        return;
    }

    my $in_fh = IO::File->new( "< $fileName");
    if ($!) {
        print "infile - $fileName " . $! . ", Aborting execution!\n";
        exit 1;
    }
    #exit;
    my $sContent = '';
    my @aClean = (  
                    '# Last Generated:'
                  , '# API Release Number:'
                  , '# API Release Type:');
    while (<$in_fh>) {

        my $line = $_;
        foreach my $sClean (@aClean) {
            if ($line =~ m/^$sClean/) {
                $line =~ s/($sClean).*$/$1/;
            }
        }
        $sContent .= $line;
    }
    $in_fh->close();

    my $out_fh = IO::File->new( "> $fileName");
    if ($!) {
        print "outfile - $fileName " . $! . ", Aborting execution!\n";
        exit 1;
    }
    print $out_fh $sContent;
    $out_fh->close();
}

sub main {

   my $inputDir = undef;      # default value, output to current working dir
   
   GetOptions ( 'inputDir=s' => \$inputDir );
   usage ( $inputDir );	


   find(\&create_file_list, $inputDir); # populates @aFiles

   foreach my $fileName ( @aFiles ) {
       print "$fileName\n";
       inner_process_file( $fileName );
   }
}

=head2 usage()

=cut 

sub usage {

   my $inputDir = shift;

   if ( length($inputDir) == 0 ) {

     my $scriptName = $0;   # script name
     my $no_file = 0;
     my ($volume, $directories, $file) = File::Spec->splitpath( $scriptName, $no_file );
     $scriptName = $file;

     my $msg = <<"USAGE";
usage:      
    $scriptName --inputDir=s
      arguments:
    	  inputDir - Root output directory for generated classes.
USAGE
    print $msg;
    exit;
   }
}
