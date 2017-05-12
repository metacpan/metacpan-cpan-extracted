use strict;
use warnings;

print STDERR <<__WARNING;


WARNING: use of Makefile_m.pl is deprecated, and this script may be
removed in the future.  Please use

  perl -MConfig_m Makefile.PL


__WARNING

print <<__MSG;

Setting the build environment to MinGW and calling Makefile.PL
with '-MConfig_m' in a few seconds.




__MSG

# give people enough time to see the warning
sleep(4);

# Call the same perl as used to run this script ($^X), setting
# '-MConfig_m, passing any other command line options they give,
# and setting BUILDENV=mingw.  By setting BUILDENV at the end of
# the command line, it will always override any BUILDENV passed in.
my $result = system $^X ($^X, '-MConfig_m' , "Makefile.PL", @ARGV, "BUILDENV=mingw");

if($result == -1) {
  die "System call to Makefile.PL failed: $!";
}

exit($?>>8);

