
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use FindBin;
use Test::File::ShareDir
  -root  => "$FindBin::Bin/01_files",
  -share => { -module => { 'Example' => 'share', } };

use lib "$FindBin::Bin/01_files/lib";

use Example;

use File::ShareDir qw( module_dir module_file );

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

done_testing;
