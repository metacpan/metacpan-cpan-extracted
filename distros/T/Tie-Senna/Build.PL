#!perl
# $Id: Build.PL 2 2005-11-15 15:43:07Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOSUB');
    sub ACTION_disttest
    {
        my $self = shift;
        local $ENV{PERL_TESTPOD} = 1;
        $self->SUPER::ACTION_disttest(@_);
    }

    sub find_test_files
    {
        my $self  = shift;
        my $tests = $self->SUPER::find_test_files(@_);

        return $tests if $ENV{PERL_TESTPOD};
        return [ grep { $_ !~ /\bpod.*\.t\z/ } @$tests ];
    }
EOSUB

my $build = $class->new(
    module_name => 'Tie::Senna',
    requires => {
        'Senna'     => '>= 0.06',
        'Tie::Hash' => 0,
    },
    license => 'perl',
    create_makefile_pl => 'traditional',
    create_readme => 1,
);
$build->create_build_script;