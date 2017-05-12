#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 6;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;

$SIG{TERM} = $SIG{INT} = sub { exit 0 };  # run the termination

# this script exercises spot instance requests
my($ec2,@requests);

SKIP: {

skip "account information unavailable",TEST_COUNT unless setup_environment();

use_ok('VM::EC2',':standard','spot_instance');
$ec2 = VM::EC2->new(-print_error=>1,-region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");

my @requests = $ec2->request_spot_instances(-spot_price    => 0.001,  # too low - will never be satisfied
					    -instance_type => 't1.micro',
					    -image_id      => TEST_IMAGE,
					    -instance_count => 4,
					    -type           => 'one-time',
					    -security_group => 'default') or die $ec2->error_str;

is(scalar @requests,4,'Correct number of spot instances requested');
sleep 1; #??! 

my %state = map {$_->current_state => 1} @requests;
my @state = keys %state;
is("@state",'open','Spot instances are all open');

my $r = $ec2->describe_spot_instance_requests($requests[0]);
is($r,$requests[0],'describe_spot_instance_requests works');

my @c = $ec2->cancel_spot_instance_requests(@requests);
is(scalar @c, scalar @requests,'cancel_spot_instance_requests working as expected');

sleep 1; # ??!

%state = map {$_->current_state => 1} @requests;
@state = keys %state;
is("@state",'cancelled','spot instances are now cancelled');
}

undef @requests;

exit 0;

END {
    $ec2->cancel_spot_instance_requests(@requests)
	if $ec2 && @requests;
}
