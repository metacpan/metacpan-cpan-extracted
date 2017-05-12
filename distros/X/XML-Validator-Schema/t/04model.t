#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw(no_plan);
use XML::Validator::Schema;
use XML::Validator::Schema::ElementNode;
use XML::Validator::Schema::ModelNode;

# create test elements
my $foo = XML::Validator::Schema::ElementNode->parse(
           { Attributes => { '{}name' => { Value => 'foo' } } });
my $bar = XML::Validator::Schema::ElementNode->parse(
           { Attributes => { '{}name' => { Value => 'bar' } } });
my $baz = XML::Validator::Schema::ElementNode->parse(
           { Attributes => { '{}name' => { Value => 'baz' } } });

# foo contains a sequence of (bar, baz)
my $sequence = XML::Validator::Schema::ModelNode->parse({ LocalName => 'sequence' });
$foo->add_daughter($sequence);
$sequence->add_daughters($bar, $baz);
is($sequence->daughters(), 2);

# compile sequence into $foo
$sequence->compile();
is($foo->daughters, 2);
is(($foo->daughters())[0]->name, $bar->name);
is(($foo->daughters())[1]->name, $baz->name);
isa_ok($foo->{model}, 'XML::Validator::Schema::ModelNode');

# check the description
is($foo->{model}->{description}, "(bar,baz)");

# check a sequence of nodes against the model
eval { $foo->{model}->check_final_model('', ['bar', 'baz']) };
is($@, "");

eval { $foo->{model}->check_model('', ['bar']) };
is($@, "");

eval { $foo->{model}->check_final_model('', []) };
like($@, qr/do not match content model/);

eval { $foo->{model}->check_model('', ['baz']) };
like($@, qr/does not match content model/);


# foo contains a choice of (bar|baz)
my $choice = XML::Validator::Schema::ModelNode->parse({ LocalName => 'choice' });
$foo->clear_daughters();
$foo->{model} = undef;
$foo->add_daughter($choice);
$choice->add_daughters($baz, $bar);
is($choice->daughters(), 2);

# compile model into $foo
$choice->compile();
is($foo->daughters, 2);
is(($foo->daughters())[0]->name, $baz->name);
is(($foo->daughters())[1]->name, $bar->name);
isa_ok($foo->{model}, 'XML::Validator::Schema::ModelNode');

# check the description
is($foo->{model}->{description}, "(baz|bar)");

# check a sequence of nodes against the model
eval { $foo->{model}->check_final_model('', ['bar']) };
is($@, "");

eval { $foo->{model}->check_model('', ['baz']) };
is($@, "");

eval { $foo->{model}->check_final_model('', []) };
like($@, qr/do not match content model/);

eval { $foo->{model}->check_model('', ['bar', 'baz']) };
like($@, qr/does not match content model/);

# foo contains an 'all' of (bar&baz)
my $all = XML::Validator::Schema::ModelNode->parse({ LocalName => 'all' });
$foo->clear_daughters();
$foo->{model} = undef;
$foo->add_daughter($all);
$all->add_daughters($bar, $baz);
is($all->daughters(), 2);

# compile model into $foo
$all->compile();
is($foo->daughters, 2);
is(($foo->daughters())[0]->name, $bar->name);
is(($foo->daughters())[1]->name, $baz->name);
isa_ok($foo->{model}, 'XML::Validator::Schema::ModelNode');

# check the description
is($foo->{model}->{description}, "(bar&baz)");

# check a sequence of nodes against the model
eval { $foo->{model}->check_final_model('', ['bar', 'baz']) };
is($@, "");

eval { $foo->{model}->check_final_model('', ['baz', 'bar']) };
is($@, "");

eval { $foo->{model}->check_final_model('', []) };
like($@, qr/do not match content model/);

my $bang = XML::Validator::Schema::ElementNode->parse(
           { Attributes => { '{}name' => { Value => 'bang' } } });
my $bop = XML::Validator::Schema::ElementNode->parse(
           { Attributes => { '{}name' => { Value => 'bop' } } });


# foo contains a sequence with a choice of (bar,(bang|bop),baz)
$sequence = XML::Validator::Schema::ModelNode->parse({ LocalName => 'sequence' });
$foo->clear_daughters();
$foo->{model} = undef;
$foo->add_daughter($sequence);
$choice = XML::Validator::Schema::ModelNode->parse({ LocalName => 'choice' });
$choice->add_daughters($bang, $bop);
$sequence->add_daughters($bar, $choice, $baz);
is($sequence->daughters(), 3);

# compile sequence into $foo
$sequence->compile();

# all daughters should end up in $foo
is($foo->daughters, 4);

# check the description
is($foo->{model}->{description}, "(bar,(bang|bop),baz)");

# check a sequence of nodes against the model
eval { $foo->{model}->check_final_model('', ['bar', 'bang', 'baz']) };
is($@, "");

eval { $foo->{model}->check_final_model('', ['bar', 'bop', 'baz']) };
is($@, "");

eval { $foo->{model}->check_model('', ['bar']) };
is($@, "");

eval { $foo->{model}->check_model('', ['bar', 'bang']) };
is($@, "");

eval { $foo->{model}->check_final_model('', ['bar', 'bang', 'bop', 'baz']) };
like($@, qr/do not match content model/);

eval { $foo->{model}->check_model('', ['baz']) };
like($@, qr/does not match content model/);
