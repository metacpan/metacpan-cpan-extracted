#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Trickster;

my $app = Trickster->new;

# In-memory data store
my %users = (
    1 => { id => 1, name => 'Alice', email => 'alice@example.com' },
    2 => { id => 2, name => 'Bob', email => 'bob@example.com' },
);
my $next_id = 3;

# List users
$app->get('/api/users', sub {
    my ($req, $res) = @_;
    return $res->json([values %users]);
});

# Get user
$app->get('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    if (exists $users{$id}) {
        return $res->json($users{$id});
    } else {
        return $res->json({ error => 'User not found' }, 404);
    }
});

# Create user
$app->post('/api/users', sub {
    my ($req, $res) = @_;
    my $data = $req->json;
    
    my $user = {
        id => $next_id++,
        name => $data->{name},
        email => $data->{email},
    };
    
    $users{$user->{id}} = $user;
    
    return $res->json($user, 201);
});

# Update user
$app->put('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    unless (exists $users{$id}) {
        return $res->json({ error => 'User not found' }, 404);
    }
    
    my $data = $req->json;
    $users{$id}{name} = $data->{name} if $data->{name};
    $users{$id}{email} = $data->{email} if $data->{email};
    
    return $res->json($users{$id});
});

# Delete user
$app->delete('/api/users/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    unless (exists $users{$id}) {
        return $res->json({ error => 'User not found' }, 404);
    }
    
    delete $users{$id};
    
    return $res->json({ success => 1 });
});

# Error handler
$app->error_handler(sub {
    my ($error, $req, $res) = @_;
    return $res->json({ error => "Internal Server Error: $error" }, 500)->finalize;
});

$app->to_app;
