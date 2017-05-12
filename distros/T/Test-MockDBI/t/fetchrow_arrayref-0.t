# Test::MockDBI fetchrow_arrayref() when given no array to return

# $Id: fetchrow_arrayref-0.t 246 2008-12-04 13:01:22Z aff $

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

plan tests => 3;


# ------ define variables
my $dbh = undef;                           # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $retval = undef;    # return array from fetchrow_arrayref()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(2, "FETCHROW_ARRAYREF"); # return nothing (3rd arg)
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");  
$retval = $sth->fetchrow_arrayref();
ok(!defined($retval), q{Expect undef with non-matching sql from fetchrow_arrayref});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW_ARRAYREF");  
$retval = $sth->fetchrow_arrayref();
ok(!defined($retval), q{Expect undef with matching sql from fetchrow_arrayref});
$sth->finish();

__END__

=pod

=cut
