#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

# Test complex chained control flow
my $b = XS::JIT::Builder->new;

$b->xs_function('complex_func')
  ->xs_preamble
  ->get_self_hv
  ->if('items < 1')
    ->croak('No arguments')
  ->elsif('items > 5')
    ->croak('Too many arguments')
  ->else
    ->line('// Process arguments')
  ->endif
  ->xs_return(1)
  ->xs_end;

my $code = $b->code;
like($code, qr/XS_EUPXS\(complex_func\)/, 'complex function has header');
like($code, qr/dVAR; dXSARGS;/, 'complex function has preamble');
like($code, qr/HV\* hv = \(HV\*\)SvRV\(self\);/, 'complex function has self_hv');
like($code, qr/if \(items < 1\).*croak.*else if.*items > 5.*croak.*else/s, 'complex function has control flow');
like($code, qr/XSRETURN\(1\);/, 'complex function returns');
like($code, qr/\}\s*$/, 'complex function closes');
$b->reset;

# Test building a complete accessor by chaining
$b->xs_function('Person_get_age')
  ->xs_preamble
  ->if('items > 1')
    ->croak('Read only attribute')
  ->endif
  ->get_self_hv
  ->hv_fetch_return('hv', 'age', 3);

$code = $b->code;
like($code, qr/XS_EUPXS\(Person_get_age\)/, 'manual accessor has function');
like($code, qr/Read only attribute/, 'manual accessor has croak');
like($code, qr/hv_fetch.*"age".*3/, 'manual accessor fetches');
like($code, qr/XSRETURN\(1\)/, 'manual accessor returns');
$b->reset;

# Test nested control structures
$b->if('x > 0')
    ->if('y > 0')
      ->line('quadrant_1();')
    ->else
      ->line('quadrant_4();')
    ->endif
  ->else
    ->if('y > 0')
      ->line('quadrant_2();')
    ->else
      ->line('quadrant_3();')
    ->endif
  ->endif;

$code = $b->code;
like($code, qr/if \(x > 0\)/, 'nested has outer if');
like($code, qr/if \(y > 0\)/, 'nested has inner if');
like($code, qr/quadrant_1/, 'nested has q1');
like($code, qr/quadrant_2/, 'nested has q2');
like($code, qr/quadrant_3/, 'nested has q3');
like($code, qr/quadrant_4/, 'nested has q4');
$b->reset;

# Test loop with control flow inside
$b->for('int i = 0', 'i < n', 'i++')
    ->if('items[i] == NULL')
      ->line('continue;')
    ->endif
    ->line('process(items[i]);')
  ->endloop;

$code = $b->code;
like($code, qr/for \(int i = 0; i < n; i\+\+\)/, 'loop with if has for');
like($code, qr/if \(items\[i\] == NULL\)/, 'loop with if has condition');
like($code, qr/continue;/, 'loop with if has continue');
like($code, qr/process\(items\[i\]\);/, 'loop with if has body');
$b->reset;

done_testing();
