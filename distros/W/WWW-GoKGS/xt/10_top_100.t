use strict;
use warnings;
use xt::Util qw/build_gokgs/;
use Test::Base;
use Test::Deep;
use WWW::GoKGS;

spec_file 'xt/10_top_100.spec';

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1 * blocks;

my $gokgs = build_gokgs();

my $expected = {
   players => array_each({
       position => re('^(?:[1-9][0-9]?|100)$'),
       name => re('^[a-zA-Z][a-zA-Z0-9]{0,9}$'),
       rank => re('^[1-9]d$'),
       uri => all( isa('URI'), methods(path => '/graphPage.jsp') ),
   }),
};

run {
    my $block = shift;
    my $got = $gokgs->top_100->scrape( $block->input );
    is_deeply $got, $block->expected if defined $block->expected;
    cmp_deeply $got, $expected unless defined $block->expected;
};

sub html {
    ( @_, $gokgs->top_100->build_uri );
}
