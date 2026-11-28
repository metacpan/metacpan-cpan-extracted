use Test::More;

plan skip_all => "Optional modules (DBI) not installed"
  unless eval {
      require DBI;
  };

plan tests => 3;

$package = 'Web::Session::Store::MariaDBJSON';

use_ok($package);

my $foo = $package->new;

isa_ok $foo, $package;

use_ok('Web::Session::MariaDBJSON');
