# This will test "easy" errors -- ones that don't require mocked HTTP responses
#
use 5.012; # strict, //
use warnings;
use Test::More;
use Test::Exception;

use WWW::KeePassHttp;

# need a "valid" object for some tests
my $kph = WWW::KeePassHttp->new(Key => "\0"x32);

# constructor: Key error checking
throws_ok { WWW::KeePassHttp->new() } qr/^\Q256-bit AES key is required/, 'constructor error: missing key';
throws_ok { WWW::KeePassHttp->new(Key => undef) } qr/^\Q256-bit AES key is required/, 'constructor error: undefined key';
throws_ok { WWW::KeePassHttp->new(Key => 0) } qr/^\QKey not recognized as 256-bit AES/, 'constructor error: unrecognizeable key';
throws_ok { WWW::KeePassHttp->new(Key => 'CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=') } qr/^\Q256-bit AES key must be in octets, not in base64/, 'constructor error: base64 key';
throws_ok { WWW::KeePassHttp->new(Key => "CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=\n") } qr/^\Q256-bit AES key must be in octets, not in base64/, 'constructor error: base64 key with newline';
throws_ok { WWW::KeePassHttp->new(Key => "091c9745b1fdbc191d3eb91d9b9d92ddb4c6dab1ad9d8bb226db64fe6949d798") } qr/^\Q256-bit AES key must be in octets, not hex nibbles/, 'constructor error: hex nibbles';
throws_ok { WWW::KeePassHttp->new(Key => "0x091c9745b1fdbc191d3eb91d9b9d92ddb4c6dab1ad9d8bb226db64fe6949d798") } qr/^\Q256-bit AES key must be in octets, not hex nibbles/, 'constructor error: hex nibbles with 0x';

# verify set_login parameters
throws_ok { $kph->set_login() } qr/^\Qset_login(): missing Login parameter/, 'set_login error: missing Login parameter';
throws_ok { $kph->set_login(Login=>'') } qr/^\Qset_login(): missing Url parameter/, 'set_login error: missing Url parameter';
throws_ok { $kph->set_login(Login=>'',Url=>'') } qr/^\Qset_login(): missing Password parameter/, 'set_login error: missing Password parameter';

done_testing();
