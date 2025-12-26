#!/usr/bin/env perl

=head1 NAME

verify_api.pl - Simple script to verify WWW::Tumblr API functionality

=head1 SYNOPSIS

    # Set environment variables first:
    export TUMBLR_CONSUMER_KEY='your_consumer_key'
    export TUMBLR_SECRET_KEY='your_secret_key'
    export TUMBLR_TOKEN='your_token'
    export TUMBLR_TOKEN_SECRET='your_token_secret'
    export TUMBLR_BLOG='yourblog.tumblr.com'
    
    # Then run:
    perl examples/verify_api.pl

=head1 DESCRIPTION

This script tests various Tumblr API endpoints to verify your credentials
and that the WWW::Tumblr module is working correctly.

Get your API credentials at: https://www.tumblr.com/oauth/apps

=cut

use strict;
use warnings;
use 5.010;

use lib 'lib';
use WWW::Tumblr;
use Data::Dumper;

# Color codes for output
my $GREEN  = "\033[32m";
my $RED    = "\033[31m";
my $YELLOW = "\033[33m";
my $RESET  = "\033[0m";

sub ok    { say "${GREEN}✓${RESET} $_[0]" }
sub fail  { say "${RED}✗${RESET} $_[0]" }
sub warn_ { say "${YELLOW}⚠${RESET} $_[0]" }
sub info  { say "  $_[0]" }

# Check for required environment variables
my @required = qw(TUMBLR_CONSUMER_KEY TUMBLR_SECRET_KEY TUMBLR_TOKEN TUMBLR_TOKEN_SECRET);
my @missing = grep { !$ENV{$_} } @required;

if (@missing) {
    say "\n${RED}Missing required environment variables:${RESET}";
    say "  - $_" for @missing;
    say "\nPlease set them before running this script:";
    say "  export TUMBLR_CONSUMER_KEY='your_consumer_key'";
    say "  export TUMBLR_SECRET_KEY='your_secret_key'";
    say "  export TUMBLR_TOKEN='your_token'";
    say "  export TUMBLR_TOKEN_SECRET='your_token_secret'";
    say "  export TUMBLR_BLOG='yourblog.tumblr.com'  # optional\n";
    say "Get credentials at: https://www.tumblr.com/oauth/apps\n";
    exit 1;
}

my $blog_name = $ENV{TUMBLR_BLOG} || 'staff.tumblr.com';

say "\n" . "=" x 60;
say "WWW::Tumblr API Verification Script";
say "=" x 60;

# Initialize the client
say "\n>> Initializing WWW::Tumblr client...";

my $tumblr = WWW::Tumblr->new(
    consumer_key  => $ENV{TUMBLR_CONSUMER_KEY},
    secret_key    => $ENV{TUMBLR_SECRET_KEY},
    token         => $ENV{TUMBLR_TOKEN},
    token_secret  => $ENV{TUMBLR_TOKEN_SECRET},
);

ok "Client initialized";

# Test 1: Tagged endpoint (API key auth only)
say "\n>> Test 1: Tagged endpoint (api_key auth)";
my $tagged = $tumblr->tagged(tag => 'perl');
if ($tagged && ref $tagged eq 'ARRAY') {
    ok "Tagged endpoint works";
    info "Found " . scalar(@$tagged) . " posts tagged 'perl'";
} else {
    fail "Tagged endpoint failed";
    if ($tumblr->error) {
        info "Error: " . join(', ', @{$tumblr->error->reasons || ['Unknown']});
    }
}

# Test 2: Blog info (API key auth)
say "\n>> Test 2: Blog info for '$blog_name' (api_key auth)";
my $blog = $tumblr->blog($blog_name);
my $info = $blog->info;
if ($info && ref $info eq 'HASH' && $info->{blog}) {
    ok "Blog info works";
    info "Blog title: " . ($info->{blog}{title} || 'N/A');
    info "Posts: " . ($info->{blog}{posts} || 0);
    info "Updated: " . ($info->{blog}{updated} || 'N/A');
} else {
    fail "Blog info failed";
    if ($blog->error) {
        info "Error: " . join(', ', @{$blog->error->reasons || ['Unknown']});
    }
}

# Test 3: Blog avatar (no auth / redirect)
say "\n>> Test 3: Blog avatar (no auth)";
my $avatar = $blog->avatar;
if ($avatar && $avatar->{avatar_url}) {
    ok "Avatar endpoint works";
    info "Avatar URL: " . substr($avatar->{avatar_url}, 0, 60) . "...";
} else {
    fail "Avatar endpoint failed";
    if ($blog->error) {
        info "Error: " . join(', ', @{$blog->error->reasons || ['Unknown']});
    }
}

# Test 4: Blog posts (API key auth)
say "\n>> Test 4: Blog posts (api_key auth)";
my $posts = $blog->posts(limit => 3);
if ($posts && ref $posts eq 'HASH') {
    ok "Posts endpoint works";
    info "Total posts: " . ($posts->{total_posts} || 0);
    if ($posts->{posts} && @{$posts->{posts}}) {
        info "Sample post types: " . join(', ', map { $_->{type} } @{$posts->{posts}});
    }
} else {
    fail "Posts endpoint failed";
    if ($blog->error) {
        info "Error: " . join(', ', @{$blog->error->reasons || ['Unknown']});
    }
}

# Test 5: User info (OAuth required)
say "\n>> Test 5: User info (OAuth auth)";
my $user = $tumblr->user;
my $user_info = $user->info;
if ($user_info && ref $user_info eq 'HASH' && $user_info->{user}) {
    ok "User info works - OAuth is valid!";
    info "Username: " . ($user_info->{user}{name} || 'N/A');
    info "Following: " . ($user_info->{user}{following} || 0) . " blogs";
    info "Likes: " . ($user_info->{user}{likes} || 0);
    info "Blogs: " . scalar(@{$user_info->{user}{blogs} || []});
} else {
    fail "User info failed - OAuth may be invalid or expired";
    if ($user->error) {
        info "Error code: " . ($user->error->code || 'N/A');
        info "Error: " . join(', ', @{$user->error->reasons || ['Unknown']});
    }
}

# Test 6: User dashboard (OAuth required)
say "\n>> Test 6: User dashboard (OAuth auth)";
my $dashboard = $user->dashboard(limit => 1);
if ($dashboard && ref $dashboard eq 'HASH') {
    ok "Dashboard endpoint works";
    info "Posts in response: " . scalar(@{$dashboard->{posts} || []});
} else {
    fail "Dashboard failed";
    if ($user->error) {
        info "Error: " . join(', ', @{$user->error->reasons || ['Unknown']});
    }
}

# Test 7: User's own blog (if TUMBLR_BLOG is set and owned)
if ($ENV{TUMBLR_BLOG}) {
    say "\n>> Test 7: Your blog followers (OAuth auth)";
    my $own_blog = $tumblr->blog($ENV{TUMBLR_BLOG});
    my $followers = $own_blog->followers(limit => 3);
    if ($followers && ref $followers eq 'HASH') {
        ok "Followers endpoint works";
        info "Total followers: " . ($followers->{total_users} || 0);
    } else {
        warn_ "Followers endpoint failed (you may not own this blog)";
        if ($own_blog->error) {
            info "Error: " . join(', ', @{$own_blog->error->reasons || ['Unknown']});
        }
    }
}

# Summary
say "\n" . "=" x 60;
say "Verification Complete";
say "=" x 60;
say "\nIf all OAuth tests passed, your credentials are valid and";
say "the WWW::Tumblr module is working correctly with Tumblr API v2.\n";

__END__

