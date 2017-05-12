
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use FindBin;

use Test::File::ShareDir qw(with_module_dir);
use lib "$FindBin::Bin/08_files/lib";
use Example;
use File::ShareDir qw( module_dir module_file );

with_module_dir(
  { Example => 't/08_files/share' } => sub {
    is(
      exception {
        note module_dir('Example');
      },
      undef,
      'module_dir doesn\'t bail as it finds the dir'
    );

    is(
      exception {
        note module_file( 'Example', 'afile' );
      },
      undef,
      'module_file doesn\'t bail as it finds the file'
    );
  },
);

isnt(
  exception {
    note module_dir('Example');
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
    note module_file( 'Example', 'afile' );
  },
  undef,
  'dist_file bails after clear'
);

done_testing;
