# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-LevelDB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 30;
BEGIN { use_ok('Tie::LevelDB') };

#########################

my $DBDIR = "/tmp/leveldb-test";
my $LevelDB_Class = "Tie::LevelDB";

# 1. Test LevelDB API
{
system("rm -rf $DBDIR");
my $db = Tie::LevelDB::DB->new($DBDIR);
is(ref $db,"Tie::LevelDB::DB");
ok(-d $DBDIR);

is($db->Get("k1"),undef);
$db->Put("k1","v1");
is($db->Get("k1"),"v1");
$db->Delete("k1");
is($db->Get("k1"),undef);
}

# 2. Test TIEHASH API

# tests like in GDBM_File

system("rm -rf $DBDIR");

my %h;
isa_ok(tie(%h, $LevelDB_Class, $DBDIR), $LevelDB_Class);
ok(-d $DBDIR);

ok(not exists $h{k1});
is($h{k1}, undef);
$h{k1} = '';
ok(exists $h{k1});
$h{k1} = undef;
ok(not exists $h{k1}); # limitation of LevelDB
is($h{k1}, undef);
delete $h{k1};
is($h{k1}, undef);
ok(not exists $h{k1});

$h{"\0"} = "\0";
ok(exists $h{"\0"});
is($h{"\0"}, "\0");
delete $h{"\0"};
ok(not exists $h{"\0"});

$h{k1} = "V1";
is($h{k1}, "V1");

my @keys = keys %h;
is(scalar(@keys),1);
is($keys[0],"k1");

$h{k1} = "V1a";
is(scalar(keys %h),1);
$h{k2} = "V2";
is(scalar(keys %h),2);
is(scalar(%h),2);
delete $h{k1};
is(scalar(keys %h),1);

%h = ();
is(scalar(keys %h),0);

$h{'jkl','mno'} = "JKL\034MNO";

$h{'goner2'} = 'snork';
delete $h{'goner2'};

untie(%h);
isa_ok(tie(%h, $LevelDB_Class, $DBDIR), $LevelDB_Class);

$h{'goner3'} = 'snork';

delete $h{'goner1'};
delete $h{'goner2'};

is(scalar(keys %h), 2);

open my $fh, "|-", $^X, "-Mblib" or die $!;
print $fh <<EOF;
use $LevelDB_Class;
eval { tie my %h, "$LevelDB_Class", "$DBDIR" };
die if \$@ !~ /LOCK/;
EOF
close $fh;
ok +($? >> 8) == 0, "Unable to open locked DB";

untie %h;

is(scalar(keys %h), 0);

system("rm -rf $DBDIR");

system("rm -rf /tmp/stress-*");

