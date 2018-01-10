# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl module_check.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;
my %hold = (
    'Digest::MD5'   => undef,
    'Crypt::OpenSSL::RSA'   => undef,
    'Crypt::OpenSSL::Bignum'=> undef,
    'Crypt::RSA'    => undef,
    #'JE'            => undef,
);
for my $module (keys %hold){
    eval "require $module";
    $hold{$module} = $@?$@:"ok";     
}

ok($hold{'Digest::MD5'} eq "ok", "module Digest::MD5 hasn't been installed?");
ok(($hold{'Crypt::OpenSSL::RSA'} eq "ok" and $hold{'Crypt::OpenSSL::Bignum'} eq "ok") || ($hold{'Crypt::RSA'} eq "ok") , "module Crypt::OpenSSL::RSA && Crypt::OpenSSL::Bignum hasn't been installed? \n see https://metacpan.org/pod/distribution/Webqq-Encryption/lib/Webqq/Encryption.pod for installation\n");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
