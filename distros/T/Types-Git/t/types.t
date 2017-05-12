#!/usr/bin/env perl
use strictures 1;

use Test::More;

BEGIN { use_ok('Types::Git', '-types') }

my $git_ref_rule_bad_refs = {
    1 => [qw(
        refs.lock/heads/master
        refs/heads.lock/master
        refs/heads/master.lock
        .refs/heads/master
        refs/.heads/master
        refs/heads/.master
    )],
    2 => [ 'master' ],
    3 => [ 'refs/heads/ma..ster' ],
    4 => [
        "refs/heads/ma\040ster",
        "refs/heads/ma\000ster",
        "refs/heads/ma\177ster",
        "refs/heads/ma ster",
        qw(
            refs/heads/ma~ster
            refs/heads/ma^ster
            refs/heads/ma:ster
        ),
    ],
    5 => [qw(
        refs/heads/ma?ster
        refs/heads/ma*ster
        refs/heads/ma[ster
    )],
    6 => [qw(
        /refs/heads/master
        refs/heads/master/
        refs/heads//master
    )],
    7 => [ 'refs/heads/master.' ],
    8 => [ 'refs/heads/ma@{ster' ],
    9 => [ '@' ],
    10 => [ 'refs/heads/ma\ster' ],
};

subtest 'GitRef' => sub{
    my @bad_refs = (
        map { @{ $git_ref_rule_bad_refs->{$_} } }
        sort {$a <=> $b} keys( %$git_ref_rule_bad_refs )
    );

    my @good_refs = qw(
        refs/heads/master
    );

    ok( (! GitRef->check($_)), "$_ is not valid" ) for @bad_refs;

    ok( GitRef->check($_), "$_ is valid" ) for @good_refs;
};

subtest 'GitLooseRef' => sub{
    my @bad_refs = (
        map { @{ $git_ref_rule_bad_refs->{$_} } }
        grep { $_ != 2 }
        sort {$a <=> $b} keys( %$git_ref_rule_bad_refs )
    );

    my @good_refs = qw(
        master
        refs/heads/master
    );

    ok( (! GitLooseRef->check($_)), "$_ is not valid" ) for @bad_refs;

    ok( GitLooseRef->check($_), "$_ is valid" ) for @good_refs;
};

subtest 'GitBranchRef' => sub{
    my @bad_refs = qw(
        refs/tags/master
        master
    );

    my @good_refs = qw(
        refs/heads/master
    );

    ok( (! GitBranchRef->check($_)), "$_ is not valid" ) for @bad_refs;

    ok( GitBranchRef->check($_), "$_ is valid" ) for @good_refs;
};

subtest 'GitTagRef' => sub{
    my @bad_refs = qw(
        refs/heads/master
        master
    );

    my @good_refs = qw(
        refs/tags/master
    );

    ok( (! GitTagRef->check($_)), "$_ is not valid" ) for @bad_refs;

    ok( GitTagRef->check($_), "$_ is valid" ) for @good_refs;
};

subtest 'GitSHA' => sub{
    my @bad_shas = qw(
        foo
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    );

    my @good_shas = qw(
        a
        abcdef0123456789
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    );

    ok( (! GitSHA->check($_)), "$_ is not valid" ) for @bad_shas;

    ok( GitSHA->check($_), "$_ is valid" ) for @good_shas;
};

done_testing;
