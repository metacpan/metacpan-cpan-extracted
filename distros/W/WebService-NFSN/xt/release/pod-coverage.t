#! /usr/bin/perl -T
#---------------------------------------------------------------------
# pod-coverage.t
#---------------------------------------------------------------------

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

#---------------------------------------------------------------------
my @private = map { qr/^$_/ } qw(
  decode_json make_request object_type root_url
);

my %parameters = ( also_private => \@private );

#---------------------------------------------------------------------
# WebService::NFSN::Object is entirely private:

my @modules = grep { $_ ne 'WebService::NFSN::Object' } all_modules();

plan tests => scalar @modules;

foreach my $module (@modules) {
  pod_coverage_ok($module, \%parameters, "Pod coverage on $module");
}
