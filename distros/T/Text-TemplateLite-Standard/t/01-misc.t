#!perl -T

use Test::More tests => 11;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:misc/);

is_deeply([ $tpl->get_tokens(q{$=('a',1)}) ],
  [ '$=', '(', "'a'", ',', '1', ')' ], 'assignment parsing');
ok($tpl->{defs}{'$='}, '$= function is registered');

$tpl->set(q{<<$=('a')>>});
is($rnd->render({ a => 100 })->result, '100', '$= for rendered variable');

$tpl->set(q{<<'$a0='$a$=('a',1)';$a1='$a$=('a',2)';$a2='$=('a')>>});
is($rnd->render->result, '$a0=;$a1=1;$a2=2', 'set/get using $=');
is_deeply($rnd->vars, { a => 2}, 'renderer vars after render');

$tpl->set(q{<<$=('c',12,'d',13)>>});
is($rnd->render->result, '', '$= w/ even # args has no value');
is_deeply($rnd->vars, { c => 12, d => 13 }, '$= multi-set');

$tpl->set(q{<<$=('e',14,'f',15,'f')>>});
is($rnd->render->result, '15', '$= w/ odd # args returns value');
is_deeply($rnd->vars, { e => 14, f => 15 }, '$= multi-set w/ return');

$tpl->set(q{<<'before'void($=('during','void')'expr')'after'>>});
is($rnd->render->result, 'beforeafter', 'void value not returned');
is_deeply($rnd->vars, { during => 'void' }, 'void value evaluated');

# END
