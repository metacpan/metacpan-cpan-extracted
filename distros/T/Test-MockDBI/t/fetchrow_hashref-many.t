# $Id: fetchrow_hashref-many.t 236 2008-12-04 10:28:12Z aff $

use strict;				
use warnings;				

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=2"; }

use Data::Dumper;
use Test::More;
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local version of Test::MockDBI
use Test::MockDBI;			

plan tests => 11;

# ------ define variables
my $dbh = "";                                      # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $hashref = undef;

# ------ set up return values for DBI fetchrow_hashref() methods
my $arrayref = [
  { key1line1 => 'value1', key2line1 => 'value2' },
  { key1line2 => 'value3', key2line2 => 'value4' },
  { key1line3 => 'value5', key2line3 => 'value6' },
];
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(2, "FETCHROW_HASHREF", sub { shift @$arrayref });
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";

my $sth = $dbh->prepare("FETCHROW_HASHREF");
$sth->execute();

# row 1
$hashref = $sth->fetchrow_hashref();
ok($hashref, q{Expect fetchrow_hashref to return true for first row});
isa_ok($hashref, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref  first row});

is_deeply(
  $hashref,
  { key1line1 => 'value1', key2line1 => 'value2' },
  q{Expect key value pairs line 1}
);

# row 2
$hashref = $sth->fetchrow_hashref();
ok($hashref, q{Expect fetchrow_hashref to return true for second row});
isa_ok($hashref, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref second row});
is_deeply(
  $hashref,
  { key1line2 => 'value3', key2line2 => 'value4' },
  q{Expect key value pairs line 2}
);

# row 3
$hashref = $sth->fetchrow_hashref();
ok($hashref, q{Expect fetchrow_hashref to return true for third row});
isa_ok($hashref, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref second row});
is_deeply(
  $hashref,
  { key1line3 => 'value5', key2line3 => 'value6' },
  q{Expect key value pairs line 3}
);

# row 4 - expected to be undefined
$hashref = $sth->fetchrow_hashref();
ok(!$hashref, q{Expect fetchrow_hashref to return false the fourth time}) or 
	diag(q{rv:}.Dumper($hashref));

__END__


