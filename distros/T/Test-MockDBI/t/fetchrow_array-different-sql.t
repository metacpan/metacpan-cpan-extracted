# Test::MockDBI fetch*() which return an array handle multiple SQL statements.

# $Id: fetchrow_array-different-sql.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;
use Test::Warn;

plan tests => 7;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

# ------ define variables
my $dbh = "";          # mock DBI database handle
my $md = Test::MockDBI::get_instance();
my @retval = ();       # return value from fetchrow_array()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_array(2, "FETCHROW_ARRAY", "go deep", 476);
} qr/set_retval_array is deprecated/, "Legacy warning displayed";

warning_like{
  $md->set_retval_array(2, "SELECT zip5_zipcode.+'Chino Hills'", "Experian stuff", 1492);
} qr/set_retval_array is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
ok(!defined($sth->fetchrow_array()), q{Expect undef on non-matching sql});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW_ARRAY");
$sth->execute();
@retval = $sth->fetchrow_array();
is_deeply(\@retval, [ "go deep", 476 ], "Retval");
$sth->finish();

# test non-matching sql again
$sth = $dbh->prepare("STILL oTheR SQL");
$sth->execute();
ok(!defined($sth->fetchrow_array()), q{Expect undef on another non-matching sql});
$sth->finish();

# test another matching sql
$sth = $dbh->prepare("SELECT zip5_zipcode FROM ziplist5 WHERE zip5_cityname = 'Chino Hills'");
$sth->execute();
@retval = $sth->fetchrow_array();
is_deeply(\@retval, ["Experian stuff", 1492], q{Expect array ("Experian stuff", 1492)});
$sth->finish();

# test non-matching sql third time
$sth = $dbh->prepare("LaSt sqL");
$sth->execute();
ok(!defined($sth->fetchrow_array()), q{Expect undef on another non-matching sql});

__END__
