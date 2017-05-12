#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

__PACKAGE__->main('UR');

sub main {
    my ($test, $module) = @_;
    use_ok($module) or exit;
    
    $test->ur_context_process_is_distinguished_from_current;
    
    done_testing();
}

sub ur_context_process_is_distinguished_from_current {
    my $self = shift;

    my $cc = UR::Context->current;
    my $cp = UR::Context->process;
    is($cc->id, $cp->id, 'current returned the same as process');

    my $tx = UR::Context::Transaction->begin;
    my $new_cc = UR::Context->current;
    my $new_cp = UR::Context->process;
    isnt($new_cc->id, $cc->id, 'current changed within transaction');
    is  ($new_cp->id, $cp->id, 'process did not change within transaction');
}
