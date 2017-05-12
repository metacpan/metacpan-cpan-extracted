#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use XML::LibXML";
eval "use XML::LibXSLT";
eval "use XML::Dumper";
if ($INC{"XML/LibXML.pm"} && $INC{'XML/LibXSLT.pm'} && $INC{'XML/Dumper.pm'}) {
    plan tests => 8;
}
else {
    plan skip_all => 'works only with systems which have XML::LibXML and XML::LibXSLT';
}

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

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
ok($pv, "got an xml view for the person");
my $pv_got_content = $pv->content;

my $c1v = $c1->create_view(toolkit => 'xml');
ok($c1v, 'Created xml view for a cat');
ok($c1v, "got a xml view for one of the cats");
my $c1v_got_content = $c1v->content;
ok($c1v_got_content, 'Cat xml view generated some content');

UR::Context->current->rollback;

