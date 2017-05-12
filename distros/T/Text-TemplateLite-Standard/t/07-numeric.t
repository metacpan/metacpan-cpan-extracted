#!perl -T

use Test::More tests => 16;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;
my $rnd = $tpl->new_renderer;

Text::TemplateLite::Standard::register($tpl, qw/:numeric/);

## + - * / %

$tpl->set(q{<<+ ',' +() ',' +('') ',' +(1) ',' +(2,4) ',' +(8,16,32)>>});
is($rnd->render->result, '0,0,0,1,6,56', '+');

$tpl->set(q{<<- ',' -() ',' -(1) ',' -(4,2) ',' -(32,16,8)>>});
is($rnd->render->result, '0,0,-1,2,16', '-');

$tpl->set(q{<<* ',' *() ',' *(3) ',' *(2,4) ',' *(8,16,32)>>});
is($rnd->render->result, '1,1,3,8,4096', '*');

$tpl->set(q{<</ ',' /() ',' /(2) ',' /(5,2)>>});
is($rnd->render->result, ',,,2.5', '/');

$tpl->set(q{<<% ',' %() ',' %(2) ',' %(39,7)>>});
is($rnd->render->result, ',,,4', '%');

# Tests: 5

## int max min

$tpl->set(q{<<int','int()','int('a')','int(2)','int(4.5)','int(-6.5)>>});
is($rnd->render->result, '0,0,0,2,4,-6', 'int()');

$tpl->set(q{<<max','max()','max(-3,-1,-2)','max(1,3,2)>>});
is($rnd->render->result, ',,-1,3', 'max()');

$tpl->set(q{<<min',',min()','min(-1,-3,-2)','min(3,1,2)>>});
is($rnd->render->result, ',,-3,1', 'min()');

## <=> = >= > <= < !=

$tpl->set(q{<< <=>(9,10)'.'<=>(10,10)'.'<=>(10,9)>>});
is($rnd->render->result, '-1.0.1', '<=> 9,10 10,10 10,9');

$tpl->set(q{<< <=>(-9,-10)'.'<=>(-10,-10)'.'<=>(-10,-9)>>});
is($rnd->render->result, '1.0.-1', '<=> -9,-10 -10,-10 -10,-9');

$tpl->set(q{<< =(9,10)'.'=(10,10)'.'=(10,9)>>});
is($rnd->render->result, '.1.', '= 9,10 10,10 10,9');

$tpl->set(q{<< >=(9,10)'.'>=(10,10)'.'>=(10,9)>>});
is($rnd->render->result, '.1.1', '>= 9,10 10,10 10,9');

$tpl->set(q{<< >(9,10)'.'>(10,10)'.'>(10,9)>>});
is($rnd->render->result, '..1', '> 9,10 10,10 10,9');

$tpl->set(q{<< <=(9,10)'.'<=(10,10)'.'<=(10,9)>>});
is($rnd->render->result, '1.1.', '<= 9,10 10,10 10,9');

$tpl->set(q{<< <(9,10)'.'<(10,10)'.'<(10,9)>>});
is($rnd->render->result, '1..', '< 9,10 10,10 10,9');

$tpl->set(q{<< !=(9,10)'.'!=(10,10)'.'!=(10,9)>>});
is($rnd->render->result, '1..1', '!= 9,10 10,10 10,9');

# Tests: 7
