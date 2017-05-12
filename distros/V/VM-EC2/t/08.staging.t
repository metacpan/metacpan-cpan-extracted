#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 31;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;

$SIG{TERM} = $SIG{INT} = sub { exit 0 };  # run the termination

# this script exercises the staging manager, servers and instances
my($ec2,$manager);
my $msg =
'
# This test will launch two "micro" instances under your Amazon account
# and then terminate them, incurring a one hour runtime charge for each.
# This will incur a charge of $0.04 (as of July 2012), which may be covered
# under the AWS free tier. Also be aware that this test may take several
# minutes to complete due to tests that launch, start, and stop instances.
#
# [this prompt will timeout automatically in 15s]
';

setup_environment();
require_ok('VM::EC2::Staging::Manager');

SKIP: {

skip "; account information unavailable",TEST_COUNT-1 unless setup_environment();
skip "; instance tests declined",        TEST_COUNT-1 unless confirm_payment($msg);
skip "; this system does not have ssh, rsh and dd command line tools in PATH", TEST_COUNT-1
    unless VM::EC2::Staging::Manager->environment_ok();

$ec2     = VM::EC2->new();
$manager = $ec2->staging_manager(-instance_type=> 't1.micro',
				 -on_exit      => 'run', # don't terminate user's servers!
				 -verbose      => 0,
    ) or BAIL_OUT("Can't load VM::EC2::Staging::Manager module");


# remove preexisting volumes, servers used for testing
cleanup();

my $volume_count = $manager->volumes;

print STDERR "# spinning up a test server...\n";
my $server1 = $manager->get_server(-name => 'test_server');
ok($server1,'staging server creation successful');
$server1->add_tag(StagingTest=>1);  # so that we can correctly identify and remove it

ok($server1->ping,'staging server is reachable');
my %servers = map {$_=>1} $manager->servers;
ok($servers{$server1},'staging server is registered correctly');

my $mgr = VM::EC2::Staging::Manager->new();
is($manager,$mgr,'manager behaves in a singleton manner');
is($mgr->on_exit,'run',"manager accessors don't change unexpectedly");

print STDERR "# allocating a test volume...\n";
my $volume = $manager->get_volume(-name    => 'test_volume',
				  -fstype  => 'ext3',
				  -size    => 1);
ok($volume,'volume creation works');
$volume->add_tag(StagingTest=>1);  # so that we can correctly identify and remove it
is($volume->fstype,'ext3','volume fstype method returns correct value');
ok($volume->size==1,'volume size method returns correct value');
is($volume->server,$server1,'volume is automounted on preexisting server');

my $vol  = $manager->get_volume(-name    => 'test_volume',
				-fstype  => 'ext3',
				-size    => 1);
is($vol,$volume,'get_volume() returns identical volume when same name requested');
my $testdir = $Bin;   # we're going to use current directory for file copying
ok($volume->put($testdir),'rsync exits with good status code');
my @listing = $volume->ls('-1','t');
is($listing[0],'01.describe.t','put copied files with correct structure');

# (need lots more tests of syntactic correctness of the rsync methods)

my $used_zone   = $server1->placement;
my ($new_zone)  = grep {$_ ne $used_zone} 
                  $manager->ec2->describe_availability_zones({state=>'available'});

print STDERR "# spinning up a second test server...\n";
my $server2 = $manager->get_server(-name              => 'test_server2',
				   -availability_zone => $new_zone);
isnt($server1,$server2,'got new server in new zone when zone forced');
$server2->add_tag(StagingTest=>1);  # so that we can correctly identify and remove it

ok($volume->mounted,'mounted state correct when mounted');
my @volumes = $server1->volumes;
cmp_ok(scalar @volumes,'==',1,'server1 has 1 volumes mounted');

print STDERR "# detaching/remounting volume...\n";
my $status = $volume->detach;
$ec2->wait_for_attachments($status);
ok(!$volume->mounted,'mounted state correct when detached');

@volumes = $server1->volumes;
cmp_ok(scalar @volumes,'==',0,'server1 has 0 volumes mounted');

$server1->mount_volume($volume=>'/mnt/test');
ok($volume->mounted,'mounted state correct when mounted');
is($volume->mtpt,'/mnt/test','volume mounted on correct mtpt');
is($volume->server,$server1,'volume mounted on correct server');
my $output = $server1->scmd('df /mnt/test');
my $mtdev  = $volume->mtdev;
like($output,"/$mtdev/mi",'server agrees with volume on mount point and device');

@volumes = $server1->volumes;
cmp_ok(scalar @volumes,'==',1,'server1 has 1 volume mounted');

print STDERR "# provisioning a second test volume...\n";
my $volume2 = $server2->provision_volume(-size=>1);
ok($volume2,'volume creation on server2 successful');
is($volume2->server,$server2,"volume2 has correct server");

@volumes    = $server2->volumes;
cmp_ok(scalar @volumes,'==',1,'server2 has 1 registered volume');

# try a copy
ok($manager->rsync($volume=>$volume2),'rsync from volume to volume successful');
@listing = $volume2->ls('-1','t');
is($listing[0],'01.describe.t','rsync copied files with correct structure');

@volumes    = $manager->volumes;
cmp_ok(scalar @volumes,'==',$volume_count + 2,'manager has 2 new registered volumes');
print STDERR "# deleting a volume...\n";
ok($volume2->delete,'volume deletion successful');

@volumes   = $manager->volumes;
cmp_ok(scalar @volumes,'==',$volume_count + 1,'manager has 1 new registered volume');

} # SKIP

exit 0;

sub cleanup {
    reset_cache();
    reset_declined();
    if ($ec2) {
	my @servers = $ec2->describe_instances({'tag:StagingTest' =>1,'instance-state-name'=>['running','stopped']});
	if (@servers) {
	    print STDERR "# terminating test staging servers\n";
	    $_->terminate foreach @servers;
	    $ec2->wait_for_instances(@servers);
	}
	my @volumes = $ec2->describe_volumes({'tag:StagingTest' =>1,status=>'available'});
	if (@volumes) {
	    print STDERR "# deleting test staging volumes\n";
	    $ec2->delete_volume($_) foreach @volumes;
	    $ec2->wait_for_volumes(@volumes);
	}
    }
}

END {
    cleanup();
}

