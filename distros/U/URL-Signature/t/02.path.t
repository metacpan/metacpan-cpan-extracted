use strict;
use warnings;
use Test::More;
use URL::Signature::Path;

ok my $signer = URL::Signature::Path->new( key => 'my-secret-key' );
isa_ok $signer, 'URL::Signature';
isa_ok $signer, 'URL::Signature::Path';

my $url = $signer->sign( '/foo/bar' );
is $url->as_string, '/St19oQIH7_iKcizaMtI9wRZi6B8/foo/bar', 'path sign()ing works fine';

done_testing;
