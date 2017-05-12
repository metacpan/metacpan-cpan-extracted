#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 14;
use Tree::Easy;

ok( my $tree = Tree::Easy->new('foo') );
is( $tree->data, 'foo' );
ok( $tree->npush('bar') );

ok( my $newtree = $tree->clone );

my @words;
$newtree->traverse( sub { push @words, shift->data } );
is( $words[0], 'bar' );
is( $words[1], 'foo' );

ok( my $barnode = $newtree->search( 'bar' ) );
is( $barnode->data, 'bar' );

my $hash_ref = { name => 'bar' };
$barnode->data( $hash_ref );
is( $barnode->data, $hash_ref );

ok( $newtree->search( sub { eval { shift->data->{name} eq 'bar' } } ));
is( $tree->search( sub { eval { shift->data->{name} eq 'bar' } } ),
    undef );
is( $newtree->get_height, 2 );

ok( my $lasttree = $newtree->clone );
$hash_ref->{name} =  'baz';
ok( $lasttree->search( sub { eval { shift->data->{name} eq 'bar' } } ));
