#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

__PACKAGE__->main('UR');

sub main {
    my ($test, $module) = @_;
    use_ok($module) or exit;
    
    $test->ur_context_class_commit_triggers_observer;
    
    done_testing();
}

sub ur_context_class_commit_triggers_observer {
    my $self = shift;
    my $context = UR::Context->current;
    
    my @expected_signals = (
            [ $context, 'precommit' ],
            [ $context, 'sync_databases' => 1 ],
            [ $context, 'commit' => 1 ],
    );

    my @signals_fired;

    foreach my $signal ( @expected_signals ) {
        my $aspect = $signal->[1];
        $context->add_observer(
            aspect => $aspect,
            callback => sub {
                push @signals_fired, [ @_ ];
            }
        );
    }

    ok(UR::Context->commit, 'UR::Context committed');

    is_deeply(\@signals_fired, \@expected_signals, 'Got expected signals and args');
}
