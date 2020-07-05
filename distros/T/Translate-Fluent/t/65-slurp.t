#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'Translate::Fluent' ) || print "Bail out!\n";
}

my $path = $0;
$path =~ s{t/.*.t}{test_files/slurp};


my $resource_group = Translate::Fluent::ResourceGroup->slurp_directory( $path );
isa_ok($resource_group, "Translate::Fluent::ResourceGroup");

my $ptbr = $resource_group->translate(
                  'my-language',
                  {},
                  { language => 'pt-br' }
              );
is( $ptbr, 'Português do Brasil', 'pt-br');

my $ptpt = $resource_group->translate(
                  'my-language',
                  {},
                  { language => 'pt-pt' }
              );
is( $ptpt, 'Português', 'pt-pt');

my $enus = $resource_group->translate(
                  'my-language',
                  {},
                  { language => 'en-us' }
              );
is( $enus, 'English', 'en-us');

# Random language that doesn't exist/have translation
# should default to default_language = 'en'
my $exfi = $resource_group->translate(
                  'my-language',
                  {},
                  { language => 'ex-fi' } 
              );
is( $exfi, 'English', 'ex-fi');

my $exfi2 = $resource_group->translate(
                  'my-unfound-language',
                  {},
                  { language => 'ex-fi' } 
              );
is( $exfi2, 'Just a Dev String', 'unfound-language');


done_testing();
