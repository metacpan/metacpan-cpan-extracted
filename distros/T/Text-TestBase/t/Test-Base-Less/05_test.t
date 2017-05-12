use strict;
use warnings;
use utf8;
use Test::Base::Less;

filters {
    code => [qw/eval/],
};

is(0+blocks, 2) or die "BAIL OUT";
isa_ok([blocks]->[0], 'Text::TestBase::Block');

is_deeply([blocks]->[0]->code, +{ a => 'b' });
is(scalar([blocks]->[1]->code), 'X');
is_deeply([[blocks]->[1]->code], [qw/X Y/]);

done_testing;
__DATA__

===
--- code: +{ a => 'b' }

===
--- code
(
    'X' => 'Y'
)
