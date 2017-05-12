use strict;
use Test::More;

# see if each of these can be loaded
foreach my $module (
    qw [
    VMware::vCloudDirector::API
    VMware::vCloudDirector::Error
    VMware::vCloudDirector::Link
    VMware::vCloudDirector::Object
    VMware::vCloudDirector
    ]
    ) {
    use_ok($module);
}

done_testing;
