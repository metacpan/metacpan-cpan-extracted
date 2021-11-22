# This will test "easy" errors -- ones that don't require mocked HTTP responses
#
use 5.012; # strict, //
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'WWW::KeePassHttp::Entry';
}

my $e;

# verify constructor working
lives_ok { $e = WWW::KeePassHttp::Entry->new( Url => 'entry.url', Login => 'entry.login', Password => 'entry.pw') } 'entry success: normal entry';
isa_ok $e,  'WWW::KeePassHttp::Entry', 'Normal Entry';

# verify constructor working with UUID
lives_ok { $e = WWW::KeePassHttp::Entry->new( Url => 'entry.url', Login => 'entry.login', Password => 'entry.pw', Uuid => 'entry.uuid') } 'entry success: entry with UUID';
isa_ok $e,  'WWW::KeePassHttp::Entry', 'Entry with UUID';

# verify setters
is $e->url('https://new.url'), 'https://new.url', 'entry->url(): setter returns new value';
is $e->login('entry.username'), 'entry.username', 'entry->login(): setter returns new value';
is $e->password('entry.password'), 'entry.password', 'entry->password(): setter returns new value';
is $e->uuid('entry.uuid'), 'entry.uuid', 'entry->uuid(): setter returns new value';

# verify getters: by doing these in bulk after the bulk setters, it verifies they don't overwrite each other
is $e->url(), 'https://new.url', 'entry->url(): getter returns same value';
is $e->login(), 'entry.username', 'entry->login(): getter returns same value';
is $e->password(), 'entry.password', 'entry->password(): getter returns same value';
is $e->uuid(), 'entry.uuid', 'entry->uuid(): getter returns same value';

# verify errors
throws_ok { $e = WWW::KeePassHttp::Entry->new( Login => 'entry.login', Password => 'entry.pw') } qr/^\Qmissing Url/, 'entry error: missing URL';
throws_ok { $e = WWW::KeePassHttp::Entry->new( Url => 'entry.url', Password => 'entry.pw') } qr/^\Qmissing Login/, 'entry error: missing Login';
throws_ok { $e = WWW::KeePassHttp::Entry->new( Url => 'entry.url', Login => 'entry.login') } qr/^\Qmissing Password/, 'entry error: missing Password';

done_testing(16);
