use strict;
use Test::More tests => 11;

use Scalar::Util qw/ refaddr /;

BEGIN {
    use_ok( 'XML::XPathScript::Template' );
}


my $template = new XML::XPathScript::Template;

$template->set( 'groucho' => { pre => 'marx' } );
is( $template->{groucho}{pre}, 'marx', 'scalar assignment of set()' );

$template->set( [ qw/ foo bar / ] => { 'pre' => 'works' } );
is( $template->{bar}{pre}, 'works', "array assignment of set_template()" );

# copy()

$template->copy( 'foo' => 'feh' );
is( $template->{feh}{pre}, 'works', 'copy( $t1, $t2 )' );

$template->copy( 'foo' =>  [ qw/ fa fi / ] );
is( $template->{fa}{pre}, 'works', 'copy( $t1, \@t2 )' );

$template->set( 'foo' => { 'pre' => 'a', 'post' => 'b'  } );
$template->set( 'bar' => { 'pre' => 'c', 'post' => 'd'  } );
$template->copy( 'foo' => 'bar', [ 'pre' ] );
is( $template->{bar}{pre},  'a', 'copy()' );
is( $template->{bar}{post}, 'd', 'copy()' );

# alias
$template->alias( 'foo' => 'bar' );
is( refaddr($template->{foo}), refaddr($template->{bar}), 'alias()' );

$template->alias( 'foo' => [ qw/ bar baz / ] );
is( refaddr($template->{foo}) => refaddr($template->{baz}), 'alias()' );

# is_alias
ok( $template->is_alias( 'foo' ) == 2, 'is_alias()' );

# unalias
$template->unalias( 'foo' );
ok( !$template->is_alias( 'foo' ), 'unalias' );


