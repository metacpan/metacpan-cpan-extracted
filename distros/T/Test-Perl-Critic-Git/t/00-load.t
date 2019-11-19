#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Test::Perl::Critic::Git') || print "Bail out!\n";
    use_ok('Test::MockModule')        || print "Bail out!\n";
}

diag(
    "Testing Test::Perl::Critic::Git $Test::Perl::Critic::Git::VERSION, Perl $], $^X"
);

my $o_gitdiff_mock = Test::MockModule->new('Git::Diff');
$o_gitdiff_mock->mock(
    new => sub {
        my ($s_class) = @_;
        return bless {}, $s_class;
    },
    changes_by_line => sub {
        return {
            'some/file/in/git.pm' => {
                addition => { 23 => '   my ( $string ) = @_;' },
                changed  => {
                    '-23 +23 ' => q~sub is_identifier {
        -   my ($string) = @_;
        +   my ( $string ) = @_;
        ~
                },
                raw         => undef,
                subtraction => { 23 => '   my ($string) = @_;' },
            }
        };
    },
);
my $import = Test::Perl::Critic::Git->import;
is $import, 'main', 'import test';

ok critic_on_changed_ok, 'critic_on_changed_ok test';

my $o_criticutils_mock = Test::MockModule->new('Test::Perl::Critic::Git');
$o_criticutils_mock->mock(
    _matching_files => sub {
        my ( $ar_dirs, $hr_changed_files ) = @_;
        return ['some/file/in/git.pm'];
    },
);

my $o_critic_mock = Test::MockModule->new('Perl::Critic');
$o_critic_mock->mock( critique => sub { return; }, );

ok critic_on_changed_ok, 'critic_on_changed_ok test';
