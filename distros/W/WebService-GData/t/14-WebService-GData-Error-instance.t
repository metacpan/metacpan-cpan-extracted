use Test::More tests => 1;
use WebService::GData::Error;

my $error = new WebService::GData::Error();

ok(ref($error) eq 'WebService::GData::Error','$error is a WebService::GData::Error instance.');


