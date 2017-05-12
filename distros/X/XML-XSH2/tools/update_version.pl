#!/usr/bin/perl
# update_version.pl     pajas@ufal.ms.mff.cuni.cz     2007/01/02 09:46:10

use warnings;
use strict;
$|=1;

my $VERSION_FROM = shift;
my $version=`grep '\# VERSION TEMPLATE' "$VERSION_FROM"`;
$version =~ /#\ VERSION TEMPLATE/
  or die "Didn't find version template in $VERSION_FROM";
print "New version line: $version";

for my $module (@ARGV) {
  rename $module, $module.'~' || die "Cannot create backup for $module\n";
  open my $in, $module.'~' || error($module,"Cannot open ${module}~ for reading: $!");
  open my $out, '>',$module || error($module, "Cannot open ${module} for writing: $!");

  while (<$in>) {
    if (/#\ VERSION TEMPLATE/) {
      print "Updating version number in $module\n";
      $_=$version;
    }
    print $out $_;
  }

  my $perm = (stat $in)[2];
  chmod($perm, $out);
  
  close $out;
  close $in;
}
 
sub error {
  my ($module, $error)=@_;
  rename $module.'~', $module || die "Cannot revert backup for $module after error: $error\n";
  die $error;
}
