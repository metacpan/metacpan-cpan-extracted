#!perl -T

use Test::More tests => 5;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $trnd = $tpl->new_renderer;
my $ctof = Text::TemplateLite->new;
my $crnd = $ctof->new_renderer;

Text::TemplateLite::Standard::register($_, qw/:misc :numeric :template/)
  foreach ($tpl, $ctof);

# tpl, <$>

# °F = 9/5 °C + 32
$ctof->set(q{<<tpl('c_to_f',+(/(*($1,9),5),32))
  'freezing '$c_to_f(0)' boiling '$c_to_f(100)>>});
is($crnd->render->result, 'freezing 32 boiling 212', 'nested template');

$ctof->set(q{<<tpl('c_to_f',+(/(*($1,9),5),32))
  $=('f_freeze',$c_to_f($c_freeze),'f_boil',$c_to_f($c_boil))>>});
$crnd->render({ c_freeze => 0, c_boil => 100 });
is($crnd->vars->{f_freeze}, 32, 'c_freeze -> f_freeze');
is($crnd->vars->{f_boil}, 212, 'c_boil -> f_boil');

$tpl->register('c_to_f', $ctof)
  ->set(q{<<c_to_f('c_freeze', 0, 'c_boil', 100)
  <$>('f_freeze','f_freeze','f_boil','f_boil','f_boil')>>});
is($trnd->render->result, '212', 'named value from ext tpl');
is_deeply($trnd->vars, { f_freeze => 32, f_boil => 212 },
  'import from ext tpl');
