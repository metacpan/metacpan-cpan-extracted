#!/usr/bin/env perl

=head1 SYNOPSIS

    perl examples/crawl-host.pl www.somehost.com

=head1 DESCRIPTION

This simple script shows you a dump of the default report.  You're encouraged
to provide your own reporting callback in order to customize your report.

=cut

use strict;
use warnings;
use feature qw( say state );

use CHI;
use Data::Printer filters => { -external => ['URI'], };
use Path::Tiny qw( path );
use WWW::RoboCop;
use WWW::Mechanize::Cached;

my $cache = CHI->new(
    driver   => 'File',
    root_dir => path( '~/.www-robocop-cache' )->stringify,
);

my $host        = shift @ARGV;
my $upper_limit = 10;

die 'usage: perl examples/crawl-host.pl www.somehost.com' unless $host;

my $robocop = WWW::RoboCop->new(
    is_url_whitelisted => sub {
        my $link          = shift;
        my $referring_url = shift;

        state $limit = 0;

        return 0 if $limit > $upper_limit;
        my $uri = URI->new( $link->url_abs );

       # If the link URI does not match the host but the referring_url matches
       # the host, then this is a 1st degree outbound link.  We'll fetch the
       # page in order to log the status code etc, but we won't index any of
       # the links on it.

        if ( $uri->host eq $host || $referring_url->host eq $host ) {
            ++$limit;
            return 1;
        }
        return 0;
    },
    ua => WWW::Mechanize::Cached->new( cache => $cache ),
);

$robocop->crawl( "http://$host" );

my %report = $robocop->get_report;

p( %report );
