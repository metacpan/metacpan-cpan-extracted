# Test::MockDBI fetchall_arrayref() with many-element array returned
# (For our purposes, 2 eq many.)

# $Id: fetchall_arrayref-many.t 246 2008-12-04 13:01:22Z aff $

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

plan tests => 5;


# ------ define variables
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my $retval = "";			# return value from fetchall_arrayref()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(2, "FETCH", [ [ "go deep", 476 ], [ 1066, "Yellow Pages" ] ]);
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
$retval = $sth->fetchall_arrayref();
ok(!defined($retval), q{Expect undef for non-matching sql});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHALL_ARRAYREF");
$sth->execute();
$retval = $sth->fetchall_arrayref();
ok(defined($retval), q{Expect defined for non-matching sql});
isa_ok($retval, q{ARRAY}, q{Expect array ref});
is_deeply(
  $retval,
  [ [ "go deep", 476 ], [ 1066, "Yellow Pages" ] ],
  q{Expect array ref with 2 array ref elements}
);

$sth->finish();

__END__

=pod

=cut
