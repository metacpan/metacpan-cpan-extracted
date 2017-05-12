#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw( :chomp );

my $o = sub {
    my @args = @_;
    return Text::Template::Simple->new( @args );
};

ok( my $t     = $o->(), 'Got the object');
ok( my $pre   = $o->( pre_chomp  => CHOMP_ALL    ), 'Got the object (pre)');
ok( my $post  = $o->( post_chomp => CHOMP_ALL    ), 'Got the object (post)');
ok( my $prec  = $o->( pre_chomp  => COLLAPSE_ALL ), 'Got the object (prec)');
ok( my $postc = $o->( post_chomp => COLLAPSE_ALL ), 'Got the object (postc)');
ok( my $both  = $o->( pre_chomp  => CHOMP_ALL,
                      post_chomp => CHOMP_ALL    ), 'Got the object (both)');
ok( my $bothc = $o->( pre_chomp  => COLLAPSE_ALL,
                      post_chomp => COLLAPSE_ALL ), 'Got the object (bothc)');

my $test = <<'THIS';
BU
<%=~ 'R' ~%>
AK
<%- my $z -%>
FF
THIS

ok( my $got = $t->compile( $test ), 'Compile' );
is( $got, "BU R AKFF\n", 'Test return value' );

is( $t->compile(     q{| <%-  %> |})    , q{| |}  , 'Chomping 1'  );
is( $t->compile(     q{| <%- -%> |})    , q{||}   , 'Chomping 2'  );
is( $t->compile(    qq{|\n <%~  %> |})  , q{|  |} , 'Chomping 3'  );
is( $t->compile(    qq{|\n <%~ ~%> \n|}), q{|  |} , 'Chomping 4'  );
is( $t->compile(    qq{|\n <%~  -%> |}) , q{| |}  , 'Chomping 5'  );
is( $t->compile(    qq{|\n <%- ~%> \n|}), q{| |}  , 'Chomping 6'  );

is( $pre->compile(   q{| <%  %> |})     , q{| |}  , 'Chomping 7'  );
is( $post->compile(  q{| <%  %> |})     , q{| |}  , 'Chomping 8'  );
is( $prec->compile(  q{|  <%  %>  |})   , q{|   |}, 'Chomping 9'  );
is( $postc->compile( q{|  <%  %>  |})   , q{|   |}, 'Chomping 10' );
is( $both->compile(  q{| <%  %> |})     , q{||}   , 'Chomping 11' );
is( $bothc->compile( q{|  <%  %>  |})   , q{|  |} , 'Chomping 12' );

# TODO: this test currently does not cover the full chomping interface
