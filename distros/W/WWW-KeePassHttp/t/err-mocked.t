# This will test through a standard workflow / use-case to read an entry from KeePass
#
use 5.012; # strict, //
use warnings;
use Test::More;
use Test::Exception;
use Test::MockObject;
use MIME::Base64;
use JSON;

my $mock;

BEGIN {
    $mock = Test::MockObject->new();
    $mock->fake_module( 'HTTP::Tiny' );
    $mock->fake_new( 'HTTP::Tiny' );
    $mock->set_isa( 'HTTP::Tiny' );
}

# this is the series of ->get() results, required to provoke various error conditions
my @series = (
    {
        content  => "{\"RequestType\":\"get-logins\",\"Success\":true,\"Id\":\"err-mocked.t\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\",\"Entries\":[{\"Login\":\"URDpgbTnHWZfMd9mddik3Q==\",\"Password\":\"k0krqs1+W2mc3QBJP01Z5w==\",\"Uuid\":\"BmcYDdjoivBoG3dYozsaqOkJuBeZMQYKeQjnND+Xjfzzr/d/UPD0/QsuDcvj2ZnF\",\"Name\":\"AfeSGKHYGqtslglqqzKo7Q==\"}]}",
        success => 1,
    },
    {
        content  => "{\"RequestType\":\"get-logins\",\"Success\":true,\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\",\"Entries\":[{\"Login\":\"URDpgbTnHWZfMd9mddik3Q==\",\"Password\":\"k0krqs1+W2mc3QBJP01Z5w==\",\"Uuid\":\"BmcYDdjoivBoG3dYozsaqOkJuBeZMQYKeQjnND+Xjfzzr/d/UPD0/QsuDcvj2ZnF\",\"Name\":\"AfeSGKHYGqtslglqqzKo7Q==\"}]}",
        success => 1,
    },
    {
        success => 0,   # get() returns !success, so there is no JSON, as opposed to the content JSON says Success:false
    },
    {   # successful get(), but no content in reply
        success => 1,
    },
    {   # successful get(), but content is not json string
        success => 1,
        content => [],
    },
    {   # missing verifier for DNE
        content  => "{\"RequestType\":\"DNE\",\"Success\":true,\"Id\":\"err-mocked.t\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\"}",
        success => 1,
    },
    {   # missing nonce for DNE
        content  => "{\"RequestType\":\"DNE\",\"Success\":true,\"Id\":\"err-mocked.t\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\"}",
        success => 1,
    },
    {   # missing verifier for ASSOCIATE
        content  => "{\"RequestType\":\"associate\",\"Success\":true,\"Id\":\"err-mocked.t\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\"}",
        success => 1,
    },
    {   # mismatch between NONCE and VERIFIER
        content  => "{\"RequestType\":\"DNE\",\"Success\":true,\"Id\":\"err-mocked.t\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"BqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\"}",
        success => 1,
    },
    # content  => "{\"RequestType\":\"DNE\",\"Success\":false,\"Version\":\"1.8.4.2\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\"}",
    #undef,
    # { # valid associate response
    #     content  => "{\"RequestType\":\"get-logins\",\"Success\":true,\"Id\":\"WWW::KeePassHttp\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\",\"Entries\":[{\"Login\":\"URDpgbTnHWZfMd9mddik3Q==\",\"Password\":\"k0krqs1+W2mc3QBJP01Z5w==\",\"Uuid\":\"BmcYDdjoivBoG3dYozsaqOkJuBeZMQYKeQjnND+Xjfzzr/d/UPD0/QsuDcvj2ZnF\",\"Name\":\"AfeSGKHYGqtslglqqzKo7Q==\"}]}",
    #     success => 1,
    # },
);
$mock->set_series( get => @series );

use WWW::KeePassHttp;

# need an object for some tests
my $key = decode_base64(my $key64='CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=');
my $kph = WWW::KeePassHttp->new(Key => $key);

# verify association() error handling
throws_ok { $kph->associate(); } qr/Wrong ID:/, 'associate error: Wrong App ID';
throws_ok { $kph->associate(); } qr/Wrong ID:/, 'associate error: missing (ie, undefined) ID';

# verify request() error handling
throws_ok { $kph->request( 'DNE' ) } qr/\Qrequest_error/, 'request error: failed HTTP get()';
throws_ok { $kph->request( 'DNE' ) } qr/\Qno_json/, 'request error: no content (JSON or otherwise) with HTTP reply';
throws_ok { $kph->request( 'DNE' ) } qr/\Qmalformed JSON string/, 'request error: content is not JSON string';
throws_ok { $kph->request( 'DNE' ) } qr/\Qmissing_verifier/, 'request error: missing verifier on alternate action';
throws_ok { $kph->request( 'DNE' ) } qr/\Qmissing_verifier/, 'request error: missing nonce on alternate action';
lives_ok  { $kph->request( 'associate' ) } 'no request error: missing verifier on associate is allowed';
throws_ok { $kph->request( 'DNE' ) } qr/\QDecoded Verifier/, 'request error: mismatch between nonce and verifier';

done_testing();
