#!./perl
# $Id: 4_blk.t,v 1.4 2005/03/20 19:50:59 mpeppler Exp $
#
# From:
#	@(#)bcp.t	1.2	03/22/96

use strict;
use Test;

BEGIN { plan tests => 19 };

use Sybase::BLK;

ok(1);      # loaded.

use lib 't';
use _test;
use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my $X = new Sybase::BLK $Uid, $Pwd, $Srv;
ok(defined($X));		# 2

my $lock = '';

$X->ct_sql("if object_id('$Db..bcp') is not null drop table $Db..bcp");
my $ret = $X->ct_sql("create table $Db..bcp(f1 char(5), f2 int, f3 text, f4 varchar(10) null) $lock");
ok(defined($ret));		# 3

$ret = $X->config(INPUT => 't/blk.dat',
	    OUTPUT => "$Db..bcp",
	    REORDER => {1 => 'f2',
			2 => 'f3',
			3 => 'f1',
		        4 => 'f4'});
ok(defined($ret) && $ret);	# 4
$ret = $X->run;
ok(defined($ret));		# 5

my @rows = $X->ct_sql("select * from $Db..bcp");
ok(@rows);			# 6
ok(scalar(@rows) == 4);		# 7
ok($rows[3]->[1] == 12);	# 8
ok($rows[2]->[2] =~ /\r/);	# 9
ok(!defined($rows[1]->[3]));	# 10

$X->ct_sql("if object_id('$Db..bcp2') is not null drop table $Db..bcp2");

ok($X->ct_sql("create table $Db..bcp2(f1 char(5), f2 int null, f3 varchar(10) null, f4 datetime, f5 varchar(10) null) $lock")); # 11
ok($X->config(INPUT => 't/blk2.dat',
	    OUTPUT => "$Db..bcp2",
	    SEPARATOR => '|',
	   ));			# 12
ok($X->run);			# 13

ok(@rows = $X->ct_sql("select * from $Db..bcp2")); # 14
ok(scalar(@rows) == 5);		# 15
ok($rows[2]->[1] == 3);		# 16
ok(!defined($rows[0]->[2]));	# 17
ok(!defined($rows[3]->[5]));	# 18
ok(!defined($rows[4]->[1]));	# 19

$X->ct_sql("if object_id('$Db..bcp2') is not null drop table $Db..bcp2");
$X->ct_sql("if object_id('$Db..bcp') is not null drop table $Db..bcp");
