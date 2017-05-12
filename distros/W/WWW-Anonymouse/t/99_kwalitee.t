use strict;
use warnings;
use Test::More;

if ( ($ENV{CPAN_AUTHOR_TESTS}||'') !~ /\bWWW::Anonymouse\b/ ) {
    plan skip_all => 'author tests';
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };
if ($@) {
    plan skip_all => 'Test::Kwalitee not installed; skipping';
}
