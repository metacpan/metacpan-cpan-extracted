use Test::More tests => 2;

use YAML::Manual;

pass 'YAML::Manual Loads';
ok $YAML::Manual::VERSION, 'YAML::Manual has a $VERSION';
