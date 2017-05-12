#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use VS::RuleEngine::Declare;

use lib 't/lib';

use Test::VS::RuleEngine::Input;

my $input_obj = Test::VS::RuleEngine::Input->new();

my $engine = engine {
    input "input1" => instanceof "Test::VS::RuleEngine::Input";
    input "input2" => instanceof "Test::VS::RuleEngine::Input" => with_args {
        start => 10
    };
    
    input "input3" => does {
        1;
    };
    
    input "input4" => $input_obj;
};

ok($engine->has_input("input1"));
my $input = $engine->_get_input("input1");
ok(defined $input);
is($input->_pkg, "Test::VS::RuleEngine::Input");
is_deeply($input->_args, []);

ok($engine->has_input("input2"));
$input = $engine->_get_input("input2");
ok(defined $input);
is($input->_pkg, "Test::VS::RuleEngine::Input");
is_deeply($input->_args, [start => 10]);

ok($engine->has_input("input3"));
$input = $engine->_get_input("input3");
ok(defined $input);
is($input->_pkg, "VS::RuleEngine::Input::Perl");
is($input->_args->[0]->(), 1);

ok($engine->has_input("input4"));
$input = $engine->_get_input("input4");
ok(defined $input);
ok($input->_pkg == $input_obj);