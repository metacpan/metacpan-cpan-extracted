#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use JSON;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use constant TEST_COUNT => 18;
use Test::More tests => TEST_COUNT;
use EC2TestSupport;

# this script tests the security tokens and policy

setup_environment();

use_ok('VM::EC2',':standard');
require_ok('VM::EC2::Security::Policy');
SKIP: {
skip "account information unavailable",TEST_COUNT-2 unless setup_environment();

my $ec2 = VM::EC2->new(-print_error=>1,
		       -region=>'us-east-1') or BAIL_OUT("Can't load VM::EC2 module");

# create a policy
my $policy = VM::EC2::Security::Policy->new();
ok($policy,'create policy');

my $default = {
    Statement => [
        {
            Action   => [ 'ec2:*' ],
            Effect   => 'Deny',
            Resource => '*'
        }
    ]
};

my $json = JSON->new();
$json->canonical(1);

# default policy should be to deny all
is("$policy", $json->encode($default),'default policy is deny all');

# allow describing everything
$policy->allow('Describe*');

# except images
$policy->deny('DescribeImages');

# adding the same thing twice doesn't make it appear twice
$policy->allow('Describe*','RunInstances');

my $exp = {
    Statement => [
        {
            Action   => [ 'ec2:Describe*', 'ec2:RunInstances' ],
            Effect   => 'Allow',
            Resource => '*',
        },
        {
            Action   => [ 'ec2:DescribeImages' ],
            Effect   => 'Deny',
            Resource => '*',
        }
    ],
};
is("$policy", $json->encode($exp), 'allow/deny');

my $token = $ec2->get_federation_token(-name     => 'TestUser',
				       -policy   => $policy,
				       -duration => 60*60, # 1 hour
    );
ok($token);
cmp_ok($token->packedPolicySize,'>',0,'packed policy size > 0');

my $credentials = $token->credentials;
ok($credentials,'credentials');

my $user        = $token->federatedUser;
ok($user,'federated user');
like($user,qr/TestUser/,'expected username in credentials');

my $serialized = $credentials->serialize;
ok($serialized,'serialization');

my $new_credentials = VM::EC2::Security::Credentials->new_from_serialized($serialized);
foreach (qw(sessionToken accessKeyId secretAccessKey expiration)) {
    is($credentials->$_,$new_credentials->$_,"serialized and unserialized credentials $_ field matches");
}

my $new_ec2 = VM::EC2->new(-security_token=> $token,
			   -region        => 'us-east-1'
    );
my @zones   = $new_ec2->describe_availability_zones(); # this should work
cmp_ok(scalar @zones,'>',0,'policy allows describe_availability_zones');

my @images = $new_ec2->describe_images(); # this should be forbidden
cmp_ok(scalar @images,'==',0,'policy forbids describe_images');
like($new_ec2->error_str,qr/UnauthorizedOperation/,'error message forbids describe_images');

}

exit 0;
