#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Trickster;
use Trickster::Template;
use Time::Piece;

my $app = Trickster->new(debug => 1);

# Initialize template engine
my $template = Trickster::Template->new(
    path => ["$FindBin::Bin/../templates"],
    cache => 0, # Disable cache for development
    layout => 'layouts/main.tx',
    default_vars => {
        app_name => 'Trickster Demo',
        tagline => 'Modern Perl Web Framework with Templates',
        version => '0.01',
    },
    function => {
        format_date => sub {
            my $timestamp = shift;
            return localtime($timestamp)->strftime('%Y-%m-%d %H:%M:%S');
        },
        upper => sub {
            return uc(shift);
        },
    },
);

# Sample data
my %users = (
    1 => { 
        id => 1, 
        name => 'Alice Johnson', 
        email => 'alice@example.com', 
        role => 'admin',
        bio => 'Full-stack developer and Perl enthusiast.',
    },
    2 => { 
        id => 2, 
        name => 'Bob Smith', 
        email => 'bob@example.com', 
        role => 'user',
        bio => 'Backend developer specializing in APIs.',
    },
    3 => { 
        id => 3, 
        name => 'Carol White', 
        email => 'carol@example.com', 
        role => 'user',
        bio => 'DevOps engineer and automation expert.',
    },
);

# Home page
$app->get('/', sub {
    my ($req, $res) = @_;
    
    my $html = $template->render('home.tx', {
        title => 'Home - Trickster Demo',
        features => [
            'Fast routing with constraints',
            'Template engine with Text::Xslate',
            'Exception handling',
            'Data validation',
            'Secure cookies',
            'Structured logging',
            'PSGI/Plack compatible',
        ],
        request_time => $template->{xslate}->function->{format_date}->(time),
        template_count => scalar(keys %users),
    });
    
    return $res->html($html);
});

# List all users
$app->get('/users', sub {
    my ($req, $res) = @_;
    
    my $html = $template->render('user/list.tx', {
        title => 'Users - Trickster Demo',
        users => [values %users],
    });
    
    return $res->html($html);
});

# View user profile
$app->get('/user/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->param('id');
    
    my $user = $users{$id};
    
    my $html = $template->render('user/profile.tx', {
        title => $user ? "$user->{name} - Profile" : 'User Not Found',
        user => $user,
    });
    
    return $res->html($html);
}, constraints => { id => qr/^\d+$/ });

# Render template from string
$app->get('/hello/:name', sub {
    my ($req, $res) = @_;
    my $name = $req->param('name');
    
    my $html = $template->render_string(
        '<div class="card"><h2>Hello [% name %]!</h2><p>Welcome to Trickster.</p></div>',
        { 
            title => "Hello $name",
            name => $name,
        }
    );
    
    return $res->html($html);
});

# Example without layout
$app->get('/api/template', sub {
    my ($req, $res) = @_;
    
    my $html = $template->render('user/profile.tx', {
        user => $users{1},
        no_layout => 1, # Skip layout
    });
    
    return $res->html($html);
});

# About page (inline template)
$app->get('/about', sub {
    my ($req, $res) = @_;
    
    my $html = $template->render_string(q{
        <div class="card">
            <h2>About Trickster</h2>
            <p>Trickster is a modern, battle-tested micro-framework for building web applications in Perl.</p>
            
            <h3 style="margin-top: 20px;">Core Features</h3>
            <ul style="margin-left: 20px; margin-top: 10px;">
                <li>Minimal core with light dependencies</li>
                <li>PSGI/Plack native</li>
                <li>Modern Perl 5.14+ features</li>
                <li>Production-ready error handling</li>
                <li>Fast template rendering with Text::Xslate</li>
            </ul>
            
            <h3 style="margin-top: 20px;">Template Engine</h3>
            <p>Powered by <strong>Text::Xslate</strong>, one of the fastest template engines for Perl.</p>
            <p>Current time: [% format_date(now) %]</p>
        </div>
    }, {
        title => 'About - Trickster Demo',
        now => time,
    });
    
    return $res->html($html);
});

$app->to_app;
