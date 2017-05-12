use strict;
local $^W = 1;
our $jobname;
require './t/defs.pm';
my %tables = (
  hdb => 1,
  html => 1,
  links => 1,
  meta => 1,
  analys => 1,
  topic => 1,
  netlocalias => 1,
  urlalias => 1,
  topichierarchy => 1,
  netlocs => 1,
  urls => 1,
  urldb => 1,
  newlinks => 1,
  recordurl => 1,
  admin => 1,
  log => 1,
  que => 1,
  robotrules => 1,
  oai => 1,
  exports => 1,
  localtags => 1,
  search => 1,
);
my $noOfTables = scalar(keys %tables);

use Test::More tests => 25 ;
#diag('Ignore mkdir and chmod errors');

use DBI;
my $sv = DBI->connect("DBI:mysql:database=;host=localhost", 
                    'root', '');             #!!Handle passwd
if (!$sv) { diag('BAILOUT: MySQL must be installed: ' . $DBI::errstr); }
else { ok($sv, 'MySQL'); }
$sv->disconnect;

#Test that database and tables are created OK
system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");

$sv = DBI->connect("DBI:mysql:database=$jobname;host=localhost", 
                    'combine', '');             #!!Handle passwd
if (!$sv) { diag("BAILOUT: problems connecting to $jobname as user 'combine' after running combineINIT: " . $DBI::errstr); }
else { ok($sv, "MySQL:$jobname"); }

my $sth =  $sv->prepare(qq{SHOW TABLES;});
$sth->execute;
my $i=0;
while (my ($table) = $sth->fetchrow_array) { ok($tables{$table}, "MySQL table $table"); $i++;}
is($i, $noOfTables, 'No of MySQL tables');
