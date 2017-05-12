#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 33;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;
use constant IMG_NAME => 'Test_Image_from_libVM_EC2';

$SIG{TERM} = $SIG{INT} = sub { exit 0 };  # run the termination

# this script exercises instances and volumes
my($ec2, $instance,$key,$address,$deallocate_address,$volume,$image);

my $msg =
'
# The next two tests will launch three "micro" instances under your Amazon account
# and then terminate them, incurring a one hour runtime charge each. This will
# incur a charge of $0.06 (as of July 2012), which may be covered under 
# the AWS free tier. Also be aware that these tests may take a while
# (several minutes) due to tests that launch, start, and stop instances.
# (this prompt will timeout automatically in 15s)
';

SKIP: {

skip "account information unavailable",TEST_COUNT unless setup_environment();
skip "instance tests declined",        TEST_COUNT unless confirm_payment($msg);

use_ok('VM::EC2',':standard');
$ec2 = VM::EC2->new(-print_error=>1,-region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");

cleanup();

my $natty = $ec2->describe_images(TEST_IMAGE);  # defined in t/lib/EC2TestSupport
BAIL_OUT($ec2->error_str) unless $natty;			

$key     = $ec2->create_key_pair("MyTestKey$$");
$key or BAIL_OUT("could not create test key");

my $finger  = $key->fingerprint;

print STDERR "# Spinning up an instance...\n";

$instance = $natty->run_instances(-max_count     => 1,
				  -user_data     => 'xyzzy',
				  -key_name      => $key,
				  -instance_type => 't1.micro') or warn $ec2->error_str;
sleep 1;
ok($instance,'run_instances()');
$instance->add_tags(Name=>'test instance created by VM::EC2');
$ec2->wait_for_instances($instance);
is($instance->current_status,'running','instance is running');
is($instance->userData,'xyzzy','user data is available to instance');

# allocate or reuse an elastic IP address to test association
my @addresses = grep {!$_->instanceId} $ec2->describe_addresses();
if (@addresses) {
    $address = $addresses[0];
} else {
    $address = $ec2->allocate_address;
    $deallocate_address++;
}
SKIP: {
    skip "no elastic addresses available for testing",2 unless $address;
    ok($instance->associate_address($address),'elastic address association');
    sleep 2;
    $instance->refresh;
    ok($instance->disassociate_address($address),'address disassociation');
}

# volume management
my $zone   = $instance->placement;
$volume = $ec2->create_volume(-size=>1,-availability_zone=>$zone) or warn $ec2->error_str;
$volume->add_tag(Name=>'Test volume created by VM::EC2');
ok($volume,'volume creation');

$ec2->wait_for_volumes($volume);
SKIP: {
    skip "could not create a new volume, status was ".$volume->current_status,6
	unless $volume->current_status eq 'available';
    my $a = $instance->attach_volume($volume => '/dev/sdg1');
    ok($a,'attach()');
    $ec2->wait_for_attachments($a);

    is($a->current_status,'attached','attach volume to instance');
    ok(!$a->deleteOnTermination,'delete on termination flag set to false');
    $a->deleteOnTermination(1);
    $a->refresh;
    ok($a->deleteOnTermination,'delete on termination flag set to true');

    is($volume->current_status,'in-use','volume reports correct attachment');

    my @mapping = $instance->blockDeviceMapping;
    my ($b) = grep {$_ eq '/dev/sdg1'} @mapping;
    ok($b,'block device mapping reports correct list');
    ok($b->deleteOnTermination,'delete on termination flag set to true');
    $b->deleteOnTermination(0);
    ($b) = grep {$_ eq '/dev/sdg1'} $instance->blockDeviceMapping;
    ok(!$b->deleteOnTermination,'set delete on termination to false');

    is($volume->deleteOnTermination,$b->deleteOnTermination,'deleteOnTermination flags in sync');
    
    my $d = $volume->detach;
    ok($d,'detach volume from instance');
    $ec2->wait_for_attachments($d);
    is($volume->current_status,'available','detached volume becomes available');
    ok($ec2->delete_volume($volume),'delete volume');
    undef $volume;
}

$ec2->print_error(0); # avoid deliberate error message
ok(!$instance->userData('abcdefg'),"don't change user data on running instance");
$ec2->print_error(1);

print STDERR "# Stopping instance...\n";
ok($instance->stop('wait'),'stop running instance');
is($instance->current_status,'stopped','stopped instance reports correct state');
ok($instance->userData('abcdefg'),"can change user data on stopped instance");
is($instance->userData,'abcdefg','user data set ok');

# after stopping instance, should be console output
ok($instance->console_output,'console output available');
like($instance->console_output,qr/Linux version/,'console output is plausible');

# create an image here
print STDERR "# Creating an image...\n";
$image = $instance->create_image(-name=>IMG_NAME,-description=>'Delete me!') or warn $ec2->error_str;
ok($image,'create image ok');
SKIP: {
    skip "image tests skipped because image creation failed",5 unless $image;
    for (my $cnt=0; $cnt<20 && $image->current_status eq 'pending'; $cnt++) {
	sleep 5;
    }
    is($image->current_status,'available','image becomes available');
    ok(!$image->is_public,'newly created image not public');
    ok($image->make_public(1),'make image public');
    ok($image->is_public,'image now public');
    my @block_devices = $image->blockDeviceMapping;
    ok(@block_devices>0,'block devices defined in image');

    my @snapshots = map {$_->snapshotId} @block_devices;
    ok($ec2->deregister_image($image),'deregister_image');

    foreach (@snapshots) {
	$ec2->delete_snapshot($_) if $_;
    }
}

}  # SKIP


exit 0;

END {
    $ec2->print_error(0) if $ec2;

    if ($instance) {
	print STDERR "# Terminating $instance...\n";
	$instance->terminate();
    }
    if ($key) {
	print STDERR "# Removing test key...\n";
	$ec2->delete_key_pair($key);
    }
    if ($address && $deallocate_address) {
	print STDERR "# Deallocating $address...\n";
	$ec2->release_address($address);
    }
    if ($volume) {
	print STDERR "# Deleting volume...\n";
	my $a = $volume->detach();
	$ec2->wait_for_attachments($a) if $a;
	$ec2->delete_volume($volume);
    }
    if ($image) {
	print STDERR "# Deleting image...\n";
	$ec2->deregister_image($image);
    }
    cleanup();
}

sub cleanup {
    return unless $ec2;
    my $img = $ec2->describe_images({name=>IMG_NAME});
    if ($img) {
	print STDERR "Deleting dangling image...\n";
	$ec2->deregister_image($img);
    }
    my @v = $ec2->describe_volumes({'tag:Name'=>'Test volume created by VM::EC2'});
    if (@v) {
	print STDERR "Deleting dangling volumes...\n";
	$ec2->delete_volume($_) foreach @v;
    }
}
