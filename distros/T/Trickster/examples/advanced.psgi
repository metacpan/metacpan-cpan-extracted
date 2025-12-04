#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Trickster;
use Trickster::Exception;
use Trickster::Validator;
use Trickster::Logger;
use Trickster::Cookie;
use Plack::Builder;

# Initialize app with logger
my $logger = Trickster::Logger->new(level => 'info');
my $app = Trickster->new(
    logger => $logger,
    debug => 1,
);

# Cookie handler
my $cookie = Trickster::Cookie->new(
    secret => 'your-secret-key-change-in-production',
);

# In-memory data store
my %users = (
    1 => { id => 1, name => 'Alice', email => 'alice@example.com', role => 'admin' },
    2 => { id => 2, name => 'Bob', email => 'bob@example.com', role => 'user' },
);
my $next_id = 3;

# Home route
$app->get('/', sub {
    my ($req, $res) = @_;
    return $res->html(<<'HTML');
<!DOCTYPE html>
<html>
<head><title>Trickster Advanced Example</title></head>
<body>
    <h1>Trickster Advanced Example</h1>
    <h2>API Endpoints:</h2>
    <ul>
        <li>GET /api/users - List all users</li>
        <li>GET /api/users/:id - Get user by ID</li>
        <li>POST /api/users - Create user (requires name, email)</li>
        <li>PUT /api/users/:id - Update user</li>
        <li>DELETE /api/users/:id - Delete user</li>
        <li>GET /api/profile/:username - Get profile (named route)</li>
    </ul>
    <h2>Features Demonstrated:</h2>
    <ul>
        <li>Robust routing with constraints</li>
        <li>Exception handling</li>
        <li>Data validation</li>
        <li>Structured logging</li>
        <li>Secure cookies</li>
        <li>Named routes</li>
    </ul>
</body>
</html>
HTML
});

# List users
$app->get('/api/users', sub {
    my ($req, $res) = @_;
    $logger->info('Listing all users');
    return $res->json([values %users]);
});

# Get user by ID (with numeric constraint)
$app->get('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    $logger->info("Fetching user", id => $id);
    
    unless (exists $users{$id}) {
        Trickster::Exception::NotFound->throw(
            message => "User with ID $id not found"
        );
    }
    
    return $res->json($users{$id});
}, constraints => { id => qr/^\d+$/ });

# Create user with validation
$app->post('/api/users', sub {
    my ($req, $res) = @_;
    my $data = $req->json;
    
    my $validator = Trickster::Validator->new({
        name => ['required', ['min', 2], ['max', 50]],
        email => ['required', 'email'],
        role => [['in', 'admin', 'user', 'guest']],
    });
    
    unless ($validator->validate($data)) {
        $logger->warn('Validation failed', errors => $validator->errors);
        Trickster::Exception::BadRequest->throw(
            message => 'Validation failed',
            details => $validator->errors,
        );
    }
    
    my $user = {
        id => $next_id++,
        name => $data->{name},
        email => $data->{email},
        role => $data->{role} || 'user',
    };
    
    $users{$user->{id}} = $user;
    
    $logger->info('User created', id => $user->{id}, name => $user->{name});
    
    return $res->json($user, 201);
});

# Update user
$app->put('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    my $data = $req->json;
    
    unless (exists $users{$id}) {
        Trickster::Exception::NotFound->throw(
            message => "User with ID $id not found"
        );
    }
    
    my $validator = Trickster::Validator->new({
        name => [['min', 2], ['max', 50]],
        email => ['email'],
        role => [['in', 'admin', 'user', 'guest']],
    });
    
    unless ($validator->validate($data)) {
        Trickster::Exception::BadRequest->throw(
            message => 'Validation failed',
            details => $validator->errors,
        );
    }
    
    $users{$id}{name} = $data->{name} if $data->{name};
    $users{$id}{email} = $data->{email} if $data->{email};
    $users{$id}{role} = $data->{role} if $data->{role};
    
    $logger->info('User updated', id => $id);
    
    return $res->json($users{$id});
}, constraints => { id => qr/^\d+$/ });

# Delete user
$app->delete('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    unless (exists $users{$id}) {
        Trickster::Exception::NotFound->throw(
            message => "User with ID $id not found"
        );
    }
    
    delete $users{$id};
    
    $logger->info('User deleted', id => $id);
    
    return $res->json({ success => 1, message => 'User deleted' });
}, constraints => { id => qr/^\d+$/ });

# Named route example
$app->get('/api/profile/:username', sub {
    my ($req, $res) = @_;
    my $username = $req->param('username');
    
    # Find user by name
    my ($user) = grep { lc($_->{name}) eq lc($username) } values %users;
    
    unless ($user) {
        Trickster::Exception::NotFound->throw(
            message => "Profile for $username not found"
        );
    }
    
    return $res->json($user);
}, name => 'user_profile');

# Cookie example
$app->get('/cookie/set', sub {
    my ($req, $res) = @_;
    $cookie->set($res, 'user_session', 'session-123', max_age => 3600);
    return $res->json({ message => 'Cookie set' });
});

$app->get('/cookie/get', sub {
    my ($req, $res) = @_;
    my $session = $cookie->get($req, 'user_session');
    return $res->json({ session => $session || 'none' });
});

# Custom error handler
$app->error_handler(sub {
    my ($error, $req, $res) = @_;
    
    if (ref($error) && $error->isa('Trickster::Exception')) {
        $logger->warn('Exception thrown', 
            status => $error->status,
            message => $error->message
        );
        return $res->json($error->as_hash, $error->status)->finalize;
    }
    
    $logger->error('Unhandled error', error => "$error");
    return $res->json({ error => 'Internal Server Error' }, 500)->finalize;
});

# Wrap with middleware
builder {
    enable 'Runtime';
    enable 'ContentLength';
    $app->to_app;
};
