# $Id: fetchrow_hashref-1.t 236 2008-12-04 10:28:12Z aff $

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

plan tests => 4;

# ------ define variables
my $dbh = "";                                      # mock DBI database handle
my $md  = Test::MockDBI::get_instance();
my $hashref = undef;


# ------ set up return values for DBI fetchrow_hashref() methods
$dbh = DBI->connect("", "", "");

warning_like{
  $md->set_retval_scalar(42, "FETCHROW_HASHREF", { key => 'value' });
} qr/set_retval_scalar is deprecated/, "Legacy warning displayed";  

# non-matching sql
my $sth = $dbh->prepare("other SQL");
$sth->execute();
$hashref = $sth->fetchrow_hashref();
ok(!defined($hashref), q{Expect fetchrow_hashref to return undefined value for non-matching sql});
$sth->finish();

# matching sql
$sth = $dbh->prepare("FETCHROW_HASHREF");
$sth->execute();
$hashref = $sth->fetchrow_hashref();
isa_ok($hashref, q{HASH}, q{Expect fetchrow_hashref to return a HASH ref}) or 
	diag(q{hashref:}.Dumper($hashref));
is_deeply($hashref, { key => 'value' }, q{Expect fetchrow_hashref to return { key => value }});

__END__

