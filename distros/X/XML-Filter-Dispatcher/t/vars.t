#!/usr/local/lib/perl -w

use strict;

use Test;
use XML::SAX::PurePerl;
use XML::Filter::Dispatcher qw( :all );
use UNIVERSAL;

plan tests => 13;

my @log;

my $d = XML::Filter::Dispatcher->new(
    Rules => [
        "/"    => sub {
            xset_var a => string => "aaa";
            ok xget_var( "a" ), "aaa", "/ => xgetvar( a )";
        },
        "//foo" => sub {
            ok xget_var( "a" ), "aaa", "foo => xgetvar( a )";
            ok ! defined xget_var( "b" ), 1, "! defined foo => xgetvar( b )";
            xset_var b => string => "bbb";
            ok xget_var( "b" ), "bbb", "foo => xgetvar( b )";
        },
        "//bar" => sub {
            ok xget_var( "a" ), "aaa", "bar => xgetvar( a )";
            ok xget_var( "b" ), "bbb", "bar => xgetvar( b )";
        },
    ],
);

ok 1;

my $p = XML::SAX::PurePerl->new( Handler => $d );

ok 1;

$p->parse_string( "<root><foo><bar/></foo><foo><bar/></foo></root>" );

