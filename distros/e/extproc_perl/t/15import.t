# $Id: 15import.t,v 1.3 2006/08/03 16:04:28 jeff Exp $

# test importing

use DBI;
use Test::More tests => 3;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $tmp;

# import_perl
init_test($dbh);
ok($dbh->do("BEGIN TestPerl.import_perl('ep_testimport'); END;"), 'import_perl');

# execute
init_test($dbh);
undef $tmp;
$sth = $dbh->prepare("SELECT TestPerl.func('ep_testimport', 'testing 1 2 3') FROM dual");
if ($sth && $sth->execute()) {
   $tmp = ($sth->fetchrow_array)[0];
}
is($tmp, 'testing 1 2 3', 'execute');

# drop_perl
init_test($dbh);
ok($dbh->do("BEGIN TestPerl.drop_perl('ep_testimport'); END;")); 
