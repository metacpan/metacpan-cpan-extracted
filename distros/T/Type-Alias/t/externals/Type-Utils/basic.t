use strict;
use warnings;
use Test::More;
use Test::Requires qw( Type::Utils );

use Type::Utils qw( compile_match_on_type );
use Type::Alias -alias => [qw/ Published Draft /];

type Published => 'published';
type Draft     => 'draft';

subtest 'pattern matching' => sub {

    my $hi = compile_match_on_type(
        Published, sub { 'published!' },
        Draft, sub { 'draft...' }
    );

    is $hi->('published'), 'published!';
    is $hi->('draft'), 'draft...';

    eval { $hi->('foo') };
    ok $@;
};

done_testing;
