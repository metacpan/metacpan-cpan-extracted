# Test making DBI parameters bad

# $Id: bad_param-ok-none.t 246 2008-12-04 13:01:22Z aff $

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

# ------ use/require pragmas
use strict;            # better compile-time checking
use warnings;          # better run-time checking
use Test::More;        # advanced testing
use Data::Dumper;
use Test::Warn;


use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local module
use Test::MockDBI;     # what we are testing

plan tests => 13;

# ------ define variables
my $dbh        = undef;    # mock DBI database handle
my $md         = undef;    # Test::MockDBI instance
my @retval     = ();       # return array from fetchrow_array()
my $select     = undef;    # DBI SQL SELECT statement handle

$md	= Test::MockDBI::get_instance();
isa_ok($md, q{Test::MockDBI}, q{Expect a Test::MockDBI reference});

# Set 2nd param bad (In mode --dbitest=2)
warning_like{
  like($md->bad_param(2, 2, "noblesville"), qr/^\d+$/, q{Expect a positive integer (bad_param))});
} qr/You have called bad_param in an deprecated way/, "Legacy warning displayed";

warning_like{
  like($md->set_retval_scalar(2, "other SQL", [42]), qr/^\d+$/, q{Expect a positive integer (set_retval_scalar))});
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

# Connect and prepare
$dbh = DBI->connect("", "", "");
isa_ok($dbh, q{DBI::db}, q{Expect a DBI::db reference});
$select = $dbh->prepare("other SQL ? ? ?");
isa_ok($select, q{DBI::st}, q{Expect a DBI::st reference});

# Bind, execute and fetch
is($select->bind_param(1, "46062"), 1, q{Expect 1 (bind_param 1))});
is($select->bind_param(2, "Noblesville"), 1, q{Expect 1 (bind_param 2 - note case sensitive!))});
is($select->bind_param(3, "IN"), 1, q{Expect 1 (bind_param 3))});

is($select->execute(), -1, q{Expect -1 (execute 1))});
cmp_ok($select->fetchrow_arrayref()->[0], q{==}, 42, q{Expect row->[0] == 42 since no params are bad});

is($select->finish(), 1, "finish()");

__END__

=pod

=head1 TEST COMMENT

This checks that setting the param 'noblesville' bad does not affect
the param 'Noblesville'.

=cut
