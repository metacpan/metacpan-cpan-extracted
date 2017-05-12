use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $worepan = WorePAN->new(
  files => [qw{
    BARBIE/Test-YAML-Meta-0.19.tar.gz
    BARBIE/Test-YAML-Meta-0.16.tar.gz
  }],
  cleanup => 1,
  use_backpan => 1,
  no_network => 0,
);

my $authors = $worepan->authors;
ok @$authors && @$authors == 1, "only one author exists";
is $authors->[0]{pauseid} => 'BARBIE', "and it's Barbie";
like $authors->[0]{email} => qr/^\w+\@[\w.]+$/, "looks like email";

my $modules = $worepan->modules;
ok @$modules && @$modules == 2, "two modules are listed";
is_deeply [sort {$a->{module} cmp $b->{module}} @$modules] => 
  [
    {module => 'Test::YAML::Meta', version => '0.19', file => 'B/BA/BARBIE/Test-YAML-Meta-0.19.tar.gz'},
    {module => 'Test::YAML::Meta::Version', version => '0.16', file => 'B/BA/BARBIE/Test-YAML-Meta-0.16.tar.gz'}
  ], "modules are correct";

my $files = $worepan->files;
ok @$files && @$files == 2, "two files are listed";
is_deeply [sort @$files] => [qw{
  B/BA/BARBIE/Test-YAML-Meta-0.16.tar.gz
  B/BA/BARBIE/Test-YAML-Meta-0.19.tar.gz
}], "files are correct";

my $dists = $worepan->latest_distributions;
ok @$dists && @$dists == 1, "only one dist is listed";
is $dists->[0]->distvname => 'Test-YAML-Meta-0.19', "latest dist is correct";

done_testing;
