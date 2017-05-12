# $Id: 05debug.t,v 1.2 2006/08/03 16:04:28 jeff Exp $

# test debugging

use DBI;
use Test::More tests => 4;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $file;

# Perl.debug(1)
init_test($dbh);
ok ($dbh->do('BEGIN TestPerl.debug(1); END;'), 'Perl.debug(1)');

# Perl.debug(0)
init_test($dbh);
ok ($dbh->do('BEGIN TestPerl.debug(0); END;'), 'Perl.debug(0)');

# debug_file
init_test($dbh);
$sth = $dbh->prepare('SELECT debug_file FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    $file = ($sth->fetchrow_array)[0];
    like($file, qr/\/tmp\/ep_debug.\d+/, 'debug_file');
}
else {
    fail('Perl.debug(1)');
}

# debug_file existence
init_test($dbh);
ok (-e $file, 'debug_file existence');
