# Test::MockDBI fetch*() with 0-element array returned from coderef

# $Id: coderef-scalar-0.t 246 2008-12-04 13:01:22Z aff $

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
my $dbh    = "";                              # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my $retval = undef;

# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(2, "FETCHROW",  sub {});
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");  
$retval = $sth->fetchrow_arrayref();
ok(!defined($retval), q{Expect 0 columns});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCHROW");  
$retval = $sth->fetchrow_arrayref();
ok(!defined($retval), q{Expect undef for matching sql since sub returns undef});

$sth->finish();


__END__

=pod

=cut
