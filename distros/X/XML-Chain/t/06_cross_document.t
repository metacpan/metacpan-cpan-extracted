#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;

use XML::Chain qw(xc);

subtest 'cross-document append' => sub {

    # Create two independent documents
    my $doc1 = xc('list1')->a( 'item', '-' => 'from doc1' );
    my $doc2 = xc('list2')->a( 'item', '-' => 'from doc2' );

    # Get a node from doc2
    my $item_from_doc2 = $doc2->find('//item')->first;

    # Append to doc1 - should work with proper node handling
    $doc1->c('container')->append($item_from_doc2);

    # Verify the structure
    my $container = $doc1->find('//container');
    is( $container->count, 1, 'container was created in doc1' );

    # Note: Depending on implementation, the node might be cloned or
    # moved. The key is it should work without crashing.
    my $items_in_container = $container->children;
    is( $items_in_container->count,
        1, 'item from doc2 is now in doc1 container' );
};

subtest 'cross-document remap' => sub {

    # Create two documents
    my $doc1 =
        xc('root1')
        ->a( 'x', '-' => '1' )
        ->a( 'x', '-' => '2' )
        ->a( 'x', '-' => '3' );

    my $doc2 = xc('root2')->a( 'y', '-' => 'replacement' );

    # Get replacements from different document
    my $replacement = $doc2->find('//y')->first;

    # remap using node from doc2
    my $x_elements = $doc1->find('//x');
    is( $x_elements->count, 3, 'doc1 has 3 x elements before remap' );

    # Replace middle x with y from doc2
    $doc1->find('//x[position()=2]')->remap(
        sub {
            $replacement;
        }
    );

    # Verify remap worked across documents
    my $all_elements = $doc1->find('//x | //y');
    is( $all_elements->count, 3, 'after remap: 2 x + 1 y elements' );

    my $y_in_doc1 = $doc1->find('//y');
    is( $y_in_doc1->count, 1, 'y element is now in doc1' );
};

subtest 'cross-document node identity' => sub {

    # Create sources
    my $doc1 = xc('source1')->a( 'el', id => 'a' );
    my $doc2 = xc('source2')->a( 'el', id => 'b' );

    # Get nodes
    my $el_from_1 = $doc1->find('//el[@id="a"]')->first;
    my $el_from_2 = $doc2->find('//el[@id="b"]')->first;

    # Create target
    my $target = xc('target');

    # Append both to target
    $target->c('container')->append($el_from_1)->up->append($el_from_2);

    # Verify both are in target
    my $all_in_target = $target->find('//el');
    is( $all_in_target->count, 2,
        'both elements from different source docs are in target' );

    # Verify their ids are preserved
    my $a_in_target = $target->find('//el[@id="a"]');
    my $b_in_target = $target->find('//el[@id="b"]');
    is( $a_in_target->count, 1, 'element from doc1 preserved in target' );
    is( $b_in_target->count, 1, 'element from doc2 preserved in target' );
};

subtest 'cross-document find and modify' => sub {

    # Create independent documents
    my $docA =
        xc('tree')->a( 'branch', id => '1' )->up->a( 'branch', id => '2' );

    my $docB =
        xc('tree')->a( 'branch', id => 'x' )->up->a( 'branch', id => 'y' );

    # Find and modify in docA
    my $branch_1 = $docA->find('//branch[@id="1"]')->first;
    $branch_1->attr( source => 'docA' );

    # Get a branch from docB and append to docA
    my $branch_x  = $docB->find('//branch[@id="x"]')->first;
    my $container = $docA->c('imports');

    # This tests that we can handle nodes from different documents
    $container->append($branch_x);

    # Verify structure
    is( $docA->find('//branch')->count,
        3, 'docA now has all its branches plus imported one' );

    my $imported = $docA->find('//branch[@id="x"]');
    is( $imported->count, 1, 'imported branch from docB is in docA' );
};

subtest 'cross-document empty/leaf operations' => sub {

    # Test operations on nodes from different documents
    my $doc1 = xc('parent')->a( 'child', '-' => 'text' );
    my $doc2 = xc('donor')->a('empty_el');

    # Get empty element from doc2
    my $empty = $doc2->find('//empty_el')->first;

    # Get child from doc1
    my $child = $doc1->find('//child')->first;

    # Try to append to empty from another doc
    my $result =
        $doc1->c('container')->append($empty)->up->find('//empty_el');
    is( $result->count, 1,
        'empty element from another document can be appended' );

    # Verify children of imported element
    my $empty_children = $result->children;
    is( $empty_children->count, 0, 'imported empty element remains empty' );
};

subtest 'data() storage - cross-document behavior' => sub {
    my $doc1 = xc( \'<root><el id="a"/></root>' );
    my $doc2 = xc( \'<root><el id="b"/></root>' );

    # Set data in doc1
    my $el_a = $doc1->find('//el[@id="a"]')->first;
    $el_a->data( source => 'doc1' );
    is( $el_a->data('source'), 'doc1', 'data set in doc1' );

    # Try to move/copy element to doc2
    my $el_b = $doc2->find('//el[@id="b"]')->first;
    $el_b->data( source => 'doc2' );

    # Append el_a to doc2
    $doc2->c('imported')->append($el_a);

    # The imported element is now a new object with a new unique_key
    # It will NOT have the data from doc1
    my $imported = $doc2->find('//el[@id="a"]')->first;

    # NOTE: This element is now orphaned from the original _xc_el_data cache
    # So data() returns empty hash (new element, no data set)
    my $imported_data = $imported->data;
    is_deeply( $imported_data, {},
        'data does NOT survive cross-document operations' );

    # el_b still has its original data in doc2
    my $el_b_check = $doc2->find('//el[@id="b"]')->first;
    is( $el_b_check->data('source'),
        'doc2', 'other document data unaffected' );
};

done_testing;
