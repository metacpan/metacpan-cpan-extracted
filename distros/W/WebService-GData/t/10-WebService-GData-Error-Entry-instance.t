use Test::More tests => 1;
use WebService::GData::Error::Entry;

my $entry = new WebService::GData::Error::Entry();

ok(ref($entry) eq 'WebService::GData::Error::Entry','$entry is a WebService::GData::Error::Entry instance.');


