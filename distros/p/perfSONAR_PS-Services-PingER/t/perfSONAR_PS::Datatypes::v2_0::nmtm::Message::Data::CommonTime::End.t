use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End');
use    perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End->new({
  'inclusive' =>  'value_inclusive',  'value' =>  'value_value',  'duration' =>  'value_duration',  'type' =>  'value_type',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('end');
 ok($ns  eq 'nmtm', "  mapname('end')...  ");
#4
 my $inclusive  =  $obj1->inclusive;
 ok($inclusive  eq 'value_inclusive', " checking accessor  obj1->inclusive ...  ");
#5
 my $value  =  $obj1->value;
 ok($value  eq 'value_value', " checking accessor  obj1->value ...  ");
#6
 my $duration  =  $obj1->duration;
 ok($duration  eq 'value_duration', " checking accessor  obj1->duration ...  ");
#7
 my $type  =  $obj1->type;
 ok($type  eq 'value_type', " checking accessor  obj1->type ...  ");
#8
 my $string = undef;
 eval {
      $string =  $obj1->asString 
 };
 ok($string   && !$EVAL_ERROR  , "  Converting to string XML:   $string " . $EVAL_ERROR);
 $EVAL_ERROR = undef;
#9
 my $obj22 = undef; 
 eval {
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#10
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
