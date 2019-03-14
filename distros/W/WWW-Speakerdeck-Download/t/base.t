#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'WWW::Speakerdeck::Download';

my $o = WWW::Speakerdeck::Download->new(
    ua => Speakerdeck::UA->new,
);

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'mojolicious-test' );
    } or $error = $@;

    like $error, qr/cannot get deck .* Not Found/;
}

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'mojolicious-test', {} );
    } or $error = $@;

    like $error, qr/need plain path to target or Mojo::File/;
}

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'is-mojolicious-web-only', $o->ua );
    } or $error = $@;

    like $error, qr/need plain path to target or Mojo::File/;
}

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'mojolicious-test', './test.pdf' );
    } or $error = $@;

    like $error, qr/cannot get deck/;
}

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'no-icon' );
    } or $error = $@;

    like $error, qr/cannot download no-icon deck/;
}

{
    my $error = '';
    eval {
        $o->download( 'reneeb', 'test-exists' );
    } or $error = $@;

    like $error, qr/cannot download deck/;
}

{
    my $target = './test.pdf';
    my $error = '';
    eval {
        $o->download( 'reneeb', 'is-mojolicious-web-only', $target );
    } or $error = $@;

    is $error, '';

    ok -f $target;
    unlink $target;
}

{
    my $target = './mojo.pdf';
    my $error = '';
    eval {
        $o->download( 'reneeb', 'is-mojolicious-web-only' );
    } or $error = $@;

    is $error, '';

    ok -f $target;
    unlink $target;
}

done_testing();

{
    package # private package
        Speakerdeck::UA;

    use Mojo::Base 'Mojo::UserAgent';
    use Mojo::Message::Response;
    use Mojo::Transaction;
    use Mojo::File qw(path);

    sub get {
        my $self   = shift;
        my $url    = shift;

        my $basename = path( $url )->basename;
        my $response = path( __FILE__ )->sibling( 'data', $basename . '.response' )->slurp;

        my $res = Mojo::Message::Response->new->parse( $response );

        my $tx = Mojo::Transaction->new;
        $tx->res( $res );

        return $tx;
    }
}

