use strict;
use warnings;
use xt::Util qw/build_gokgs/;
use Test::Base;
use Test::Deep;
use WWW::GoKGS;

spec_file 'xt/70_tz_list.spec';

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1 * blocks;

my $gokgs = build_gokgs();

run {
    my $block = shift;
    my $got = $gokgs->tz_list->scrape( $block->input );
    is_deeply $got, $block->expected;
};

sub html {
    ( @_, $gokgs->tz_list->build_uri );
}

sub build_uri {
    $gokgs->tz_list->build_uri( @_ );
}

