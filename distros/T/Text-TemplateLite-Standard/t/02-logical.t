#!perl -T

use Test::More tests => 10;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:misc :logical/);

$tpl->set(q{<<&&($=('a',1)1,$=('b',2)'t',$=('c',3),$=('d',4))>>});
is($rnd->render->result, '0', '&& TTFF is 0/false');
is_deeply($rnd->vars, { a => 1, b => 2, c => 3 }, '&& TTFF evals 3');

$tpl->set(q{<<&&($=('a',1)1,$=('b',2)'t')>>});
is($rnd->render->result, '1', '&& TT is 1/true');

$tpl->set(q{<<||($=('a',1)0,$=('b',2),$=('c',3)1,$=('d',4)'t')>>});
is($rnd->render->result, '1', '&& FFTT is 1/true');
is_deeply($rnd->vars, { a => 1, b => 2, c => 3 }, '&& FFTT evals 3');

$tpl->set(q{<<||($=('a',1)0,$=('b',2))>>});
is($rnd->render->result, '0', '&& FF is 0/false');

$tpl->set(q{<<!>>});
is($rnd->render->result, '1', '! is 1/true');
$tpl->set(q{<<!()>>});
is($rnd->render->result, '1', '!() is 1/true');
$tpl->set(q{<<!('')>>});
is($rnd->render->result, '1', '!(\'\') is 1/true');
$tpl->set(q{<<!(0)>>});
is($rnd->render->result, '1', '!(0) is 1/true');
