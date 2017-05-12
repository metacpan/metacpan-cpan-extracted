#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use VS::RuleEngine::Constants;
use VS::RuleEngine::Data;
use VS::RuleEngine::Declare;

my $cnt = 0;

my $engine = engine {
    input "Foo1" => does {
        $cnt++;
        return $cnt;
    };
    
    input "Foo2" => does {
        my ($self, $input, $global, $local) = @_[KV_SELF, KV_INPUT, KV_GLOBAL, KV_LOCAL];
        
        isa_ok($self, "VS::RuleEngine::Input::Perl");
        isa_ok($input, "VS::RuleEngine::InputHandler");
        isa_ok($global, "VS::RuleEngine::Data");
        isa_ok($local, "VS::RuleEngine::Data");
        isnt($global, $local);        
    }
};

my $input = $engine->_input_handler;
is($input->get("Foo1"), 1);
is($input->get("Foo1"), 1);

throws_ok {
    $input->_clear();
} qr/You are not allowed to clear the input/;

{
    # Small trick because only VS::RuleEngine::Engine may clear inputs
    package VS::RuleEngine::Runloop;
    $input->_clear();
}

is($input->get("Foo1"), 2);
is($input->get("Foo1"), 2);

throws_ok {
    $input->set_global("global");
} qr/Not a VS::RuleEngine::Data instance/;

throws_ok {
    $input->set_local("local");
} qr/Not a VS::RuleEngine::Data instance/;

lives_ok {
    $input->set_global(VS::RuleEngine::Data->new());    
};

lives_ok {
    $input->set_local(VS::RuleEngine::Data->new());    
};

$input->get("Foo2");