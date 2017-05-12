# Test::MockDBI fetchrow_array() with many-element array returned
# (For our purposes, 2 eq many.)

# $Id: fetchrow_array-many.t 246 2008-12-04 13:01:22Z aff $

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
  $md->set_retval_array(2, "FETCHROW_ARRAY", "go deep", 476);
} qr/set_retval_array is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
@retval = $sth->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns for non-matching sql});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW_ARRAY");
$sth->execute();
@retval = $sth->fetchrow_array();
cmp_ok(scalar(@retval), q{==}, 2, q{Expect 2 column in row for matching sql});
is_deeply(\@retval, [ "go deep", 476 ], q{Expect 1st row to contain ["go deep", 476]});

$sth->finish();

__END__
