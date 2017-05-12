# Test::MockDBI fetch*() with 1-element array returned from coderef

# $Id: coderef-scalar-1.t 246 2008-12-04 13:01:22Z aff $

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
my $dbh    = "";                              # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my $retval = undef;

# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(2, "FETCHROW",  sub { return [ 1016 ]; });
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
$retval = $sth->fetchrow_arrayref();
ok(!defined($retval), q{Expect 0 columns});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW");
$sth->execute();
$retval = $sth->fetchrow_arrayref();
ok(defined($retval), q{Expect defined for matching sql});
is_deeply($retval, [ 1016 ], q{Expect 1 element array with value 1016});

$sth->finish();


__END__

=pod

=cut
