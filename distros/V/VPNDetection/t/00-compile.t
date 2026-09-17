use strict;
use warnings;

use Test::More;

my @modules = qw(
    VPNDetection
    VPNDetection::Bogon
    VPNDetection::Bogons
    VPNDetection::Cache
    VPNDetection::Database
    VPNDetection::Error
    VPNDetection::Oauth
    VPNDetection::OauthError
    VPNDetection::Result
);

use_ok($_) for @modules;

# Makefile.PL takes the distribution version from VPNDetection.pm alone, so a
# module left behind would ship indexed at the wrong version. A forgotten bump is
# a test failure rather than a bad release.
my $version = VPNDetection->VERSION;
ok($version, "the distribution version is $version");
# The two refusal subclasses live in OauthError.pm, so they are loaded, not used.
my @packages = (@modules, qw(VPNDetection::OauthAccessDeniedError VPNDetection::OauthExpiredTokenError));
for my $module (grep { $_ ne 'VPNDetection::Bogons' } @packages) {
    is($module->VERSION, $version, "$module is at $version");
}

done_testing();
