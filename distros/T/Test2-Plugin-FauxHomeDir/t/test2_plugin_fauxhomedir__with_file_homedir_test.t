use Test2::Plugin::FauxHomeDir;
use Test2::V0;

skip_all 'Test requires File::HomeDir::Test'
  unless eval q{ use File::HomeDir::Test; 1 };

ok 1;

done_testing;
