#!/usr/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Tropo;
use Data::Dumper;

get '/' => sub {
    my $self = shift;

    my $tropo = Tropo->new;
    $tropo->say(
        'Willkommen bei WeekendsSale',
    );
    $tropo->ask( 
        'Bitte wählen geben Sie die Ziffer des Artikels ein', 
        choices => '[2 DIGITS]',
    );

    $tropo->on(
        event => 'continue',
        next  => 'http://localhost/continue',
    );

    $tropo->on(
        event => 'hangup',
        next  => 'http://localhost/hangup',
    );

    my $perl = $tropo->perl;
    $self->render( json => $perl );
};

get '/continue' => sub {
    my $self = shift;

    my $tropo_data = $self->req->json;
    # do whatever you want

    # you need to send 'true'
    $self->render( json => 'true' );
};

app->start;

