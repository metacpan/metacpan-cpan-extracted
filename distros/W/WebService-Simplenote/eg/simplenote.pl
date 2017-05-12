#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use WebService::Simplenote;
use WebService::Simplenote::Note;
use Log::Dispatch;
use Log::Any::Adapter;

my $email    = shift;
my $password = shift;

my $logger = Log::Dispatch->new( outputs => [ [ 'Screen', min_level => 'debug', newline => 1 ], ], );
Log::Any::Adapter->set( 'Dispatch', dispatcher => $logger );

my $sn = WebService::Simplenote->new(
    email    => $email,
    password => $password,
);

my $notes = $sn->get_remote_index;

foreach my $note_id ( keys %$notes ) {
    my $note = $sn->get_note( $note_id );
    printf "[%s] %s\n\n", $note->modifydate->iso8601, $note->title;

    #$note->deleted(1);
    #$sn->delete_note($note);
}

my $new_note = WebService::Simplenote::Note->new( content => "Some stuff", );

#$sn->put_note( $new_note );
