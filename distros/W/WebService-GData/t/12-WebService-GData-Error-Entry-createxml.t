use Test::More tests => 5;
use WebService::GData::Error::Entry;

my $xml_inline=q[<error><code>invalid_character</code><domain>yt:validation</domain><location type='xpath'>media:group/media:title/text()</location></error>];

my $entry = new WebService::GData::Error::Entry();
   $entry->code('invalid_character');
   $entry->domain('yt:validation');
   $entry->location({type=>'xpath',content=>'media:group/media:title/text()'});
   $entry->location;


ok($entry->domain eq 'yt:validation','domain is properly parsed.');
ok($entry->code eq 'invalid_character','code is properly parsed.');
ok($entry->location->{type} eq 'xpath','location type is properly parsed.');
ok($entry->location->{content} eq 'media:group/media:title/text()','location content is properly parsed.');
ok($entry->serialize eq $xml_inline,'serialize outputs the proper xml.');


