use Test::More;
use utf8;

BEGIN {
    use_ok 'WebService::Yamli';
}

my $tr = WebService::Yamli::tr('7aga');
is $tr, 'حاجة';

my @tr = WebService::Yamli::tr('7aga');
is $tr[0], 'حاجة';
isnt scalar @tr, 1;

my $words = WebService::Yamli::tr('7aga 7aga');
is $words, 'حاجة حاجة';

done_testing;
