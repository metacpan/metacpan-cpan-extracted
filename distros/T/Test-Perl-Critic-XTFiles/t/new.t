#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Perl::Critic ();

use Test::Perl::Critic::XTFiles;

use constant CLASS => 'Test::Perl::Critic::XTFiles';

my $obj = CLASS()->new;
isa_ok( $obj, CLASS(), 'new returned object' );

my $critic = $obj->critic;
isa_ok( $critic, 'Perl::Critic', 'critic() returns a Perl::Critic object' );

my $critic_module = $obj->critic_module;
isa_ok( $critic_module, 'Perl::Critic', 'critic_module() returns a Perl::Critic object' );
ok( $critic == $critic_module, '... the same as was returned from critic()' );

my $critic_script = $obj->critic_script;
isa_ok( $critic_script, 'Perl::Critic', 'critic_script() returns a Perl::Critic object' );
ok( $critic == $critic_script, '... the same as was returned from critic()' );

my $critic_test = $obj->critic_test;
isa_ok( $critic_test, 'Perl::Critic', 'critic_test() returns a Perl::Critic object' );
ok( $critic == $critic_test, '... the same as was returned from critic()' );

$obj->critic( Perl::Critic->new );
$critic = $obj->critic;
isa_ok( $critic, 'Perl::Critic', 'critic can be used to set a new Perl::Critic object' );
ok( $critic != $critic_module, '... which differs now' );

my $critic_module2 = $obj->critic_module;
isa_ok( $critic_module2, 'Perl::Critic', 'critic_module() returns a Perl::Critic object' );
ok( $critic_module2 == $critic_module, '... the same as was returned before' );

my $pc = Perl::Critic->new;
$obj = CLASS()->new( critic => $pc );
isa_ok( $obj, CLASS(), 'new returned object' );

$critic = $obj->critic;
isa_ok( $critic, 'Perl::Critic', 'critic() returns a Perl::Critic object' );
ok( $critic == $pc, '... the one we passed to new' );

$critic_module = $obj->critic_module;
isa_ok( $critic_module, 'Perl::Critic', 'critic_module() returns a Perl::Critic object' );
ok( $critic == $critic_module, '... the same as was returned from critic()' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
