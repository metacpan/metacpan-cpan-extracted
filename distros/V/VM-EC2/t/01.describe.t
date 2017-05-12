#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use constant TEST_COUNT => 33;

use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use Test::More tests => TEST_COUNT;
use EC2TestSupport;

# this script tests all the describe() functions and associated features such as tags.
use_ok('VM::EC2',':standard');
reset_declined();

SKIP: {
skip "account information unavailable",TEST_COUNT-1 unless setup_environment();

my $ec2 = VM::EC2->new(-print_error=>1,-region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");
ok($ec2,'VM::EC2->new');

my $natty = $ec2->describe_images(TEST_IMAGE);  # defined in t/EC2TestSupport

if ($ec2->error_str =~ /SignatureDoesNotMatch/) {
    BAIL_OUT($ec2->error_str);
}

ok($natty,'describe image by id');

is($natty->imageLocation,'755060610258/ebs/ubuntu-images/ubuntu-natty-11.04-i386-server-20110426-nano','$image->imageLocation');
like($natty->description,'/http:\/\/nolar\.info\/nano-ami/','$image->description');
is($natty->architecture,'i386','$image->architecture');
is(($natty->blockDeviceMapping)[0],'/dev/sda1=snap-90ed13fe:1:true:standard','$image->blockDeviceMapping');
is($natty->imageState,'available','$image->imageState');

my $owner = $natty->imageOwnerId();
my @i = $ec2->describe_images(-ownerId=>$natty->imageOwnerId,
			      -filter=>{description=>$natty->description,
					'manifest-location'=>$natty->imageLocation});
ok (@i == 1,'describe_images() with multiple filters');
is ($i[0],$natty,'describe_images() with multiple filters returns expected image');

# test tagging
ok($natty->add_tags(Name=>'MyFavoriteImage',Description=>'Test tag added by VM::EC2'),'tag addition');
$natty->refresh;
my $tags = $natty->tags;
is($tags->{Name},'MyFavoriteImage','tag retrieval');

@i = $ec2->describe_images(-filter=>{'tag:Name'        => 'MyFavoriteImage',
				     'tag:Description' => '*VM::EC2'});
is ($i[0],$natty,'retrieve by tags');

ok($natty->add_tags(Name=>'MyLeastFavoriteImage'),'tag replacement');
sleep 1; # takes a while to register
$natty->refresh;
is($natty->tags->{Name},'MyLeastFavoriteImage','tag replacement');

ok($natty->delete_tags(['Name','Description']),'tag deletion');
sleep 1; # takes a short while to register
$natty->refresh;
$tags = $natty->tags;  # should be no tags now
is(scalar keys %$tags,0,'tag deletion');

# exercise availability regions and keys
my @regions = $ec2->describe_regions;
ok(scalar @regions,'describe regions');

my $r       = $ec2->describe_regions($regions[0]);
is ($r,$regions[0],'describe regions by name');

my @zones = $ec2->describe_availability_zones();
ok(scalar @zones,'describe zones');

my $z = $ec2->describe_availability_zones($zones[0]);
is ($z,$zones[0],'describe zones by name');

# make sure that we can get zones from each region
my $cnt;
foreach (@regions) {
    @zones = $_->zones;
    $cnt++ if @zones;
}
is ($cnt,scalar @regions,'each region has availability zones');

my @keys    = $ec2->describe_key_pairs;
ok(scalar @keys,'describe keys');

# security groups
my @sg = $ec2->describe_security_groups();
ok(@sg>0,'describe_security_groups');
ok(scalar(grep {$_->name =~ /default/} @sg),'default security group present');

# error handling
$ec2->print_error(0);
is($ec2->call('IncorrectAction'),undef,'errors return undef');
my $error = $ec2->error;
is($error->code,'InvalidAction','error code on invalid action');

is($ec2->call('RunInstances',(Foo=>'bar')),undef,'errors return undef');
is($ec2->error->code,'UnknownParameter','error code on invalid parameter');
my $msg = $ec2->error->message;
like($ec2->error_str,qr/UnknownParameter/,'error code interpolation');
like($ec2->error_str,qr/$msg/,'error message interpolation');
my $e = $ec2->error;
is($ec2->error_str,"$e",'error object interpolation');

$ec2->raise_error(1);
eval {
    $ec2->call('RunInstances',(Foo=>'bar'));
};
like($@,qr/UnknownParameter/,'raise error mode');
$ec2->raise_error(0);
}

exit 0;

