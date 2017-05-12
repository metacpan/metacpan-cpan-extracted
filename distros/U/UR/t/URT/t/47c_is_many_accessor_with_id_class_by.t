#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 31;

class URT::Note {
    id_by => [
        id => { is => 'Number', len => 10 },
    ],
    has => [
        subject_class_name => { is => 'Text', len => 255 },
        subject_id         => { is => 'Text', len => 255 },
        subject            => { is => 'UR::Object', id_class_by => 'subject_class_name', id_by => 'subject_id' },
        editor_id          => { is => 'Text', len => 200 },
        entry_date         => { is => 'Date' },
        header_text        => { is => 'Text', len => 200 },
    ],
    has_optional => [
        body_text          => { is => 'Text', len => 1000 },
    ],
    id_generator => sub { our $note_seq; ++$note_seq },
};

class URT::Notable {
    is_abstract => 1,
    has => [
        notes => {
            is => 'URT::Note',
            is_many => 1,
            reverse_as => 'subject',
        },
    ],
};

class URT::Foo { is => 'URT::Notable', }; 

class URT::Bar { is => 'URT::Foo' };

class URT::Baz { is => 'URT::Foo' };

ok(URT::Foo->isa("URT::Notable"));

my $o1 = URT::Bar->create(100);
ok($o1, "created a test notable object");

my $o2 = URT::Baz->create(200);
ok($o2, "created another test notable object");

my @n;
my $n;

@n = $o1->notes;
is(scalar(@n),0,"no notes at start");

@n = $o2->notes;
is(scalar(@n),0,"no notes at start");

for my $o ($o1,$o2) {
    $n = $o->add_note(
        header_text => "head1",
        body_text => "body1",
    );
    ok($n, "added a note");
    is($n->header_text, 'head1', 'header is okay');
    is($n->body_text, 'body1', 'body is okay');
    #print Data::Dumper::Dumper($n);
    
    $n = $o->add_note(
        header_text => "head2",
        body_text => "body2",
    );
    ok($n, "added a note");
    is($n->header_text, 'head2', 'header is okay');
    is($n->body_text, 'body2', 'body is okay');
    #print Data::Dumper::Dumper($n);
};

for my $o ($o1,$o2) {
    my @n = $o->notes;
    is(scalar(@n),2,"got two notes for the object");
    for my $n (@n) {
        is($n->subject_class_name,ref($o),"class is set");
        is($n->subject_id,$o->id,"id is set");
        is($n->subject,$o,"object access works");
    }
}

1;

