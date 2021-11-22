# This will test through some alternate paths that require mocking
#
use 5.012; # strict, //
use warnings;
use Test::More;
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

my @series = (
    {
        content  => "{\"RequestType\":\"get-logins\",\"Success\":true,\"Id\":\"WWW::KeePassHttp\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\",\"Entries\":[{\"Login\":\"URDpgbTnHWZfMd9mddik3Q==\",\"Password\":\"k0krqs1+W2mc3QBJP01Z5w==\",\"Uuid\":\"BmcYDdjoivBoG3dYozsaqOkJuBeZMQYKeQjnND+Xjfzzr/d/UPD0/QsuDcvj2ZnF\",\"Name\":\"AfeSGKHYGqtslglqqzKo7Q==\"}]}",
        success => 1,
    },
    {
        content  => "{\"RequestType\":\"get-logins-count\",\"Success\":true,\"Id\":\"WWW::KeePassHttp\",\"Count\":1,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"5ExkCS6g7jGQLf/IIc7DGQ==\",\"Verifier\":\"uK0gRC1ERf2+XYL4ji/ERLmrWQZwjPXP4lVRi+NQ7Xw=\"}",
        success => 1,
    },
    {
        content  => "{\"RequestType\":\"get-logins\",\"Success\":true,\"Id\":\"WWW::KeePassHttp\",\"Count\":0,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"AqvxYWMArZTbRoZcU+a21Q==\",\"Verifier\":\"rl6RCAhGIvGdNB5J/6Yo5p5+8c3K/6Yg9sK3G2CXysw=\",\"Entries\":[{\"Login\":\"URDpgbTnHWZfMd9mddik3Q==\",\"Password\":\"k0krqs1+W2mc3QBJP01Z5w==\",\"Uuid\":\"BmcYDdjoivBoG3dYozsaqOkJuBeZMQYKeQjnND+Xjfzzr/d/UPD0/QsuDcvj2ZnF\",\"Name\":\"AfeSGKHYGqtslglqqzKo7Q==\"}]}",
        success => 1,
    },
    {
        content  => "{\"RequestType\":\"set-login\",\"Success\":true,\"Id\":\"WWW::KeePassHttp\",\"Count\":0,\"Version\":\"1.8.4.2\",\"Hash\":\"91dfdf648925fa42f69f1dbe3b012afcc43aca42\",\"Nonce\":\"gSJXXhByYIhc6zpnbG8FpA==\",\"Verifier\":\"S5PbXFEtbVwsXcBjYMM1EurG+7XsfcN2NI2R/Clunho=\"}",
        success => 1,
    },
);
$mock->set_series( get => @series );

sub test_next_get_params
{
    my ($name, $arglist, $testname_prefix, %match_args) = @_;
    #is $name, 'get', $testname_prefix . ": is a get";
    (undef, my $get_url, my $get_options) = @$arglist;

    is $get_url, delete($match_args{GET_URL}), "$testname_prefix: UA received correct GET_URL" if exists $match_args{GET_URL};

    ok exists $get_options->{content}, "$testname_prefix: UA received content";

    my $content = decode_json($get_options->{content})//{};

    my $nonce; $nonce = $content->{Nonce} if exists $content->{Nonce};
    my $iv = defined($nonce) ? decode_base64($nonce) : undef;

    for my $param ( sort keys %match_args) {
        my $got = $content->{$param};
        my $expect = $match_args{$param};
        if($expect =~ /^\0(.*)$/) {
            # use \0 as a flag that the received data needs to be decrypted
            $expect = $1;
            $got = $main::kph->{cbc}->decrypt( decode_base64($got), $main::kph->{key}, $iv) if defined $nonce;
        }
        is $got, $expect, "$testname_prefix: UA received correct $param";
    }

    #note "$testname_prefix: ", explain { $get_url => $get_options };
}




use WWW::KeePassHttp;

# NOTE: this key is used for testing (it was the key used in the example at https://github.com/pfn/keepasshttp/)
#   it is NOT the value you should use for your key in the real application
#   In a real application, you must generate a 256-bit cryptographically secure key,
#   using something like Math::Random::Secure or Crypt::Random,
#   or use `openssl enc -aes-256-cbc -k secret -P -md sha256 -pbkdf2 -iter 100000`
#       and convert the 64 hex nibbles to a key using pack 'H*', $sixtyfournibbles
my $key = decode_base64(my $key64='CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=');

# start by intializing the kph object with your key and associating
our $kph = WWW::KeePassHttp->new(Key => $key);

# get_logins with altnerative SubmitUrl
$kph->get_logins('WWW-KeePassHttp', SubmitUrl => 'alternative');
test_next_get_params($mock->next_call(), 'get-logins alternative SubmitUrl', SubmitUrl => "\0alternative");
$mock->clear();

# get_logins_count with altnerative SubmitUrl
$kph->get_logins_count('WWW-KeePassHttp', SubmitUrl => 'counter');
test_next_get_params($mock->next_call(), 'get-logins-count alternative SubmitUrl', SubmitUrl => "\0counter");
$mock->clear();

# get_logins with no return values
my $ret = $kph->get_logins('WWW-KeePassHttp', SubmitUrl => 'alternative');
is_deeply $ret, [], 'get-logins: retval with no count';
$mock->clear();

# set_login with Entry object
use WWW::KeePassHttp::Entry;
my $entry = WWW::KeePassHttp::Entry->new(
        Login => 'coverage.t.username',
        Url => 'coverage.t.url',
        Password => 'coverage.t.password',
);
ok $kph->set_login($entry), 'set-login: use entry object';

done_testing();


__END__
