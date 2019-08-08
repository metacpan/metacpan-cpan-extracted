#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Pod::Simple::SimpleTree;

use Test::Pod::Links;

main();

sub main {
    my $class = 'Test::Pod::Links';

    {
        my $obj  = $class->new;
        my $tree = Pod::Simple::SimpleTree->new->parse_file('corpus/1_link_web.pod')->root;

        my @links = $obj->_extract_links_from_pod($tree);
        is( scalar @links, 1, '_extract_links_from_pod returns 1 link' );

        is( ref $links[0], ref {}, '... in a hash' );
        ok( exists $links[0]->{to}, q{... with a 'to' key} );
        isa_ok( $links[0]->{to}, 'Pod::Simple::LinkSection' );
        is( ${ $links[0]->{to} }[2], 'https://www.perl.com/', '... pointing to the correct target' );
    }

    {
        my $obj  = $class->new;
        my $tree = Pod::Simple::SimpleTree->new->parse_file('corpus/1_link_non_web.pod')->root;

        my @links = $obj->_extract_links_from_pod($tree);
        is( scalar @links, 1, '_extract_links_from_pod returns 1 link' );

        is( ref $links[0], ref {}, '... element 1 is a hash' );
        ok( exists $links[0]->{to}, q{... with a 'to' key} );
        isa_ok( $links[0]->{to}, 'Pod::Simple::LinkSection' );
        is( ${ $links[0]->{to} }[2], 'Test::Pod::Links', '... pointing to the correct target' );
    }

    {
        my $obj  = $class->new;
        my $tree = Pod::Simple::SimpleTree->new->parse_file('corpus/7_links.pod')->root;

        my @links = $obj->_extract_links_from_pod($tree);
        my $elems = 7;
        is( scalar @links, $elems, '_extract_links_from_pod returns 6 link' );

        my @expected = qw(
          Test::Pod::Links
          https://www.perl.com/
          Test::Pod::Links
          https://www.perl.com/
          Test::Pod::Links
          https://www.perl.com/
          Test::Pod::Links
        );

        for my $i ( 0 .. ( $elems - 1 ) ) {
            is( ref $links[$i], ref {}, "... element $i is a hash" );
            ok( exists $links[$i]->{to}, q{... with a 'to' key} );
            isa_ok( $links[$i]->{to}, 'Pod::Simple::LinkSection' );
            is( ${ $links[$i]->{to} }[2], $expected[$i], "... pointing to the correct target ($expected[$i])" );
        }
    }

    {
        my $obj = $class->new;

        like( exception { $obj->_extract_links_from_pod(); }, qr{usage: _extract_links_from_pod[(]\[ elementname, \\[%]attributes, [.][.][.]subnodes[.][.][.] \][)]}, '_extract_links_from_pod throws an exception if called with to few arguments' );
        like( exception { $obj->_extract_links_from_pod( 1, 2 ); }, qr{usage: _extract_links_from_pod[(]\[ elementname, \\[%]attributes, [.][.][.]subnodes[.][.][.] \][)]}, '_extract_links_from_pod throws an exception if called with to many arguments' );
        like( exception { $obj->_extract_links_from_pod(1); },     qr{usage: _extract_links_from_pod[(]\[ elementname, \\[%]attributes, [.][.][.]subnodes[.][.][.] \][)]}, '_extract_links_from_pod throws an exception if called with incorrect arguments' );
        like( exception { $obj->_extract_links_from_pod( [1] ); }, qr{usage: _extract_links_from_pod[(]\[ elementname, \\[%]attributes, [.][.][.]subnodes[.][.][.] \][)]}, '_extract_links_from_pod throws an exception if called with incorrect arguments' );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
