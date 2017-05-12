#!perl -T -w

use Test::More tests => 5;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:misc :iteration :numeric/);

$tpl->set(q{<<?*(0,'code')'end'>>});
is($rnd->limit(total_steps => 100)->render->result, 'end',
  'no code exec on ?*(0)');

$tpl->set(q{<<*?('code',0)'end'>>});
is($rnd->limit(total_steps => 100)->render->result, 'codeend',
  'one code exec on *?(0)');

$tpl->set(q{<<?*(1,'code')>>});
is($rnd->limit(total_steps => 5)->render->result, 'codecode',
  'two code exec on ?*(1) lim 5');

$tpl->set(q{<<*?('code',1)>>});
is($rnd->limit(total_steps => 5)->render->result, 'codecode',
  'two code exec on *?(1) lim 5');

$tpl->set(q{<<$=('n',1)?*(<($n,5),$n$=('n',+($n,1)))' $n now '$n>>});
is($rnd->limit(total_steps => 200)->render->result, '1234 $n now 5',
  '$n=1; $n ?* < 5');
