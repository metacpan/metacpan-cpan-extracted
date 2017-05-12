use Test::Simple 'no_plan';
use lib './lib';
use strict;
use YAML::DBH 'yaml_dbh';
require DBD::SQLite;
use Cwd;

my $cwd = cwd();
open( FILE, '>', "$cwd/t/sqlite.conf" ) or die;
print FILE "---
abs_db: $cwd/t/test.db
";
close FILE;


ok(1,"started");


my $abs_conf = "$cwd/t/sqlite.conf";

my $dbh = yaml_dbh( $abs_conf );

ok $dbh, "got dbh";

