#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'Translate::Fluent' ) || print "Bail out!\n";
}

my $path = $0;
$path =~ s{t/.*.t}{test_files/basic.flt};

my $resource_set = Translate::Fluent::Parser::parse_file( $path );
ok( $resource_set, "Defined resource_set");

BAIL_OUT("Undefined resource_set")
  unless $resource_set;

isa_ok( $resource_set, "Translate::Fluent::ResourceSet");

my $resource_group = Translate::Fluent::ResourceGroup->new();
$resource_group->add_resource_set( $resource_set );

my $fullname = $resource_group->translate("fullname");
is( $fullname, 'theMage Merlin mage dude', "Got a proper fullname");

my $pi = $resource_group->translate('math-pi');
is( $pi, '3.1415', "We have got pi: $pi");

my $piv = $resource_group->translate('math-value-of-pi', {});
is( $piv, 'The value of constant pi is 3.1415', "We have got it: [$piv]");

my $no_message = $resource_group->translate('math-constant',
                  {name => 'pi', value => '42'}
                );
is( $no_message, undef, 'should not get a translation of a term');

my $missing = $resource_group->translate('this-is-no-resource-at-all');
is( $missing, undef, 'should not get a translation of a missing resource');


my $term    = $resource_group->get_term('math-constant');
isa_ok( $term, "Translate::Fluent::Elements::Term");

my $no_term = $resource_group->get_term('math-value-of-pi');
is($no_term, undef, 'should not get a message when asking for a term');

my $dreams  = $resource_group->translate('compose-dreams');
is( $dreams, "They don't know and they don't dream; that the dreams controls life; every time a man dreams...", 'compose dreams from message and message attributes' );

my $whole_dream = $resource_group->translate('whole-dream');
like($whole_dream, qr{dreams\nThat.*infant}smx, 'multiple block tests');


# Target a missing language
$fullname = $resource_group->translate("fullname", undef, {language => 'fr'});
is( $fullname, 'theMage Merlin mage dude', "Got a proper fullname");

$pi = $resource_group->translate('math-pi', undef, {language=>'fr'});
is( $pi, '3.1415', "We have got pi: $pi");

$piv = $resource_group->translate('math-value-of-pi', {}, {language=>'fr'});
is( $piv, 'The value of constant pi is 3.1415', "We have got it: [$piv]");

done_testing();
