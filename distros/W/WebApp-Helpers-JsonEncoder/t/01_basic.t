#!/usr/bin/env perl

use strict;
use warnings;


package MyTunes::Resource::CD;

use Moo;
with 'WebApp::Helpers::JsonEncoder';

has title      => (is => 'rw');
has artist     => (is => 'rw');
has genre      => (is => 'rw');
has is_touring => (is => 'rw');

sub to_json {
    my ($self) = @_;
    return $self->encode_json( {
        title      => $self->title,
        artist     => $self->artist,
        genre      => $self->genre,
        is_touring => $self->json_bool( $self->is_touring ),
    } );
}

sub from_json {
    my ($self, $request) = @_;
    my $data = $self->decode_json($request);
    for my $field (qw(title artist genre is_touring)) {
        $self->$field( $data->{ $field } );
    }

    return;
}


package main;

$INC{'MyTunes::Resource::CD.pm'} = __FILE__;



use Test::More;

{
    my %the_crab = (
        artist     => 'Black Crabbath',
        title      => 'Crabotage',
        genre      => 'heavy scuttle',
        is_touring => 1,
    );

    my $cd1 = MyTunes::Resource::CD->new({
        artist     => 'Black Crabbath',
        title      => 'Crabotage',
        genre      => 'heavy scuttle',
        is_touring => 1,
    });

    my $json = $cd1->to_json;

    my $cd2 = MyTunes::Resource::CD->new({});
    $cd2->from_json($json);

    for my $field (keys %the_crab) {
        is $cd1->$field(), $cd2->$field(), "Field: $field is the same";
    }

    like $json, qr/\Wis_touring\W:\s*true/, "'is_touring' fields saved as bool";
}


done_testing();
