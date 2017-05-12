use strict;
$^W=1;

use Test::More tests => 27;

use XML::Tiny::DOM;

my $c = XML::Tiny::DOM->new('t/rsnapshot.conf.xml');

ok($c->isa('XML::Tiny::DOM::Element'), "instantiate an object");

diag "basic accessors";
ok($c->configversion eq '2.0', "get attrib of root node");
ok($c->snapshotroot->isa('XML::Tiny::DOM::Element'),
  "child nodes are also objects");
ok($c->snapshotroot->nocreateroot == 1, "attrib of child node");
ok($c->externalprograms->cp->binary eq '/bin/cp', "attribs work on deeply nested nodes");

diag "overloading";
ok(''.$c->snapshotroot eq '/.snapshots/', "objects stringify");
eval { no warnings; ''.$c->externalprograms() };
ok($@, "... but not if they contain other nodes");

ok($c->snapshotroot, "bool overloading works");
ok(''.$c->externalprograms->rsync->shortargs->arg eq '-a', "stringification works");
ok($c->externalprograms->rsync->shortargs->arg eq '-a', "stringy equality checks work");
ok(!($c->externalprograms->rsync->shortargs->arg eq $c->snapshotroot), "... and say 'no' when they should");
ok($c->externalprograms->rsync->shortargs->arg ne '-b', "stringy inequality checks work");

ok($c->externalprograms->rsync->longargs->arg(3) lt $c->externalprograms->rsync->longargs->arg(1), "'less than' works for two objects");
ok($c->externalprograms->rsync->longargs->arg(3) lt '--numeric-ids', "... and for an object and a scalar");
ok('--delete-excluded' lt $c->externalprograms->rsync->longargs->arg(1), "... and for a scalar and an object (reversed params)");

ok($c->externalprograms->rsync->longargs->arg(1) gt $c->externalprograms->rsync->longargs->arg(3), "'greater than' works");
ok(!($c->externalprograms->rsync->longargs->arg(3) gt $c->externalprograms->rsync->longargs->arg(1)), "... and it says 'no' when it should");

is_deeply(
    [sort { $a cmp $b } qw(--delete --numeric-ids --relative --delete-excluded)],
    [map { ''.$_ } sort { $a cmp $b } $c->externalprograms->rsync->longargs->arg('*')],
    "cmp works"
);

diag "repeated child nodes";
ok($c->intervals->interval(0)->name eq 'alpha', "can get an individual child which exists several times");
ok($c->intervals->interval(2)->name eq 'gamma', "... and not just the first of 'em!");
eval { $c->intervals->interval(4); };
ok($@, "... but not if there's not enough children");

my @intervals = $c->intervals->interval('*');
ok($intervals[0]->name eq 'alpha' && $intervals[1]->name eq 'beta' &&
   $intervals[2]->name eq 'gamma' && $intervals[3]->name eq 'delta',
    "can get all child nodes as objects");

ok(($c->intervals->interval('beta'))[0]->retain == 7,
    "can get a named child node");

diag "bouncing up and down the tree";
ok($c->externalprograms->rsync->_parent->_parent->intervals->interval(0)->_parent->interval(2)->name eq 'gamma', "_parent works");

eval { $c->externalprograms->_parent->_parent; };
ok($@, "... but not for the root node");

eval 'use Scalar::Util qw(refaddr)';
SKIP: {
    skip("Scalar::Util not available", 2) if($@);
    ok(refaddr($c) eq refaddr($c->externalprograms->_parent),
        "_parent really returns the parent object and not a copy");
    ok(refaddr($c) eq refaddr($c->externalprograms->rsync->_root),
        "_root() works");
};
