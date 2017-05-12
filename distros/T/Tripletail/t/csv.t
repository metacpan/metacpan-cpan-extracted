#!perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Tripletail '/dev/null';

eval {
    require Text::CSV_XS;
};
if ($@) {
    plan skip_all => 'Text::CSV_XS is required for these tests';
}
else {
    plan tests => 15;
}

my $csv;
lives_ok {
    $csv = $TL->getCsv();
} 'getCsv';

my $p;
ok($p = $csv->parseCsv(\*DATA), 'parseCsv (fh)');
is_deeply($p->next, ['a,b', 'c"d', "e\nf"], 'next [0]');
is_deeply($p->next, [qw(1 2 3 4 5)], 'next [1]');
is_deeply($p->next, ['a,b', 'cd\\'], 'next [2]');
is($p->next, undef, 'next[3]');

ok($p = $csv->parseCsv('a,b,c'), 'parseCsv (scalar)');
is_deeply($p->next, [qw(a b c)], 'next [0]');
is($p->next, undef, 'next[1]');

ok($p = $csv->parseCsv('a",b,c'), 'parseCsv (error)');
dies_ok {
    $p->next;
} 'next [error]';

dies_ok {$csv->makeCsv(\123)} 'makeCsv die';
is($csv->makeCsv([]), "", 'makeCsv [0]');
is($csv->makeCsv([1, 2, 3]), "1,2,3", 'makeCsv [1]');
is($csv->makeCsv(
    ['a,b', 'c"d', "e\nf"]),
   qq{"a,b","c""d","e\nf"}, 'makeCsv [2]');

__END__
"a,b","c""d","e
f"
1,2,3,4,5
"a,b","cd\"
