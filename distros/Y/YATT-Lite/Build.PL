use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/misc/cpan";

use MyBuilder;

my $builder = MyBuilder->new
(module_name           => 'YATT::Lite'
 , license             => 'perl'
 , dist_version_from   => 'Lite.pm'
 , test_files => MyBuilder->rscan_dir('t', qr{\.t$})
 , add_to_cleanup => [ qw(t/cover_db) ]
 , MyBuilder->my_cpanfile_specs
);

$builder->add_build_element('yatt_dist');

if ($ENV{DEBUG_BUILD}) {
  print $builder->dist_version, "\n";
  use Data::Dumper;
  $builder->process_yatt_dist_files;
  print Dumper($builder), "\n";
  print Dumper($builder->install_path), "\n";
  print Dumper([$builder->install_types]), "\n";
  print Dumper($builder->install_map), "\n";
  exit;
}

$builder->create_build_script();
