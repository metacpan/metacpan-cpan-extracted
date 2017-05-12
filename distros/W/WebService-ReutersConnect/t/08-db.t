#!perl -w
use strict;
use warnings;
use Test::More ;
use Test::Fatal qw/lives_ok/;
use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($WARN);

## This test depends on File::Share (not just File::ShareDir) to be there.
BEGIN{
  eval{ require File::Share; };
  if( $@ ){
    plan skip_all => 'Cannot load File::Share. Skipping' if $@;
  }
}


use WebService::ReutersConnect qw/:demo/;


ok( my $reuters = WebService::ReutersConnect->new( { username => $ENV{REUTERS_USERNAME} // REUTERS_DEMOUSER,
                                                     password => $ENV{REUTERS_PASSWORD} // REUTERS_DEMOPASSWORD,
                                                   }), "Ok build a reuters");

ok( my $schema = $reuters->schema() , "Ok can get DB schema from reuters");
ok( $schema->resultset('Concept') , "Ok can get Concept Resultset");
ok( $schema->resultset('ConceptAlias') , "Ok can get Concept Alias Resultset");
lives_ok{ return  $schema->resultset('Concept')->count() }  "Ok can count";
ok( $schema->resultset('Concept')->count() , "Ok got concepts in DB");
ok( my $concept = $reuters->_find_concept('A:1'), "Ok can find concept");
ok( $concept->name_main() , "Ok got name_main");
ok( $concept->name_mnemonic() , "Ok got name mnemonic");
ok( $concept->definition() , "Ok got definition");
cmp_ok( $concept->concept_aliases()->count() , '==' , 2 , "Ok this concept has two aliases");
foreach my $alias ( $concept->concept_aliases()->all() ){
  ok( my $aliased =  $reuters->_find_concept($alias->alias_id()), "Ok can find the same concept by alias");
  cmp_ok( $aliased->id() , 'eq' , $concept->id() , "Ok same id as original concept");
}
ok( $concept->broader() , "Ok got a broader concept");

ok( my @chain = $concept->broader_chain(), "Ok got broader chain");
diag(  join(' > ', map{ $_->name_main() } @chain ) );

ok( !$reuters->_find_concept(314159) , "No PI concept found");

done_testing();
