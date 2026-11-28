use Test::More;

plan skip_all => "Optional modules (DBD::mysql, DBI) not installed"
  unless eval {
      require DBI;
      require DBD::mysql;
  };

plan tests => 2;

$package = 'Web::Session::Store::MySQL';

use_ok($package);

my $foo = $package->new;

isa_ok $foo, $package;

