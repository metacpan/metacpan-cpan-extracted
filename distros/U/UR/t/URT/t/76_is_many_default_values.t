#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Data::Dumper;
use Test::More tests => 6;

class Spy {
    has => [
        name => { is => 'Text', default_value => 'James Bond', },
        aliases => { is => 'Text', is_many => 1, default_value => ['007', 'Bond', 'James Bond'], },
    ],
};

{ # Test Default Values
    my $spy = Spy->create();
    isa_ok($spy, 'Spy');
    ok($spy->name eq 'James Bond', "Spy's default name is correct");

    my $default_aliases = '007|Bond|James Bond';
    my $aliases = join('|', sort($spy->aliases));
    #print "Aliases: $aliases\nExpected Aliases: $default_aliases\n";
    ok($aliases eq $default_aliases, "Spy's default aliases are correct");
}

{ # Test Specified Values
    my $name = 'Margaretha Geertruida (Grietje) Zelle';
    my $alias = 'Mata Hari';
    my $spy = Spy->create(name => $name, aliases => [$alias]);
    isa_ok($spy, 'Spy');
    ok($spy->name eq $name, "Spy's name is correct");
    my $aliases = join('|', sort($spy->aliases));
    #print "Aliases: $aliases\nExpected Aliases: $alias\n";
    ok($aliases eq $alias, "Spy's aliases are correct");
}

{ # TODO: Test complex default values involving database bridges?
    ;
}

