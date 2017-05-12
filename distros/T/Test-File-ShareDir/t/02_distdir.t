
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use FindBin;
use Test::File::ShareDir
  -root  => "$FindBin::Bin/02_files",
  -share => { -dist => { 'Example-Dist' => 'share', } };

use File::ShareDir qw( dist_dir dist_file );

is(
  exception {
    note dist_dir('Example-Dist');
  },
  undef,
  'dist_dir doesn\'t bail as it finds the dir'
);

is(
  exception {
    note dist_file( 'Example-Dist', 'afile' );
  },
  undef,
  'dist_file doesn\'t bail as it finds the file'
);

done_testing;
