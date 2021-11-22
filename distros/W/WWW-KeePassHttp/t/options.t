# test the constructor options and configuration methods
use 5.012; # strict, //
use warnings;
use Test::More;
use MIME::Base64;

use WWW::KeePassHttp;

my $kph;
my $key = decode_base64(my $key64='CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=');

# constructor: appid override
$kph = WWW::KeePassHttp->new( Key => $key, appid => 'different app');
is $kph->{appid}, 'different app', 'constructor appid override';

# constructor: full URL override
$kph = WWW::KeePassHttp->new( Key => $key, request_base => 'http://127.0.0.1', request_port => '12345');
is $kph->{request_base}, 'http://127.0.0.1', 'constructor request_base override (full override)';
is $kph->{request_port}, '12345', 'constructor request_port override (full override)';
is $kph->{request_url}, 'http://127.0.0.1:12345', 'constructor request_url result (full override)';

# constructor: partial url base override
$kph = WWW::KeePassHttp->new( Key => $key, request_port => '12345');
is $kph->{request_base}, 'http://localhost', 'constructor request_base default (partial override base)';
is $kph->{request_port}, '12345', 'constructor request_port override (partial override base)';
is $kph->{request_url}, 'http://localhost:12345', 'constructor request_url result (partial override base)';

# constructor: partial url port override
$kph = WWW::KeePassHttp->new( Key => $key, request_base => 'http://127.0.0.1');
is $kph->{request_base}, 'http://127.0.0.1', 'constructor request_base override (partial override port)';
is $kph->{request_port}, '19455', 'constructor request_port default (partial override port)';
is $kph->{request_url}, 'http://127.0.0.1:19455', 'constructor request_url result (partial override port)';

# config: appid override
$kph = WWW::KeePassHttp->new( Key => $key );
$kph->appid('config appid');
is $kph->appid(), 'config appid', 'config appid override';

# config: partial url base override
$kph = WWW::KeePassHttp->new( Key => $key );
$kph->request_port('12345');
is $kph->request_base, 'http://localhost', 'config request_base default (partial override base)';
is $kph->request_port, '12345', 'config request_port override (partial override base)';
is $kph->{request_url}, 'http://localhost:12345', 'config request_url result (partial override base)';

# config: partial url port override
$kph = WWW::KeePassHttp->new( Key => $key );
$kph->request_base('http://127.0.0.1');
is $kph->{request_base}, 'http://127.0.0.1', 'config request_base override (partial override port)';
is $kph->{request_port}, '19455', 'config request_port default (partial override port)';
is $kph->{request_url}, 'http://127.0.0.1:19455', 'config request_url result (partial override port)';

# keep alive
$kph = WWW::KeePassHttp->new( Key => $key, keep_alive => 0 );
is $kph->{ua}->{keep_alive}, 0, 'constructor: override keep_alive 0';
$kph = WWW::KeePassHttp->new( Key => $key, keep_alive => 1 );
is $kph->{ua}->{keep_alive}, 1, 'constructor: override keep_alive 1';


done_testing(19);
