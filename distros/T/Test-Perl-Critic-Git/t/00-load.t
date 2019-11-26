#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('Test::Perl::Critic::Git') || print "Bail out!\n";
    use_ok('Test::MockModule')        || print "Bail out!\n";
}

diag("Testing Test::Perl::Critic::Git $Test::Perl::Critic::Git::VERSION, Perl $], $^X");

my $import = Test::Perl::Critic::Git->import(
    {
        -severity => 'brutal',
        -exclude => [
            #'ProhibitStringyEval',
            'ProhibitHashBarewords',
            # 'ProhibitPostfixControls',
            # 'RequireTidyCode',
            # 'ProhibitBuiltinHomonyms',
            # 'RequireArgUnpacking',
            # 'ProhibitPunctuationVars',

            # # file yml
            # 'RequireCheckedSyscalls',
            # 'RequireCheckedClose',

            # # sqlite converter
            # 'ProhibitMultiplePackages',

            # #weired regex stuff
            # 'ProhibitEscapedMetacharacters',
            # 'RequireExtendedFormatting',
            # 'RequireDotMatchAnything',
            # 'RequireLineBoundaryMatching',

            # # I'm using unless, deal with it
            # 'ProhibitUnlessBlocks',

            # # Some sub are called from string
            # 'ProhibitUnusedPrivateSubroutines',

            # 'ProhibitLongChainsOfMethodCalls'
        ]
    },
    {},
    { explicit => ['pm'] }
);
is $import, 'main', 'import test';

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
                subtraction => { 44 => '   my ($string) = @_;' },
            },
            'some/files/in/git.pm' => {
                addition => { 44 => '   my ( $string ) = @_;' },
                changed  => {
                    '-44 +44 ' => q~sub is_identifier {
        -   my ($string) = @_;
        +   my ( $string ) = @_;
        ~
                },
                raw         => undef,
                subtraction => { 44 => '   my ($string) = @_;' },
            },
            'some/filer/in/git.pm' => {
                addition => { 55 => '   my ( $string ) = @_;' },
                changed  => {
                    '-55 +55 ' => q~sub is_identifier {
        -   my ($string) = @_;
        +   my ( $string ) = @_;
        ~
                },
                raw         => undef,
                subtraction => { 55 => '   my ($string) = @_;' },
            },
            't/unit.t' => {
                addition => { 88 => '   my ( $string ) = @_;' },
                changed  => {
                    '-88 +88 ' => q~sub is_identifier {
        -   my ($string) = @_;
        +   my ( $string ) = @_;
        ~
                },
                raw         => undef,
                subtraction => { 88 => '   my ($string) = @_;' },
            },
        };
    },
);
critic_on_changed_ok( ['.'], 'critic_on_changed_ok test' );

my $o_criticutils_mock = Test::MockModule->new('Test::Perl::Critic::Git');
$o_criticutils_mock->mock(
    _matching_files => sub {
        my ( $ar_dirs, $hr_changed_files ) = @_;
        return ['some/file/in/git.pm'];
    },
);

my $o_critic_mock = Test::MockModule->new('Perl::Critic');
$o_critic_mock->mock(
    critique => sub {
        my $desc = 'Offending code';    # Describe the violation
        my $expl = [ 1, 45, 67 ];       # Page numbers from PBP
        my $sev  = 5;                   # Severity level of this violation
        require PPI::Element;
        require Perl::Critic::Violation;
        return Perl::Critic::Violation->new( $desc, $expl, PPI::Document->new( \'print "Hello World!\n"' )->child(0), $sev );
    }
);

my $o_violation_mock = Test::MockModule->new('Perl::Critic::Violation');
$o_violation_mock->mock( line_number => sub { 80; } );
critic_on_changed_ok( ['.'], 'critic_on_changed_ok test' );

$o_violation_mock->mock( line_number => sub { 23; } );
critic_on_changed_not_ok( ['.'], 'critic_on_changed_not_ok test' );
