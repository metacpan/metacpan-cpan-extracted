#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('XS::JIT::Builder');

my $b = XS::JIT::Builder->new;

# Test control flow - if
$b->if('x > 0')
  ->line('positive();')
  ->endif;
my $code = $b->code;
like($code, qr/if \(x > 0\) \{/, 'if() creates if statement');
like($code, qr/positive\(\);/, 'body is indented');
like($code, qr/\}\n$/, 'endif closes if');
$b->reset;

# Test if/else
$b->if('x > 0')
  ->line('positive();')
  ->else
  ->line('non_positive();')
  ->endif;
$code = $b->code;
like($code, qr/if \(x > 0\) \{/, 'if creates if');
like($code, qr/\} else \{/, 'else creates else');
$b->reset;

# Test if/elsif/else
$b->if('x > 0')
  ->line('positive();')
  ->elsif('x < 0')
  ->line('negative();')
  ->else
  ->line('zero();')
  ->endif;
$code = $b->code;
like($code, qr/\} else if \(x < 0\) \{/, 'elsif creates else if');
$b->reset;

# Test for loop
$b->for('int i = 0', 'i < 10', 'i++')
  ->line('do_something(i);')
  ->endloop;
$code = $b->code;
like($code, qr/for \(int i = 0; i < 10; i\+\+\) \{/, 'for creates for loop');
$b->reset;

# Test while loop
$b->while('running')
  ->line('iterate();')
  ->endloop;
$code = $b->code;
like($code, qr/while \(running\) \{/, 'while creates while loop');
$b->reset;

# Test chaining returns self
{
    my $test_b = XS::JIT::Builder->new;
    is($test_b->if('1'), $test_b, 'if returns $self');
    is($test_b->elsif('0'), $test_b, 'elsif returns $self');
    is($test_b->else, $test_b, 'else returns $self');
    is($test_b->endif, $test_b, 'endif returns $self');
    
    $test_b = XS::JIT::Builder->new;
    is($test_b->for('i=0', 'i<10', 'i++'), $test_b, 'for returns $self');
    is($test_b->endloop, $test_b, 'endloop returns $self');
    
    $test_b = XS::JIT::Builder->new;
    is($test_b->while('1'), $test_b, 'while returns $self');
}

done_testing();
