use strict;
use warnings;
use Test::More tests => 2;

use YAML::Perl ();
use YAML::Perl::Loader ();
use YAML::Perl::Reader ();

cmp_ok(YAML::Perl::Loader->VERSION, 'eq', YAML::Perl->VERSION);
cmp_ok(YAML::Perl::Reader->VERSION, 'eq', YAML::Perl->VERSION);
