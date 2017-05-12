#!/usr/bin/env perl
#
# Scrape an existing Yahoo 360 blog by supplying
# the username and password.
#
# $Id$

BEGIN { $| = 1 }

use strict;
use warnings;

use Getopt::Long;
use JSON::XS;
use WWW::Scraper::Yahoo360;

our $verbose;
our $debug;

sub debug {
    if ($verbose) {
        print STDERR @_, "\n";
    }
}

GetOptions(
    'username:s' => \my $username,
    'password:s' => \my $password,
    'verbose'    => \$verbose,
    'debug'      => \$debug,
);

if (! $username || ! $password) {
    die "$0 --username=<yahoo_id> --password=<yahoo_password> [--verbose] [--debug]\n";
}

# Global debug flag
$WWW::Scraper::Yahoo360::DEBUG = $debug ? 1 : 0;

my $y360 = WWW::Scraper::Yahoo360->new({
    username => $username,
    password => $password,
});

debug("Yahoo scraper initialized. Trying to login as '$username'.");

$y360->login() or die "Can't login to Yahoo!";

debug("Logged in successfully. Getting blog information.");

my $blog_info = $y360->blog_info();

debug("Got blog information. Reading blog posts...");

my $posts = $y360->get_blog_posts();
$blog_info->{items} = $posts;

debug("Reading all blog comments...");

my $comments = $y360->get_blog_comments($posts);
$blog_info->{comments} = $comments;

my $json = JSON::XS->new()->pretty;
print $json->encode($blog_info);

