#! /usr/bin/perl

use strict;
use warnings;

use File::Spec::Functions qw<splitpath catdir catpath>;

use lib do {
    my ($vol, $dir, undef) = splitpath(__FILE__);
    catpath($vol, catdir($dir, 'lib'), '');
};

use Test::More 0.88;
use Test::Exception;

use ex::monkeypatched;

{
    my $class = 'Monkey::A';
    require_ok($class);
    ex::monkeypatched->inject($class => (
        m1 => sub { 'in patched Monkey::A m1' },
        m2 => sub { 'in patched Monkey::A m2' },
    ));
    my $obj = new_ok('Monkey::A', [], 'monkey-patched version');
    can_ok($obj, qw<meth_a m1 m2>);
}

{
    my $class = 'Monkey::B';
    require_ok($class);
    throws_ok { ex::monkeypatched->inject($class => (
        already_exists => sub { 'will fail' },
    )) } qr/^Can't monkey-patch: Monkey::B already has a method "\w+"/,
        'Refuse to post-hoc override a statically-defined method';
}

{
    my $class = 'Monkey::Nonexistent';
    ex::monkeypatched->inject($class, m3 => sub { 'in nonexistent m3' });
    throws_ok { my $obj = $class->new }
        qr/^Can't locate object method "new" via package "\Q$class\E"/,
            '->inject does not load the class';
}

done_testing();
