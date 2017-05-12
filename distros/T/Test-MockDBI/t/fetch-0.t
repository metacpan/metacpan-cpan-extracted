# Test::MockDBI fetch() when given empty array to return

# $Id: fetch-0.t 246 2008-12-04 13:01:22Z aff $

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
my $dbh    = "";                            # mock DBI database handle
my $md     = Test::MockDBI::get_instance();
my @retval = ();                            # return array from fetch()


# ------ set up return values for DBI fetch*() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_array(2, "FETCH", ());  # empty array
} qr/set_retval_array is deprecated/, "Legacy warning displayed";

# test non-matching sql
my $sth = $dbh->prepare("other SQL");  
@retval = $sth->fetch();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns for non-matching sql});
$sth->finish();

# test matching sql
$sth = $dbh->prepare("FETCH");  
@retval = $sth->fetch();
cmp_ok(scalar(@retval), q{==}, 0, q{Expect 0 columns for matching sql});

$sth->finish();

__END__

=pod

=cut
