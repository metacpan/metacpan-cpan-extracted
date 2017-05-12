use strict;
use warnings;
use Test::More;

eval q{use Test::Version 1.003001 qw( version_all_ok ), {
        is_strict   => 1,
        has_version => 1,
    };
};
plan skip_all => "Test::Version 1.003001 required for testing version numbers" if $@;
version_all_ok();
done_testing;

