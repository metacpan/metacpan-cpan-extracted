#!/usr/bin/perl -w

use strict;
use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Wx::App::Mastermind',
    license            => 'perl',
    author             => 'Mattia Barbon <mbarbon@cpan.org>',
    requires           => { 'Wx'                                    => 0.56,
                            'Class::Accessor'                       => 0.27,
                            'Class::Publisher'                      => 0.02,
                            'Games::Mastermind'                     => 0.01,
                            'Games::Mastermind::Solver::BruteForce' => 0.02,
                            'Thread::Queue::Any::Monitored'         => 0.07,
                            },
    script_files       => [qw(bin/wxperl_mm.pl)],
    create_makefile_pl => 'passthrough',
    );
$build->create_build_script;
