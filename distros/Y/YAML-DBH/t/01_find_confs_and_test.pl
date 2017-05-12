use Test::Simple 'no_plan';
use lib './lib';
use YAML::DBH 'yaml_dbh';

opendir(D,'./t') or die();
my @confs_found = grep { /\.conf$/ } readdir D;
closedir D;





for (@confs_found) {
   my $abs_credentials ="./t/$_";
   ok -f $abs_credentials, "found $abs_credentials";

   my $dbh;
   ok ( $dbh = yaml_dbh($abs_credentials), 'yaml_dbh()');
   $dbh->disconnect;
}



