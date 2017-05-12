#!/usr/bin/perl -w
# @(#) $Id: XML-Genx.t 903 2004-12-04 19:22:09Z dom $

use strict;
use warnings;

use Test::More tests => 11;

use_ok( 'XML::Genx::Simple' );

my $w = XML::Genx::Simple->new();
isa_ok( $w, 'XML::Genx' );
can_ok( $w, qw( Element StartDocString GetDocString ) );

my $out = '';
eval {
    $w->StartDocSender( sub { $out .= $_[0] } );
    $w->StartElementLiteral( 'root' );
    $w->Element( foo => 'bar', id => 1 );
    $w->Element( foo => 'baz', id => 2 );
    $w->EndElement;
    $w->EndDocument;
};
is( $@, '', 'That went well.' );
is( $out, '<root><foo id="1">bar</foo><foo id="2">baz</foo></root>',
    'Element()' );

#---------------------------------------------------------------------

my $warn;
eval {
    local $SIG{__WARN__} = sub { $warn = "@_" };
    $w->StartDocString;
    $w->StartElementLiteral('foo');
    $w->AddText('bar');
    $w->EndElement;
    $w->EndDocument;
};
is( $@, '', 'That went well too' );
is( $w->GetDocString, '<foo>bar</foo>', 'StartDocString()' );
is( $warn, undef, 'StartDocString() no warnings' );

#---------------------------------------------------------------------

my $w2 = XML::Genx::Simple->new();
is( $w2->GetDocString, undef, 'GetDocString() returns undef before use' );

#---------------------------------------------------------------------

# Check that Element can handle predefined element objects.
eval {
    $w->StartDocString;
    my $el = $w->DeclareElement( 'foo' );
    $w->Element( $el, 'bar' );
    $w->EndDocument;
};
is( $@, '', "Predeclared Element did not grumble" );
is( $w->GetDocString, '<foo>bar</foo>', ' ... and produced the right output.' );

# vim: set ai et sw=4 syntax=perl :
