#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use UR;

package Foo;

class Foo { 
    id_by => ['a'],
    #has => ['b','c', 'd' => { calculate_from => ['b','c'], calculate => q|$b+$c| }] 
    has => [qw/a b c/],
}; 

sub __load__ { 
    return 
        ['id', 'a', 'b', 'c'], 
        [ 
            ['a1', 'a1', 'b1', 'c1'], 
            ['a2', 'a2', 'b2', 'c2'], 
            ['a3', 'a3', 'b3', 'c3'], 
        ] 
};


package main;

use Test::More tests=> 16;

my $o1 = Foo->get('a2');
ok($o1, "got object 2 back");
is($o1->id, 'a2', 'id is correct');
is($o1->a, 'a2', 'property a is correct');
is($o1->b, 'b2', 'property b is correct');
is($o1->c, 'c2', 'property c is correct');

my @o = Foo->get();
is(scalar(@o), 3, "got objects back");

package Bar;

class Bar {
    id_by => 'a',
    has => [qw/a b c/]
};

my $data_set_size = 100_000;

sub __load__ {
    my $props = ['id','a','b','c'];

    my $data = IO::File->new("yes abcdefg| head -n $data_set_size |"); 
    my $n = 0;
    my $iterator = sub {
        my $v = $data->getline;
        if (not defined $v) {
            $data->close();
            return;
        }
        chomp $v;
        $n++;
        return [$n,$n,$v,$v];
    };
    
    return ($props, $iterator);
}

package main;

my $i = Bar->create_iterator();
my $n = 0;
while (my $o = $i->next()) {
    $n++;
    if ($n % 10_000 == 0) {
        ok(1,"processed $n");
    }
}



