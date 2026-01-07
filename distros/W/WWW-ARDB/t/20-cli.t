#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Capture::Tiny qw( capture );

# Test module loading
use_ok('WWW::ARDB::CLI');
use_ok('WWW::ARDB::CLI::Cmd::Items');
use_ok('WWW::ARDB::CLI::Cmd::Item');
use_ok('WWW::ARDB::CLI::Cmd::Quests');
use_ok('WWW::ARDB::CLI::Cmd::Quest');
use_ok('WWW::ARDB::CLI::Cmd::Enemies');
use_ok('WWW::ARDB::CLI::Cmd::Enemy');

# Test CLI instantiation (reset @ARGV to avoid option parsing issues)
{
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new;
    isa_ok($cli, 'WWW::ARDB::CLI');
    isa_ok($cli->api, 'WWW::ARDB');
}

# Test with options
{
    local @ARGV = ('--debug', '--no-cache', '--json');
    my $cli = WWW::ARDB::CLI->new;
    is($cli->debug, 1, 'debug option');
    is($cli->no_cache, 1, 'no_cache option');
    is($cli->json, 1, 'json option');
}

# Test default execute shows help
{
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new;
    my ($stdout, $stderr) = capture {
        $cli->execute([], [$cli]);
    };
    like($stdout, qr/ardb - ARC Raiders Database CLI/, 'help header');
    like($stdout, qr/items/, 'help shows items command');
    like($stdout, qr/quests/, 'help shows quests command');
    like($stdout, qr/enemies/, 'help shows enemies command');
}

done_testing;
