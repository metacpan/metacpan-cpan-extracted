use strict;
use warnings;
use xt::Util qw/build_gokgs :cmp_deeply/;
use Test::Base;
use Test::More;
use WWW::GoKGS;

spec_file 'xt/30_tourn_list.spec';

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1 * blocks;

my $gokgs = build_gokgs();

my $expected = hash(
    tournaments => array_of_hashes(
        name => sub { defined },
        notes => sub { defined },
        uri => [ uri(), sub { $_[0]->path eq '/tournInfo.jsp' } ],
    ),
    year_index => array_of_hashes(
        year => [ integer(), sub { $_[0] >= 2001 } ],
        uri => [ uri(), sub { $_[0]->path eq '/tournList.jsp' } ],
    ),
);

run {
    my $block = shift;
    my $got = $gokgs->tourn_list->scrape( $block->input );
    is_deeply $got, $block->expected if defined $block->expected;
    cmp_deeply $got, $expected unless defined $block->expected;
};

sub build_uri {
    $gokgs->tourn_list->build_uri( @_ );
}

sub html {
    ( @_, $gokgs->tourn_list->build_uri );
}
