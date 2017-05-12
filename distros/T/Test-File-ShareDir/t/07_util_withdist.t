
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use FindBin;

use Test::File::ShareDir qw(with_dist_dir);
use lib "$FindBin::Bin/07_files/lib";
use Example;
use File::ShareDir qw( dist_dir dist_file );

my $distname = "Should-Not-Exist-X" . int( rand() * 255 );
my $ddir;
if ( not exception { $ddir = dist_dir($distname); 1 } ) {
  diag "Found should-not-exist dir at $ddir";
  plan skip_all => "dist_dir($distname) needs to not exist";
}

with_dist_dir(
  { $distname => 't/07_files/share' } => sub {
    is(
      exception {
        note dist_dir($distname);
      },
      undef,
      'dist_dir doesn\'t bail as it finds the dir'
    );

    is(
      exception {
        note dist_file( $distname, 'afile' );
      },
      undef,
      'dist_file doesn\'t bail as it finds the file'
    );
  },
);

isnt(
  exception {
    diag dist_dir($distname);
  },
  undef,
  'dist_dir bails after clear'
);

# Note: This code warns, its a bug in File::ShareDir
# dist_file( 'x', 'y' )
#  -> _dist_dir_new('x') -> Returns undef
#  -> File::Spec->catfile( undef, 'afile' )  # warns about undef in subroutine entry.
isnt(
  exception {
    diag dist_file( $distname, 'afile' );
  },
  undef,
  'dist_file bails after clear'
);

done_testing;
