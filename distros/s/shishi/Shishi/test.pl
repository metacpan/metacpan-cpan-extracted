# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 17 };
use Shishi;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok(defined SHISHI_MATCH_TOKEN());
ok(defined SHISHI_MATCH_CHAR());

my $d = Shishi::Decision->new;
ok($d);
$d->type("text");
ok($d->type == SHISHI_MATCH_TEXT);

$d->action("continue");
ok($d->type == SHISHI_ACTION_CONTINUE);

$d->text("This is a text");
ok($d->text() eq "This is a text");

$d->type("char");
ok($d->type == SHISHI_MATCH_CHAR);

$d->token("a");
ok($d->token() == ord"a");

{
my $foo = Shishi->new("Test");
my $x = Shishi::Node->new("Some node");
my $y = Shishi::Node->new("Another node");
my $end = Shishi::Decision->new(type => "true", action=>"finish");

$foo->add_node($x);
$x->add_decision($d);
$d->next_node($y);
$foo->add_node($y);
$y->add_decision($end);

my $m = Shishi->new_match("ab");
ok($d->token() == ord"a");
#ok($foo->execute($m));
}

ok(1);

{
my $foo = Shishi->new("Test");
my $nodec = Shishi::Node->new("C")->add_decision(
        new Shishi::Decision(target => 'c', type => 'char', action => 'finish')
);
my $nodeb = Shishi::Node->new("B")->add_decision(
        new Shishi::Decision(target => 'b', type => 'char', action => 'continue',
        next_node=>$nodec));
my $nodea = Shishi::Node->new("start");
$foo->add_node($nodea);

$foo->start_node->add_decision(
 new Shishi::Decision(target => 'a', type => 'char', action => 'continue',
                          next_node => $nodeb)
);
$foo->add_node($nodeb);
$foo->add_node($nodec);
ok(!$foo->execute(Shishi->new_match("ab")));
ok($foo->execute(Shishi->new_match("abc")));

ok(!$foo->execute(Shishi->new_match("babdabc")));

$foo->start_node->add_decision(
 new Shishi::Decision(type => 'skip', next_node => $foo->start_node,
 action => 'continue')
);
ok($foo->execute(Shishi->new_match("babdabc")));


}
{
my $foo = new Shishi ("code test");
my $nodea = Shishi::Node->new("start");
$foo->add_node($nodea);
my $d = new Shishi::Decision(type  => "code", action => 'finish');
$d->code(sub{ok(1); 0;});
$nodea->add_decision($d);
ok(!$foo->execute(Shishi->new_match("a")));
}
