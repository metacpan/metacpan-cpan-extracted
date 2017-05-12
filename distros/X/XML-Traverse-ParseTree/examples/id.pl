#!/usr/bin/perl
#
use strict;
use warnings;

use XML::Parser;
use XML::Traverse::ParseTree;

my $parsed = XML::Parser->new(Style => "Tree")->parsefile("id.xml");
my $h = XML::Traverse::ParseTree->new();

## convenience access functions

*lookup_id = create_id_lookup($h,$parsed,'person');
*name = $h->getter("name",'#TEXT');
*info = $h->getter("info",'#TEXT');
*idref = $h->getter('@idref');
*from = $h->getter('@from');
*to = $h->getter('@to');

## action dispatch table

my $dispatch = {
    scene => sub {  print $h->get($_[0],"#TEXT"),"\n"; },
    intro => sub {  print "There comes ",name(lookup_id(idref($_[0]))),"\n";
                    if(defined($h->get($_[0],'@info'))) {
                        print "(",info(lookup_id(idref($_[0]))),")\n";
                    }
            },
    talk => sub { print name(lookup_id(from($_[0]))), " talks to ", name(lookup_id(to($_[0]))),"\n"; },
    go => sub { print name(lookup_id(idref($_[0]))), " goes to ",to($_[0]),"\n" },
};

## process actions

my $actions = $h->get($parsed,"actions","*");

while (my $a = $actions->()) {
    my $an = $h->get_element_name($a);
    my $act = $dispatch->{$an};
    if (!ref($act)) {
        warn "hmm, $an is an unknown action! ";
        next;
    }
    $act->($a);
}

## end of main

sub create_id_lookup {
    my ($helper,$xml,$elemname) = @_;
    my $cache = {};
    my $i = $helper->get($xml,"//$elemname");

    while(my $e = $i->()) {
        my $id = $helper->get($e,'@id') or next;
        $cache->{$id} = $e;
    }

    sub { $cache->{$_[0]} }
}


