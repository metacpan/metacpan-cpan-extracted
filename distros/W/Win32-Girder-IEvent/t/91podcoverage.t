use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok("Win32::Girder::IEvent::Common","Win32::Girder::IEvent::Client","Win32::Girder::IEvent::Server");

