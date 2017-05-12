#!perl

use strict;
use warnings;
use Test::More tests => 10;
use WWW::Lovefilm::API;
$|=1;

my $x = WWW::Lovefilm::API::_UrlAppender->new();

ok( $x, "got object" );
is( ref($x), 'WWW::Lovefilm::API::_UrlAppender', "got WWW::Lovefilm::API::_UrlAppender class" );
is( $x->{stack}, undef, "got stack" );
is_deeply( $x->{append}, {}, "got append" );


my $y = $x->Foo;
is( $x, $y, 'returned self' );
is_deeply( $x->{stack}, [qw/ foo /], "got stack: ".join('::',@{$x->{stack}}) );
$x->Bar;
is_deeply( $x->{stack}, [qw/ foo bar /], "got stack: ".join('::',@{$x->{stack}}) );
$x->More(123)->Stuff;
is_deeply( $x->{stack}, [qw/ foo bar more 123 stuff /], "got stack: ".join('::',@{$x->{stack}}) );



$x = WWW::Lovefilm::API::_UrlAppender->new( stack=>[qw/qwe asd/], append=>{foo=>456});
is_deeply( $x->{stack}, [qw/ qwe asd /], "got stack: ".join('::',@{$x->{stack}}) );
$x->foo->bar;
is_deeply( $x->{stack}, [qw/ qwe asd foo 456 bar /], "got stack: ".join('::',@{$x->{stack}}) );

