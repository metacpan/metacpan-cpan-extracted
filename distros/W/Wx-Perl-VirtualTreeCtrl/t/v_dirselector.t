#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 9;

SKIP: {
    eval "require Wx";
    skip "Requires Wx", 9 if $@;

    my $module = 'Wx::Perl::VirtualDirSelector';
    use_ok $module;
    ok $module->isa('Wx::EvtHandler'), '... isa Wx::EventHandler';
    ok $module->isa('Wx::Dialog'), '... isa Wx::Dialog';

    can_ok $module => 'ExpandRoot';
    can_ok $module => 'SetRootItemSelectable';
    can_ok $module => 'SetRootLabel';
    can_ok $module => 'SetRootImage';
    can_ok $module => 'SetImageList';
    can_ok $module => 'GetSelection';
}
