#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 25;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;

$SIG{TERM} = $SIG{INT} = sub { exit 0 };  # run the termination

# this script tests the security groups
use constant VOLUME_NAME => 'VM::EC2 Test Volume';
use constant VOLUME_DESC => 'Delete me!';

my ($ec2);

use_ok('VM::EC2',':standard');

SKIP: {
skip "account information unavailable",TEST_COUNT-1 unless setup_environment();

$ec2 = VM::EC2->new(-print_error=>1,-region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");

# in case the test was interrupted earlier
cleanup();

my ($zone) = $ec2->describe_availability_zones();
ok($zone,'describe_availability_zones()');

my $v = $ec2->create_volume(-zone=>$zone,-size=>1);
ok($v,'create_volume()');
ok($v->add_tag(Name=>VOLUME_NAME,Description=>VOLUME_DESC),'add_tag()');

for (my $cnt=0; $cnt<20 && $v->current_status eq 'creating'; $cnt++) {
    sleep 2;
}
is($v->current_status,'available','volume becomes available');

my $s = $v->create_snapshot(VOLUME_DESC);
ok($s->add_tag(Name=>VOLUME_NAME),'add_tag()');
ok($s,'create_snapshot()');
for (my $cnt=0; $cnt<10 && $s->current_status eq 'pending'; $cnt++) {
    sleep 2;
}
is($s->current_status,'completed','snapshot completed');
is($s->from_volume,$v,'from_volume() worked correctly');
my @v = $s->to_volumes();
is(scalar @v,0,'to_volumes() on new snapshot returns empty list');

ok(!$s->is_public,'newly-created snapshots not public');
ok($s->make_public(1),'make public(true)');
ok($s->is_public,'public status set correctly');
ok($s->make_public(0),'make_public(false)');
ok($s->add_authorized_users($ec2->account_id),'add_authorized_users()');
my @u = $s->authorized_users;
is(scalar @u,1,'right number of authorized users');
is($u[0],$ec2->account_id,'right authorized user');
ok($s->remove_authorized_users($ec2->userId),'remove_authorized_users()');
@u = $s->authorized_users;
is(scalar @u,0,'remove authorized users worked');

# make a volume from this snapshot
my $newvol = $s->create_volume(-zone=>$zone);
ok($newvol->add_tag(Name=>VOLUME_NAME,Description=>VOLUME_DESC),'add_tag()');

ok($newvol,'create_volume() from snapshot');
is($newvol->size,$v->size,'size matches');
@v = $s->to_volumes;
is(scalar @v,1,'to_volumes() returns one volume');
is($v[0],$newvol,'to_volumes() returns correct volume id');
is($v[0]->snapshotId,$s,'snapshotId() is correct');
}

exit 0;

sub cleanup {
    return unless $ec2;
    my @volumes   = $ec2->describe_volumes({'tag:Name'=>VOLUME_NAME});
    $ec2->delete_volume($_) foreach @volumes;
    my @snapshots = $ec2->describe_snapshots({'tag:Name'=>VOLUME_NAME});
    $ec2->delete_snapshot($_) foreach @snapshots;
}

END {
    if ($ec2) {
	print STDERR "# deleting test volumes and snapshots...\n";
	cleanup();
    }
}
