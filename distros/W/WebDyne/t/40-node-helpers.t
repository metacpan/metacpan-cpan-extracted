#!/bin/perl
#
#  Direct tests for node tree helper methods.
#
use strict qw(vars);
use warnings;

use Test::More tests => 7;
use WebDyne;
use WebDyne::Constant;


sub node {

    my ($tag, $attr_hr, $chld_ar)=@_;
    my @node;
    @node[
        WEBDYNE_NODE_NAME_IX,
        WEBDYNE_NODE_ATTR_IX,
        WEBDYNE_NODE_CHLD_IX,
    ]=($tag, ($attr_hr || {}), ($chld_ar || []));
    return \@node;

}


my $p_direct=node('p', {id => 'direct'}, ['direct']);
my $p_deep=node('p', {id => 'deep'}, ['deep']);
my $div=node('div', {id => 'container'}, ['before', $p_deep, 'after']);
my $root=node('html', {}, ['lead', $p_direct, $div, 'tail']);
my $wd=bless {}, 'WebDyne';


my $all_p_ar=$wd->find_node({data_ar => $root, tag => 'p', all_fg => 1});
is(scalar @{$all_p_ar}, 2, 'find_node finds all matching descendants');
is_deeply([map {$_->[WEBDYNE_NODE_ATTR_IX]{'id'}} @{$all_p_ar}], [qw(direct deep)], 'find_node preserves traversal order');

my $shallow_p_ar=$wd->find_node({data_ar => $root, tag => 'p', all_fg => 1, depth => 1});
is_deeply([map {$_->[WEBDYNE_NODE_ATTR_IX]{'id'}} @{$shallow_p_ar}], ['direct'], 'find_node depth limits traversal by tree depth');

my $deep_p_ar=$wd->find_node({data_ar => $root, tag => 'p', attr_hr => {id => 'deep'}, all_fg => 1});
is_deeply($deep_p_ar, [$p_deep], 'find_node matches requested attributes');

my $parent_ar=$wd->find_node({data_ar => $root, tag => 'p', attr_hr => {id => 'deep'}, prnt_fg => 1});
is_deeply($parent_ar, [$div], 'find_node can return parent node');

my $delete_sr=$wd->delete_node({data_ar => $root, node_ar => $p_deep});
ok(${$delete_sr}, 'delete_node deletes a matching child below text siblings');

my $remaining_p_ar=$wd->find_node({data_ar => $root, tag => 'p', all_fg => 1});
is_deeply([map {$_->[WEBDYNE_NODE_ATTR_IX]{'id'}} @{$remaining_p_ar}], ['direct'], 'delete_node removed only the target node');
