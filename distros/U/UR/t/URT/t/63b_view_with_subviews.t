#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use XML::LibXML";
eval "use XML::LibXSLT";
eval "use XML::Dumper";
if ($INC{"XML/LibXML.pm"} && $INC{'XML/LibXSLT.pm'} && $INC{'XML/Dumper.pm'}) {
    plan tests => 11;
}
else {
    plan skip_all => 'works only with systems which have XML::LibXML and XML::LibXSLT.pm';
}

#use File::Basename;
#use lib File::Basename::dirname(__FILE__)."/../..";

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
        cats    => { is => 'Cat', is_many => 1 },
    ]
};

class Cat {
    is => 'Animal',
    has => [
        fluf    => { is => 'Number' },
        owner   => { is => 'Person', id_by => 'owner_id' },
    ]
};

my $p = Person->create(name => 'Fester', age => 99);
    ok($p, "made a test person object to have cats");

my $c1 = Cat->create(name => 'fluffy', age => 2, owner => $p, fluf => 11);
    ok($c1, "made a test cat 1");

my $c2 = Cat->create(name => 'nestor', age => 8, owner => $p, fluf => 22);
    ok($c2, "made a test cat 2");

my @c = $p->cats();
is("@c","$c1 $c2", "got expected cat list for the owner");


my $pv = $p->create_view(
    toolkit => 'xml',
    aspects => [
        'name',
        'age',
        {
            name => 'cats',
            perspective => 'default',
            toolkit => 'xml',
            aspects => [
                'name',
                'age',
                'fluf',
                'owner'
            ],
        }
    ]
);
ok($pv, "got an XML view for the person");
my $pv_got_content = $pv->content;
ok($pv_got_content, 'Person XML view generated some content');

SKIP: {
    skip "Need a better way to validate XML output",1;
    my $pv_expected_xml = '';
    is($pv_got_content,$pv_expected_xml,"XML is as expected for the person view");
}

my $c1v = $c1->create_view(toolkit => 'text');
ok($c1v, 'Created text view for a cat');
ok($c1v, "got a text view for one of the cats");

my $c1v_expected_text = "Cat '" . $c1->id . "' age: 2 fluf: 11 name: fluffy owner: Person '" . $p->id . "' age: 99 cats: Cat '" . $c1->id . "' (REUSED ADDR) Cat '".$c2->id."' age: 8 fluf: 22 name: nestor owner: Person '".$p->id."' (REUSED ADDR) name: Fester";
my $c1v_got_content = $c1v->content;
ok($c1v_got_content, 'Cat text view generated some content');
chomp $c1v_got_content;
# Convert all whitespace to a single space
$c1v_got_content =~ s/\n/ /mg;
$c1v_got_content =~ s/\s+/ /mg;


is($c1v_got_content,$c1v_expected_text,"text is as expected for the cat view");

