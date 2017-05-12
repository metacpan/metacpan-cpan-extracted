#!perl -T

use strict;
use warnings;

use Test::More;

diag(
    "Testing WebService::ScormCloud $WebService::ScormCloud::VERSION, Perl $], $^X"
);

my @modules;

BEGIN
{
    @modules = qw(
      WebService::ScormCloud
      WebService::ScormCloud::Types
      WebService::ScormCloud::Service
      WebService::ScormCloud::Service::Course
      WebService::ScormCloud::Service::Debug
      WebService::ScormCloud::Service::Registration
      WebService::ScormCloud::Service::Reporting
      );

    foreach my $module (@modules)
    {
        use_ok($module);
    }
}

done_testing(scalar @modules);

