# $Id: fetchrow_hashref-2.t 236 2008-12-04 10:28:12Z aff $

use strict;				
use warnings;				

# ------ enable testing mock DBI
BEGIN { push @ARGV, "--dbitest=42"; }

use Data::Dumper;
use Test::More;
use Test::Warn;

use File::Spec::Functions;
use lib catdir qw ( blib lib );    # use local version of Test::MockDBI
use Test::MockDBI;			

plan tests => 7;

# ------ define variables
my $dbh = "";                                      # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $hashref = undef;


# ------ set up return values for DBI fetchrow_hashref() methods
$dbh = DBI->connect("", "", "");
my $arref = [ { key1 => 'value1' }, { key2 => 'value2' }, ];

warning_like{
  $md->set_retval_scalar(42, "FETCHROW_HASHREF", sub { shift @$arref }); # shift off on hashref each time
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";  

my $sth = $dbh->prepare("FETCHROW_HASHREF");
ok($sth, "sth is defined");

# row 1
$sth->execute();
my $rv = $sth->fetchrow_hashref();
isa_ok($rv, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref the first time}) or 
	diag(q{rv:}.Dumper($rv));
is_deeply($rv, { key1 => 'value1' }, q{Expect { key1 => 'value1' }});

# row 2
$rv = $sth->fetchrow_hashref();
isa_ok($rv, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref the second time}) or 
	diag(q{rv:}.Dumper($rv));
is_deeply($rv, { key2 => 'value2' }, q{Expect { key2 => 'value2' }}) or 
	diag(q{rv:}.Dumper($rv));

# row 3 - undefined
$hashref = $sth->fetchrow_hashref();
ok(!$hashref, q{Expect fetchrow_hashref to return false the third time}) or 
	diag(q{rv:}.Dumper($hashref));


__END__

