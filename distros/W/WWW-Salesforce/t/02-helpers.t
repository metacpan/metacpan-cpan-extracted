use strict;
use warnings;

use Test::More;
use WWW::Salesforce ();

sub trap_function {
    my ($function, @args) = @_;
    my $res;
    my $warn;
    my $err = do { # catch
        local $@;
        local $SIG{__WARN__} = sub {$warn = join '', @_};
        eval { # try
            $res = $function->(@args);
            1;
        };
        $@;
    };
    return ($res, $warn, $err);
}

# test _coerce_version
{
    my $VERSION = $WWW::Salesforce::SF_APIVERSION;
    ok(defined $VERSION, 'SF_APIVERSION is defined');
    like($VERSION, qr/^\d+\.\d+$/, 'SF_APIVERSION looks like a version number');

    # All bad values SHOULD default to the version defined in the module
    is(WWW::Salesforce::_coerce_version(''), $VERSION, 'coerces empty string to current version');
    is(WWW::Salesforce::_coerce_version(undef), $VERSION, 'coerces undef to current version');
    is(WWW::Salesforce::_coerce_version($VERSION), $VERSION, 'coerces current version to itself');

    # Stringy numbers should be coerced to themselves
    is(WWW::Salesforce::_coerce_version('1.0'), '1.0', 'coerces specific version to itself');
    is(WWW::Salesforce::_coerce_version('2.5'), '2.5', 'coerces another specific version to itself');

    # Numeric values should be coerced to string versions with .0 appended if necessary
    is(WWW::Salesforce::_coerce_version(3.0), '3.0', 'coerces yet another specific version to itself');
    is(WWW::Salesforce::_coerce_version(4), '4.0', 'coerces integer version to string');
}

# test _params
{
    my $VERSION = $WWW::Salesforce::SF_APIVERSION;
    my $URL = $WWW::Salesforce::SF_PROXY;
    my $expected = {
        sf_serverurl => $URL,
        sf_version => $VERSION,
        sf_user => undef,
        sf_pass => undef,
        sf_type => 'soap',
        sf_oauth2 => {
            client_id => undef,
            client_secret => undef,
        },
        sf_sid => undef,
        sf_uid => undef,
        sf_metadataServerUrl => undef,
    };

    # test some failure points
    {
        my ($res, $warn, $err) = trap_function(\&WWW::Salesforce::_params, []);
        like($err, qr/Argument could not be dereferenced as a hash/, '_params: passing an array reference triggers croak');
        ($res, $warn, $err) = trap_function(\&WWW::Salesforce::_params, undef);
        like($err, qr/Arguments must be a hash or a hash reference/, '_params: passing undef triggers croak');
        ($res, $warn, $err) = trap_function(\&WWW::Salesforce::_params, 'string');
        like($err, qr/Arguments must be a hash or a hash reference/, '_params: passing a string triggers croak');
        ($res, $warn, $err) = trap_function(\&WWW::Salesforce::_params, 11);
        like($err, qr/Arguments must be a hash or a hash reference/, '_params: passing an integer triggers croak');
        ($res, $warn, $err) = trap_function(\&WWW::Salesforce::_params, 11, 1, 12);
        like($err, qr/Arguments must be a hash or a hash reference/, '_params: passing odd number of arguments triggers croak');
    }

    # test empty input for _params returns the expected default structure
    is_deeply(WWW::Salesforce::_params(), $expected, '_params: empty input returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({}), $expected, '_params: input with current server URL returns the expected hashref');

    # test input with only the version specified
    is_deeply(WWW::Salesforce::_params({version => $VERSION}), $expected, '_params: input with current version returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('version', $VERSION), $expected, '_params: input with current version returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('version' => $VERSION), $expected, '_params: input with current version returns the expected hashref');

    # test the various types
    $expected->{sf_type} = 'soap';
    is_deeply(WWW::Salesforce::_params({type => 'soap'}), $expected, '_params: input with type soap returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type', 'soap'), $expected, '_params: input with type soap using key-value pair returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type' => 'soap'), $expected, '_params: input with type soap using fat arrow returns the expected hashref');
    $expected->{sf_type} = 'oauth2-usernamepassword';
    is_deeply(WWW::Salesforce::_params({type => 'oauth2-usernamepassword'}), $expected, '_params: input with type oauth2-usernamepassword returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type', 'oauth2-usernamepassword'), $expected, '_params: input with type oauth2-usernamepassword using key-value pair returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type' => 'oauth2-usernamepassword'), $expected, '_params: input with type oauth2-usernamepassword using fat arrow returns the expected hashref');
    $expected->{sf_type} = 'oauth2-clientcredentials';
    is_deeply(WWW::Salesforce::_params({type => 'oauth2-clientcredentials'}), $expected, '_params: input with type oauth2-clientcredentials returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type', 'oauth2-clientcredentials'), $expected, '_params: input with type oauth2-clientcredentials using key-value pair returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type' => 'oauth2-clientcredentials'), $expected, '_params: input with type oauth2-clientcredentials using fat arrow returns the expected hashref');
    $expected->{sf_type} = 'soap';
    is_deeply(WWW::Salesforce::_params({type => 'someUnknownType'}), $expected, '_params: input with type someUnknownType returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type', 'someUnknownType'), $expected, '_params: input with type someUnknownType using key-value pair returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type' => 'someUnknownType'), $expected, '_params: input with type someUnknownType using fat arrow returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({type => undef}), $expected, '_params: input with type undef returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type', undef), $expected, '_params: input with type undef using key-value pair returns the expected hashref');
    is_deeply(WWW::Salesforce::_params('type' => undef), $expected, '_params: input with type undef using fat arrow returns the expected hashref');

    # test the various spellings for the URL
    $URL = 'https://test.salesforce.com/services/Soap/u/68.0';
    $expected->{sf_serverurl} = $URL;
    is_deeply(WWW::Salesforce::_params({serverurl => $URL}), $expected, '_params: input with serverurl returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({serverUrl => $URL}), $expected, '_params: input with serverUrl returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({instanceurl => $URL}), $expected, '_params: input with instanceurl returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({instanceUrl => $URL}), $expected, '_params: input with instanceUrl returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({url => $URL}), $expected, '_params: input with url returns the expected hashref');

    # test the username spellings
    my $user = 'testuser';
    $URL = $WWW::Salesforce::SF_PROXY;
    $expected->{sf_serverurl} = $URL;
    $expected->{sf_user} = $user;
    is_deeply(WWW::Salesforce::_params({username => $user}), $expected, '_params: input with username returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({user => $user}), $expected, '_params: input with user returns the expected hashref');
    $expected->{sf_type} = 'oauth2-clientcredentials';
    is_deeply(WWW::Salesforce::_params({oauth2 => {user => $user}}), $expected, '_params: input with oauth2 user returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({oauth2 => {username => $user}}), $expected, '_params: input with oauth2 username returns the expected hashref');

    # test the password spellings
    my $pass = 'testpass';
    $expected->{sf_pass} = $pass;
    $expected->{sf_type} = 'soap';
    $expected->{sf_user} = undef;
    is_deeply(WWW::Salesforce::_params({password => $pass}), $expected, '_params: input with password returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({pass => $pass}), $expected, '_params: input with pass returns the expected hashref');
    $expected->{sf_type} = 'oauth2-clientcredentials';
    is_deeply(WWW::Salesforce::_params({oauth2 => {pass => $pass}}), $expected, '_params: input with oauth2 pass returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({oauth2 => {password => $pass}}), $expected, '_params: input with oauth2 password returns the expected hashref');

    # test the client_id and client_secret spellings
    my $client_id = 'testclientid';
    $expected->{sf_pass} = undef;
    $expected->{sf_type} = 'soap';
    $expected->{sf_oauth2}{client_id} = $client_id;
    is_deeply(WWW::Salesforce::_params({client_id => $client_id}), $expected, '_params: input with client_id returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({clientId => $client_id}), $expected, '_params: input with clientId returns the expected hashref');
    $expected->{sf_type} = 'oauth2-clientcredentials';
    is_deeply(WWW::Salesforce::_params({oauth2 => {client_id => $client_id}}), $expected, '_params: input with oauth2 client_id returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({oauth2 => {clientId => $client_id}}), $expected, '_params: input with oauth2 clientId returns the expected hashref');
    my $client_secret = 'testclientsecret';
    $expected->{sf_pass} = undef;
    $expected->{sf_type} = 'soap';
    $expected->{sf_oauth2}{client_id} = undef;
    $expected->{sf_oauth2}{client_secret} = $client_secret;
    is_deeply(WWW::Salesforce::_params({client_secret => $client_secret}), $expected, '_params: input with client_id and client_secret returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({clientSecret => $client_secret}), $expected, '_params: input with clientId and clientSecret returns the expected hashref');
    $expected->{sf_type} = 'oauth2-clientcredentials';
    is_deeply(WWW::Salesforce::_params({oauth2 => {client_secret => $client_secret}}), $expected, '_params: input with oauth2 client_id and client_secret returns the expected hashref');
    is_deeply(WWW::Salesforce::_params({oauth2 => {clientSecret => $client_secret}}), $expected, '_params: input with oauth2 clientId and clientSecret returns the expected hashref');
}

# test version numbers numerically
{
    ok(WWW::Salesforce::_coerce_version('67') < 68.1, 'We can use our versions for numerical comparisons');
}

done_testing();
