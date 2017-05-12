#!perl
use strict;
use warnings FATAL => 'all';
use File::Spec qw();

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => 'Test::Perl::Critic required for testing PBP compliance');
}

Test::Perl::Critic->import(
    -profile  => File::Spec->catfile(qw(xt perlcriticrc)),
    -severity => 2,
    -exclude  => [

        # These disabled policy violates should be cleared up over time.
        # Can't see a straightforward way to turn those into todo (TAP).
        # Things which should be ignored outright go into the rc file instead.

        'ErrorHandling::RequireUseOfExceptions',    # rework with X::Error.pm
        'Subroutines::ProhibitExportingUndeclaredSubs',
        # trips on the XS subs, will file P::C bug with patch later

        'CodeLayout::RequireUseUTF8',
        # should not trigger if use 5.006, will file P::C bug with patch later

        'CodeLayout::ProhibitHardTabs',   # contradicts docs, clearly a P::C bug

        'Modules::RequireVersionVar',     # waiting for other solution proposal
        'ErrorHandling::RequireCarping',  # change to log console

        'Documentation::PodSpelling',     # will do later

        # following are undiscussed improvements
        'Subroutines::ProhibitManyArgs',
        'ControlStructures::ProhibitCascadingIfElse',
        'Documentation::RequirePodSections',
        'ControlStructures::ProhibitPostfixControls',
        'CodeLayout::RequireTidyCode',

        'Documentation::RequirePodAtEnd',    # later
        'Documentation::RequireEndBeforeLastPod',
    ],
);
Test::Perl::Critic::all_critic_ok();
