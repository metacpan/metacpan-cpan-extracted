#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use XML::LibXML";
eval "use XML::LibXSLT";
eval "use XML::Dumper";
my $TEST_XML = 1;
unless ($INC{"XML/LibXML.pm"} && $INC{'XML/LibXSLT.pm'} && $INC{'XML/Dumper.pm'}) {
    $TEST_XML = undef;
}

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";

use above 'UR';

class Animal {
    has => [
        name    => { is => 'Text' },
        age     => { is => 'Number' },
    ]
};

class Person {
    is => 'Animal',
    has => [
        cats    => { is => 'Cat', is_many => 1, reverse_as => 'owner' },
        favorite_numbers => { is_many => 1 },
    ]
};

class Cat {
    is => 'Animal',
    has => [
        fluf    => { is => 'Number' },
        owner   => { is => 'Person', id_by => 'owner_id' },
        buddy   => { is => 'Cat', id_by => 'buddy_id', is_optional => 1 },
    ]
};

my $p = Person->create(id => 1001, name => 'Fester', age => 99, favorite_numbers => [2,4,7]);
    ok($p, "made a test person object to have cats");

my $c1 = Cat->create(id => 2001, name => 'fluffy', age => 2, owner => $p, fluf => 11);
    ok($c1, "made a test cat 1");

my $c2 = Cat->create(id => 2002, name => 'nestor', age => 8, owner => $p, fluf => 22, buddy => $c1);
    ok($c2, "made a test cat 2");

my @c = $p->cats();
is("@c","$c1 $c2", "got expected cat list for the owner");

#########

my @toolkits = $TEST_XML ? ( 'xml','text' ) : ( 'text' );
for my $toolkit (@toolkits) {

    note('view 1: no aspects');
    my $pv1 = $p->create_view(
        toolkit => $toolkit, 
        aspects => [ ]
    );
    ok($pv1, "got an XML view $pv1 for the object $p");

    my @a = $pv1->aspects();
    is(scalar(@a),0,"got expected aspect list @a")
        or diag(Data::Dumper::Dumper(@a));

    my @an = $pv1->aspect_names();
    is("@an","","got expected aspect list @an");


    #########

    note('view 2: simple aspects');
    my $pv2 = $p->create_view(
        toolkit => $toolkit, 
        aspects => [
            'name',
            'age',
            'cats',
        ]
    );
    ok($pv2, "got an XML view $pv2 for the object $p");

    @a = $pv2->aspects();
    is(scalar(@a),3,"got expected aspect list @a")
    or diag(Data::Dumper::Dumper(@a));

    @an = $pv2->aspect_names();
    is("@an","name age cats","got expected aspect list @an");

    #########

    note('view 3: aspects with properties');

    my $pv3 = $p->create_view(
        toolkit => $toolkit, 
        aspects => [
            { name => 'name', label => 'NAME' },
            'age',
            { 
                name => 'cats', 
                label => 'Kitties', 
            },
        ]
    );
    ok($pv3, "got an XML view $pv3 for the object $p");

    @a = $pv3->aspects();
    is(scalar(@a),3,"got expected aspect list @a")
    or diag(Data::Dumper::Dumper(@a));

    @an = $pv3->aspect_names();
    is("@an","name age cats","got expected aspect list @an");

    my $s = $pv3->subject;
    is($s, $p, "subject is the original model object");

    #$pv3->show;
    my $c = $pv3->content;
    note($c);
}

done_testing();
