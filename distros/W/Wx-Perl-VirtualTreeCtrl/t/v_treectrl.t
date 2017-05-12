#!/usr/local/bin/perl -w
use strict;
use Test::More tests => 5;

SKIP: {
    eval "require Wx";
    skip "Requires Wx", 5 if $@;

    my $module = 'Wx::Perl::VirtualTreeCtrl';
    use_ok $module;
    ok $module->isa('Wx::EvtHandler'), '... isa Wx::EventHandler';

    ok ! defined(&{"EVT_POPULATE_TREE_ITEM"}), "... doesn't export anything";
    import $module 'EVT_POPULATE_TREE_ITEM';
    ok defined(&{"EVT_POPULATE_TREE_ITEM"}),
        '... but can export EVT_POPULATE_TREE_ITEM';

    ok $module->can('GetTree'), '... can GetTree';
}
