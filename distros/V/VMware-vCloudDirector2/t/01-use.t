use strict;
use Test::More;

# see if each of these can be loaded
foreach my $module (
    qw [
    VMware::vCloudDirector2::API
    VMware::vCloudDirector2::Error
    VMware::vCloudDirector2::Link
    VMware::vCloudDirector2::Object
    VMware::vCloudDirector2
    ]
) {
    use_ok($module);
}

done_testing;
