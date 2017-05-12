#!/usr/local/bin/perl
# $Id: argo2xmi.pl,v 1.2 2003/10/13 22:30:52 kstephens Exp $
# set -x

package Argo2XMI;

use strict;
use warnings;

use File::Basename;
use Archive::Zip qw(:ERROR_CODES);
use Archive::Zip::MemberRead;
use IO::File;


sub main
{
  my ($src_file, $dst_file) = @_;

  my $zip = Archive::Zip->new();
  my $status = $zip->read($src_file);
  die("Cannot read '$src_file'") if $status != AZ_OK;
  
  my $base_file = basename($src_file);
  $base_file =~ s/\.(zargo|zuml)$//;
  my $xmi_file = "$base_file\.xmi";
  
  my $xmi_member = (grep(basename($_->fileName) eq "$xmi_file", $zip->members()))[0];
  die("$0: Cannot find '$xmi_file' in '$src_file'") unless $xmi_member;
  
  my $fh = Archive::Zip::MemberRead->new($zip, $xmi_member->fileName());
  my $out;
  if ( ! defined $dst_file || $dst_file eq '-' ) {
    $out = \*STDOUT;
  } else {
    $out = IO::File->new("> $dst_file");
  }
  
  while ( 1 ) {
    my $buffer;
    my $result = $fh->read($buffer, 4096);
    die("$0: Cannot read from '$xmi_file' in '$src_file'") unless defined $result;
    last unless $result;
    $out->print($buffer);
  }
  
  close($out) unless $out eq \*STDOUT;
}

####################################################################################

my $FILE = __FILE__;
exit(main(@ARGV)) if $0 =~ /$FILE/;

####################################################################################

1;

