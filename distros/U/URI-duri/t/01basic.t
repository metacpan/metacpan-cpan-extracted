use Test::More tests => 6;

BEGIN { use_ok('URI::duri') };
BEGIN { use_ok('URI::tdb') };

my $duri = new_ok 'URI::duri', ['duri:2012:urn:example'];
isa_ok $duri, 'URI';

my $tdb = new_ok 'URI::tdb', ['duri:2012:urn:example'];
isa_ok $tdb, 'URI';
