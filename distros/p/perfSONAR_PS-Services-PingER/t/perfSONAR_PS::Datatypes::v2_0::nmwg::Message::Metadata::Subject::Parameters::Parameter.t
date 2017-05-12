use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter');
use    perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter->new({
  'value' =>  'value_value',  'name' =>  'value_name',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('parameter');
 ok($ns  eq 'nmwg', "  mapname('parameter')...  ");
#4
 my $value  =  $obj1->value;
 ok($value  eq 'value_value', " checking accessor  obj1->value ...  ");
#5
 my $name  =  $obj1->name;
 ok($name  eq 'value_name', " checking accessor  obj1->name ...  ");
#6
 my $string = undef;
 eval {
      $string =  $obj1->asString 
 };
 ok($string   && !$EVAL_ERROR  , "  Converting to string XML:   $string " . $EVAL_ERROR);
 $EVAL_ERROR = undef;
#7
 my $obj22 = undef; 
 eval {
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#8
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata::Subject::Parameters::Parameter->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
