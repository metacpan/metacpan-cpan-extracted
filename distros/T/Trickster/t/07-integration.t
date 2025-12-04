use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP;

use_ok('Trickster');
use_ok('Trickster::Exception');
use_ok('Trickster::Validator');
use_ok('Trickster::Logger');

# Create logger with fatal level to suppress error logs in tests
my $logger = Trickster::Logger->new(level => 'fatal');
my $app = Trickster->new(debug => 1, logger => $logger);

# Test exception handling
$app->get('/error', sub {
    Trickster::Exception::NotFound->throw(message => 'Resource not found');
});

$app->get('/bad-request', sub {
    Trickster::Exception::BadRequest->throw(
        message => 'Invalid data',
        details => { field => 'email' }
    );
});

# Test validation
$app->post('/users', sub {
    my ($req, $res) = @_;
    
    my $data = $req->json;
    
    my $validator = Trickster::Validator->new({
        name => ['required', ['min', 3]],
        email => ['required', 'email'],
    });
    
    unless ($validator->validate($data)) {
        return $res->json({ errors => $validator->errors }, 400);
    }
    
    return $res->json({ id => 1, %$data }, 201);
});

# Test named routes
$app->get('/profile/:username', sub {
    my ($req, $res) = @_;
    my $username = $req->param('username');
    return $res->json({ username => $username });
}, name => 'user_profile');

my $test = test_psgi $app->to_app, sub {
    my $cb = shift;
    
    # Test exception handling
    my $res = $cb->(GET '/error', Accept => 'application/json');
    is $res->code, 404, 'Exception returns correct status';
    my $data = decode_json($res->content);
    is $data->{error}, 'Resource not found', 'Exception message in response';
    
    # Test validation
    $res = $cb->(POST '/users',
        Content_Type => 'application/json',
        Content => encode_json({ name => 'Al' })
    );
    is $res->code, 400, 'Validation error returns 400';
    $data = decode_json($res->content);
    ok exists $data->{errors}{name}, 'Validation error for name';
    ok exists $data->{errors}{email}, 'Validation error for email';
    
    $res = $cb->(POST '/users',
        Content_Type => 'application/json',
        Content => encode_json({ name => 'Alice', email => 'alice@example.com' })
    );
    is $res->code, 201, 'Valid data returns 201';
    $data = decode_json($res->content);
    is $data->{name}, 'Alice', 'User created successfully';
    
    # Test named routes
    $res = $cb->(GET '/profile/alice');
    is $res->code, 200, 'Named route works';
    $data = decode_json($res->content);
    is $data->{username}, 'alice', 'Route param extracted';
};

# Test URL generation
my $url = $app->url_for('user_profile', username => 'bob');
is $url, '/profile/bob', 'URL generation works';

done_testing;
