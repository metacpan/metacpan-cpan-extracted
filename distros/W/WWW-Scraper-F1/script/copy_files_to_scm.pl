use strict;
use warnings;

use Getopt::Long;
use File::Copy;

my $build_dir = '';

GetOptions(
   'dir=s' => \$build_dir,
);
say "Hello: $build_dir";
#chdir($build_dir);
#copy( "README.mkdn" , "../README.mkdn" ) or die "Could not copy README: $!";
