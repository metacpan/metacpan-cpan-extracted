#!perl -T

use Test::More tests => 10;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:misc :conditional $;/);

$tpl->set(q{<<$;('+', 1, '', 2, $a, 3, $=('b'), 4)>>});
is($rnd->render->result, '1++2++3++4', 'join seps for empty args');

$tpl->set(q{<<$;('+', ?(1, '', 2, $a, 3, $=('b'), 4))>>});
is($rnd->render->result, '1+2+3+4', 'join w/ ?() to remove empties');

$tpl->set(q{<<??('default only')>>});
is($rnd->render->result, 'default only', 'if/else w/ default only');

$tpl->set(q{<<??(1,'1st',$=('side','effect')'2nd')>>});
is($rnd->render->result, '1st', '?? T w/ default');
is_deeply($rnd->vars, {}, '?? T default not evaluated');

$tpl->set(q{<<??(0,'1st',$=('side','effect')'2nd')>>});
is($rnd->render->result, '2nd', '?? F w/ default');
is_deeply($rnd->vars, { side => 'effect' }, '?? F default evaluated');

$tpl->set(q{<<??(0,'1st','','2nd','3rd')>>});
is($rnd->render->result, '3rd', '?? FF w/ default');

$tpl->set(q{<<??(0,'1st','','2nd',-1,'3rd')>>});
is($rnd->render->result, '3rd', '?? FFT');

$tpl->set(q{<<??(0,'1st','','2nd',-1,'3rd','4th')>>});
is($rnd->render->result, '3rd', '?? FFT w/ default');
