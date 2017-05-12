#!/usr/bin/perl
# $File: //member/autrijus/WWW-REST/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 8518 $ $DateTime: 2003/10/21 07:12:23 $

use FindBin;
use Test::More ();
use Socket;

my $can_connect = Socket::inet_aton('www.example.com');
Test::More->import(
    $can_connect ? ( tests => 20 ) : ( skip_all => "Cannot connect" )
);
exit unless $can_connect;

push @INC, "$FindBin::Bin/../lib";

use_ok('WWW::REST');
my $url = WWW::REST->new('http://www.example.com/');
$url->dispatch(sub { ok(defined($_[0]->content), 'dispatched' ) });

foreach my $method (qw( get head put trace options delete post )) {
    ok( $url->can($method)->( $url, foo => 'bar' ), "...$method" );
}

my $url2 = $url->url('test/index.html');
is( $url2->as_string, 'http://www.example.com/test/index.html', '$url->url' );

my $url3 = $url2->dir;
is( $url3->as_string, 'http://www.example.com/test/', '$url->dir' );
is( $url3->dir->as_string, 'http://www.example.com/test/', '$dir->dir' );
is( $url3->parent->as_string, 'http://www.example.com/', '$dir->parent' );
is( $url3->url('index.html')->as_string, $url2->as_string, '$dir->url' );

__END__
