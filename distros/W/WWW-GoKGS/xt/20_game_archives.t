use strict;
use warnings;
use xt::Util qw/build_gokgs :cmp_deeply/;
use Encode qw/decode_utf8/;
use Test::Base;
use WWW::GoKGS;

spec_file 'xt/20_game_archives.spec';

plan skip_all => 'AUTHOR_TESTING is required' unless $ENV{AUTHOR_TESTING};
plan tests => 1 * blocks;

my $gokgs = build_gokgs();

my $expected = do {
    my %user = (
        name => user_name(),
        rank => user_rank(),
        uri => [ uri(), sub { $_[0]->path eq '/gameArchives.jsp' } ],
    );

    my $type = do {
        my %is_type = map {( $_ => 1 )} (
            'Ranked',
            'Teaching',
            'Simul',
            'Rengo',
            'Rengo Review',
            'Review',
            'Demonstration',
            'Tournament',
            'Free',
        );

        sub { $is_type{$_[0]} };
    };

    hash(
        time_zone => sub { $_[0] eq 'GMT' },
        games => array_of_hashes(
            sgf_uri => [ uri(), sub { $_[0]->path =~ /\.sgf$/ } ],
            owner => hash( %user ),
            white => array_of_hashes( %user ),
            black => array_of_hashes( %user ),
            board_size => [ integer(), sub { $_[0] >= 2 && $_[0] <= 38 } ],
            handicap => [ integer(), sub { $_[0] >= 2 } ],
            start_time => datetime( '%Y-%m-%dT%H:%M' ),
            type => $type,
            result => game_result(),
        ),
        tgz_uri => [ uri(), sub { $_[0]->path =~ /\.tar\.gz$/ } ],
        zip_uri => [ uri(), sub { $_[0]->path =~ /\.zip$/ } ],
        calendar => array_of_hashes(
            year => [ integer(), sub { $_[0] >= 1999 } ],
            month => [ integer(), sub { $_[0] >= 1 && $_[0] <= 12 } ],
            uri => [ uri(), sub { $_[0]->path eq '/gameArchives.jsp' } ],
        ),
    );
};

run {
    my $block = shift;
    my $got = $gokgs->game_archives->scrape( $block->input );
    is_deeply $got, $block->expected if defined $block->expected;
    cmp_deeply $got, $expected unless defined $block->expected;
};

sub build_uri {
    $gokgs->game_archives->build_uri( @_ );
}

sub html {
    ( @_, $gokgs->game_archives->build_uri );
}
