# Test::MockDBI fetchrow_array() with 1-element array returned

# $Id: fetchrow_array-1.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking

use Test::More;        # advanced testing
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # module we are testing

plan tests => 4;


# ------ define variables
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my @retval = ();                            # return array from fetchrow_array()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");
warning_like{
  $md->set_retval_array(2, "FETCHROW_ARRAY", 42);
} qr/set_retval_array is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
@retval = $sth->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW_ARRAY");
$sth->execute();
@retval = $sth->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 1, q{Expect 1 column in row});
cmp_ok($retval[0], q{==}, 42, q{Expect 1st column in row to contain 42});

$sth->finish();

__END__

=pod

=cut
