#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use XS::JIT::Builder;

# Test default (4 spaces)
subtest 'Default indentation (4 spaces)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('test')
      ->if('x > 0')
        ->return_iv('1')
      ->endif
      ->xs_end;
    
    my $code = $b->code;
    like($code, qr/^    if \(x > 0\)/m, 'if indented with 4 spaces');
    like($code, qr/^        ST\(0\)/m, 'body indented with 8 spaces');
};

# Test custom space width
subtest 'Custom indent width (2 spaces)' => sub {
    my $b = XS::JIT::Builder->new(indent_width => 2);
    $b->xs_function('test')
      ->if('x > 0')
        ->return_iv('1')
      ->endif
      ->xs_end;
    
    my $code = $b->code;
    like($code, qr/^  if \(x > 0\)/m, 'if indented with 2 spaces');
    like($code, qr/^    ST\(0\)/m, 'body indented with 4 spaces');
};

# Test tabs
subtest 'Tab indentation' => sub {
    my $b = XS::JIT::Builder->new(use_tabs => 1);
    $b->xs_function('test')
      ->if('x > 0')
        ->return_iv('1')
      ->endif
      ->xs_end;
    
    my $code = $b->code;
    like($code, qr/^\tif \(x > 0\)/m, 'if indented with 1 tab');
    like($code, qr/^\t\tST\(0\)/m, 'body indented with 2 tabs');
    unlike($code, qr/^    /m, 'no 4-space indentation');
};

# Test tabs with nested blocks
subtest 'Tabs with deep nesting' => sub {
    my $b = XS::JIT::Builder->new(use_tabs => 1);
    $b->xs_function('test')
      ->xs_preamble
      ->if('a')
        ->if('b')
          ->if('c')
            ->return_iv('1')
          ->endif
        ->endif
      ->endif
      ->xs_end;
    
    my $code = $b->code;
    like($code, qr/^\t\t\t\tST\(0\)/m, 'deeply nested code has 4 tabs');
};

done_testing;
