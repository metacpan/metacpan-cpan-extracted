#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;

use XML::Chain qw(xc);

subtest 'loop over elements, rename' => sub {
    my $body = xc('bodyz');
    is( $body, '<bodyz></bodyz>', 'rename()' );

    $body->rename('body');
    $body->a( xc('p.1')->t(1) )->a( xc('p.2')->t(2) )->a( xc('div')->t(3) )
        ->a( xc('p.3')->t(4) )
        ->children->each( sub { $_->rename('p') if $_->name =~ m/^p[.]/ } );
    is( $body,
        '<body><p>1</p><p>2</p><div>3</div><p>4</p></body>',
        '=head2 each; rename using each()'
    );

    my $remap = xc('body')->a( 'p', i => 1 );
    is( $remap->children->remap(
            sub {
                ( map { xc( 'e', i => $_ ) } 1 .. 3 ), $_;
            }
        )->root,
        '<body><e i="1"></e><e i="2"></e><e i="3"></e><p i="1"></p></body>',
        '=head2 remap; add +3 elements'
    );
    is( $remap->find('//e[position()=2]')->remap(
            sub {
                xc( 'p', i => 4 ), xc( 'p', i => 5 ),;
            }
        )->root,
        '<body><e i="1"></e><p i="4"></p><p i="5"></p><e i="3"></e><p i="1"></p></body>',
        'replace element'
    );
    is( $remap->find('//e[@i="2"] | //p[@i="5"]')->remap( sub { } )->root,
        '<body><e i="1"></e><p i="4"></p><e i="3"></e><p i="1"></p></body>',
        'remove elements'
    );

    my $remap2 = xc( \'<body><p>1</p><p>2</p><div>3</div><p>4</p></body>' );
    $remap2->children->remap(
        sub {
            (   ( $_->name eq 'div' )
                ? xc('p')->t( $_->text_content )    # replace <div> with <p>
                : $_->text_content eq '2'
                ? (    # replace the node with text "2" with 3 <div> elements
                    xc('div')->t(2),
                    xc('div')->t(21),
                    xc('div')->t(22),
                    )
                : $_->text_content eq '4'
                ? undef    # delete the <p> with text "4"
                : $_       # keep the first <p>
            )
        }
    );
    is( $remap2,
        '<body><p>1</p><div>2</div><div>21</div><div>22</div><p>3</p></body>',
        'replace and delete element via remap()'
    );

wrap_element: {
        local $TODO = 'wrap element';
        my $i = 5;
        is( xc('body')
                ->a('p1')
                ->a('p2')
                ->children->remap( sub { xc( 'div' . $i++ )->a($_) } )->root,
            '<body><div5><p1/></div5><div6><p2/></div6></body>',
        );
    }
};

subtest 'root-level navigation edge cases' => sub {
    my $root = xc( \'<root><child1><child2/></child1><child3/></root>' );

    # up() at root returns root (already tested, but verify again)
    is( $root->up->name, 'root', 'up() on root returns root' );

    # find() at root works normally
    is( $root->find('//child1')->count, 1,
        'find() on root locates elements' );

    # find() that matches root itself, then up
    is( $root->find('/root')->up->name,
        'root', 'find() matching root, then up() returns root' );

    # children() at root returns all child elements
    is( $root->children->count,
        2, 'children() at root returns child elements' );
    my @child_elements = $root->children->as_xml_libxml;
    my $child_names    = join( ',', map { $_->nodeName } @child_elements );
    is( $child_names, 'child1,child3', 'children() returns correct order' );
};

subtest 'empty selections edge cases' => sub {
    my $root = xc( \'<root><leaf/><branch><subbranch/></branch></root>' );

    # find() with no matches returns empty selection
    my $empty1 = $root->find('//nonexistent');
    is( $empty1->count, 0, 'find() with no matches returns empty selection' );
    is( $empty1->as_string, '',
        'empty selection serializes to empty string' );

    # Chaining on empty selection should not crash
    my $still_empty = $empty1->find('//child');
    is( $still_empty->count, 0, 'chaining find() on empty selection works' );

    # children() on leaf node returns empty
    my $leaf          = $root->find('//leaf');
    my $leaf_children = $leaf->children;
    is( $leaf_children->count, 0,
        'children() on leaf node returns empty selection' );

    # first() on empty selection should work but return nothing
    my $nothing = $root->find('//missing')->first;
    is( $nothing->count, 0, 'first() on empty selection returns empty' );
};

subtest 'multi-element single() failures' => sub {
    my $root = xc( \'<root><child/><child/><child/></root>' );

    # single() on empty selection throws
    throws_ok(
        sub { $root->find('//missing')->single },
        qr/no current element/i,
        'single() on empty selection throws with clear error',
    );

    # single() on multi-element selection throws
    throws_ok(
        sub { $root->find('//child')->single },
        qr/more than one current element/i,
        'single() on multi-element selection throws with clear error',
    );

    # single() on exactly one element succeeds
    my $one_child = $root->find('//child');
    $one_child->current_elements( [ $one_child->current_elements->[0] ] );
    my $elem = $one_child->single;
    isa_ok( $elem, 'XML::Chain::Element',
        'single() on 1-element selection returns Element' );
    is( $elem->name, 'child', 'single() element has correct name' );
};

subtest 'parent() stops at root element' => sub {
    my $root = xc( \'<root><child1><child2/></child1></root>' );
    is( $root->name, 'root', 'root element named root' );
    my $at_root = $root->parent;
    is( $at_root->name, 'root', 'parent() on root returns root unchanged' );
    my $still_at_root = $at_root->parent->parent;
    is( $still_at_root->name, 'root', 'multichained parent() stays at root' );
};

done_testing();
