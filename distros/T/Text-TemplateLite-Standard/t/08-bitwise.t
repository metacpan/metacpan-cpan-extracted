#!perl -T

use Test::More tests => 5;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:bitwise/);

## & | ^ ~

my $comp = ~0;

$tpl->set(q{<<&','&()','&(127)','&(127,99)>>});
is($rnd->render->result, "$comp,$comp,127,99", '&()');

$tpl->set(q{<<|','|()','|(1,2,4)','|(8,16)>>});
is($rnd->render->result, '0,0,7,24', '|()');

$tpl->set(q{<<^','^()','^(1,2,6)','^(15,60)>>});
is($rnd->render->result, '0,0,5,51', '^()');

$tpl->set(q{<<~','~()','~(0)>>});
is($rnd->render->result, "$comp,$comp,$comp", '~0');

$tpl->set(q{<<~(1024)>>});
is($rnd->render->result, ~1024, '~1024');
