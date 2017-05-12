#!/usr/bin/env perl -w

use Test::More tests => 6;

use WebService::Simplenote::Note;
use DateTime;
use JSON;

my $date = DateTime->new(
    year  => 2012,
    month => 1,
    day   => 1,
);

my $note = WebService::Simplenote::Note->new(
    createdate => $date->epoch,
    modifydate => $date->epoch,
    content    => "# Some Content #\n This is a test",
);

ok( defined $note,                                'new() returns something' );
ok( $note->isa( 'WebService::Simplenote::Note' ), '... the correct class' );

cmp_ok( $note->title, 'eq', 'Some Content', 'Title is correct' );

ok( my $json_str       = $note->serialise,                               'Serialise note to JSON' );
ok( my $note_from_json = decode_json $json_str,                          '...JSON is valid' );
ok( my $note_thawed    = WebService::Simplenote::Note->new( $json_str ), '...can deserialise' );


