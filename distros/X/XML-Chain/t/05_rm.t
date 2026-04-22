#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;

use XML::Chain qw(xc);

subtest 'deleted element handling' => sub {

    # Test 1: Delete elements and verify they're removed from DOM
    my $root =
        xc( \'<root><p>one</p><p>two</p><p>three</p><div>four</div></root>' );
    my $all_p = $root->find('//p');
    is( $all_p->count, 3, 'all_p selection has 3 <p> elements' );

    # Delete first <p> via rm()
    my $first_p = $all_p->first;
    $first_p->rm;

    # Verify it's removed from DOM
    is( $root->find('//p')->count,
        2, 'after rm(), only 2 <p> elements remain' );
    is( $root->as_string,
        '<root><p>two</p><p>three</p><div>four</div></root>',
        'rm() removes element from live DOM'
    );

    # Test 2: Old selector with deleted elements skips them in iteration
    my $root2 =
        xc( \'<root><item id="1"/><item id="2"/><item id="3"/></root>' );
    my $all_items = $root2->find('//item');
    is( $all_items->count, 3, 'all_items before deletion: 3 elements' );

    # Delete the middle item
    my $middle = $root2->find('//item[@id="2"]')->first;
    $middle->rm;

    # Now check that all_items (captured before deletion) still skips deleted
    is( $all_items->count, 2,
        'old selector skips deleted elements in count()' );

    # Iteration via _cur_el_iterrate should skip the deleted one
    my $count = 0;
    $all_items->each( sub { $count++ } );
    is( $count, 2, 'each() iteration skips deleted elements' );

    # Test 3: Direct operations on selections with deleted elements
    my $root3   = xc( \'<root><el a="1"/><el a="2"/><el a="3"/></root>' );
    my $all_els = $root3->find('//el');
    is( $all_els->count, 3, 'all_els before deletion: 3 elements' );

    # Delete second element
    my $second = $root3->find('//el[@a="2"]')->first;
    $second->rm;

    # Operations on the selection should skip the deleted one
    $all_els->attr( b => 'set' );
    my @remaining_els = $root3->find('//el')->as_xml_libxml;
    is( scalar(@remaining_els), 2,
        'find() after deletion returns 2 elements' );
    foreach my $el (@remaining_els) {
        is( $el->getAttribute('b'),
            'set', 'attr() on selection skipped deleted elements' );
    }

    # Test 4: Multi-element delete preserves iteration safety
    my $root4     = xc( \'<root><x/><y/><z/><w/></root>' );
    my $all_nodes = $root4->find('//x | //y | //z | //w');
    is( $all_nodes->count, 4, 'root4 before deletion: 4 elements' );

    # Delete multiple elements
    $root4->find('//y')->rm;
    $root4->find('//w')->rm;

    # Previous selection should still skip both deleted elements
    is( $all_nodes->count, 2,
        'multi-delete: old selector correctly skips 2 deleted elements' );
    my @final_elements = $all_nodes->as_xml_libxml;
    is( scalar(@final_elements), 2,
        'as_xml_libxml correctly returns non-deleted elements' );
};

done_testing();
