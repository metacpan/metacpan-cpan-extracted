use strict;
use warnings;
use Test::More;
use JSON::PP;

use_ok('Trickster');
use_ok('Trickster::Middleware::CORS');
use_ok('Trickster::Middleware::RateLimiter');
use_ok('Trickster::Session');
use_ok('Trickster::Cookie');

# Helper to create PSGI env
sub create_env {
    my %opts = @_;
    return {
        REQUEST_METHOD => $opts{method} || 'GET',
        PATH_INFO => $opts{path} || '/',
        SCRIPT_NAME => '',
        SERVER_NAME => 'localhost',
        SERVER_PORT => 5678,
        REMOTE_ADDR => $opts{remote_addr} || '127.0.0.1',
        'psgi.version' => [1, 1],
        'psgi.url_scheme' => 'http',
        'psgi.input' => undef,
        'psgi.errors' => \*STDERR,
        'psgi.multithread' => 0,
        'psgi.multiprocess' => 1,
        'psgi.run_once' => 0,
        'psgi.streaming' => 1,
        'psgi.nonblocking' => 0,
        %{$opts{headers} || {}},
    };
}

# Test CORS Middleware
{
    my $app = Trickster->new;
    
    $app->get('/api/test', sub {
        my ($req, $res) = @_;
        return $res->json({ message => 'ok' });
    });
    
    my $base_app = $app->to_app;
    my $cors = Trickster::Middleware::CORS->new(
        origins => ['https://example.com'],
        methods => ['GET', 'POST'],
    );
    my $wrapped_app = $cors->wrap($base_app);
    
    # Test with allowed origin
    my $env = create_env(
        path => '/api/test',
        headers => { HTTP_ORIGIN => 'https://example.com' },
    );
    my $res = $wrapped_app->($env);
    
    is $res->[0], 200, 'CORS: Request successful';
    
    # Check for CORS header
    my %headers = @{$res->[1]};
    is $headers{'Access-Control-Allow-Origin'}, 'https://example.com',
        'CORS: Origin header set';
    
    # Test OPTIONS preflight
    $env = create_env(
        method => 'OPTIONS',
        path => '/api/test',
        headers => { HTTP_ORIGIN => 'https://example.com' },
    );
    $res = $wrapped_app->($env);
    
    is $res->[0], 200, 'CORS: Preflight successful';
    %headers = @{$res->[1]};
    like $headers{'Access-Control-Allow-Methods'}, qr/GET/,
        'CORS: Methods header set';
}

# Test Rate Limiter Middleware
{
    my $app = Trickster->new;
    
    $app->get('/api/limited', sub {
        my ($req, $res) = @_;
        return $res->json({ message => 'ok' });
    });
    
    my $base_app = $app->to_app;
    my $limiter = Trickster::Middleware::RateLimiter->new(
        requests => 3,
        window => 60,
    );
    my $wrapped_app = $limiter->wrap($base_app);
    
    # First 3 requests should succeed
    for my $i (1..3) {
        my $env = create_env(path => '/api/limited');
        my $res = $wrapped_app->($env);
        is $res->[0], 200, "Rate limit: Request $i successful";
        
        my %headers = @{$res->[1]};
        ok exists $headers{'X-RateLimit-Limit'}, 'Rate limit: Limit header present';
        ok exists $headers{'X-RateLimit-Remaining'}, 'Rate limit: Remaining header present';
    }
    
    # 4th request should be rate limited
    my $env = create_env(path => '/api/limited');
    my $res = $wrapped_app->($env);
    is $res->[0], 429, 'Rate limit: Request blocked';
    
    my $body = join '', @{$res->[2]};
    like $body, qr/Rate limit exceeded/, 'Rate limit: Error message';
}

# Test Stateless Session
{
    my $cookie = Trickster::Cookie->new(secret => 'test-secret-key-for-testing');
    my $session = Trickster::Session->new(
        cookie => $cookie,
        name => 'trick_session',
    );
    
    my $app = Trickster->new;
    
    $app->get('/set-session', sub {
        my ($req, $res) = @_;
        
        $session->set($res, {
            user_id => 123,
            username => 'alice',
        });
        
        return $res->json({ success => 1 });
    });
    
    $app->get('/get-session', sub {
        my ($req, $res) = @_;
        
        my $data = $session->get($req);
        
        return $res->json({
            user_id => $data->{user_id} || 0,
            username => $data->{username} || '',
        });
    });
    
    $app->post('/logout', sub {
        my ($req, $res) = @_;
        
        $session->clear($res);
        
        return $res->json({ success => 1 });
    });
    
    my $psgi_app = $app->to_app;
    
    # Set session
    my $env = create_env(path => '/set-session');
    my $res = $psgi_app->($env);
    
    is $res->[0], 200, 'Session: Set successful';
    
    # Extract session cookie
    my %headers = @{$res->[1]};
    my $cookie_header = $headers{'Set-Cookie'};
    ok $cookie_header, 'Session: Cookie set';
    like $cookie_header, qr/trick_session=/, 'Session: Cookie name correct';
    like $cookie_header, qr/HttpOnly/, 'Session: HttpOnly flag set';
    
    my ($session_cookie) = $cookie_header =~ /(trick_session=[^;]+)/;
    
    # Get session with cookie
    $env = create_env(
        path => '/get-session',
        headers => { HTTP_COOKIE => $session_cookie },
    );
    $res = $psgi_app->($env);
    
    is $res->[0], 200, 'Session: Get successful';
    
    my $body = join '', @{$res->[2]};
    my $data = decode_json($body);
    is $data->{user_id}, 123, 'Session: User ID preserved';
    is $data->{username}, 'alice', 'Session: Username preserved';
    
    # Test logout
    $env = create_env(
        method => 'POST',
        path => '/logout',
        headers => { HTTP_COOKIE => $session_cookie },
    );
    $res = $psgi_app->($env);
    
    is $res->[0], 200, 'Session: Logout successful';
    %headers = @{$res->[1]};
    like $headers{'Set-Cookie'}, qr/Max-Age=0/, 'Session: Cookie cleared';
}

done_testing;
