use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime');
use    perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime;
use perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::Start;
use perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new({
  'inclusive' =>  'value_inclusive',  'value' =>  'value_value',  'duration' =>  'value_duration',  'type' =>  'value_type',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('commonTime');
 ok($ns  eq 'nmwg', "  mapname('commonTime')...  ");
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
 my  $obj_start  = undef;
 eval {
      $obj_start  =  perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::Start->new({  'inclusive' =>  'valueinclusive',  'value' =>  'valuevalue',  'duration' =>  'valueduration',  'type' =>  'valuetype',});
    $obj1->start($obj_start);
   }; 
 ok( $obj_start && !$EVAL_ERROR , "Create subelement object start and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#9
 my  $obj_end  = undef;
 eval {
      $obj_end  =  perfSONAR_PS::Datatypes::v2_0::nmtm::Message::Data::CommonTime::End->new({  'inclusive' =>  'valueinclusive',  'value' =>  'valuevalue',  'duration' =>  'valueduration',  'type' =>  'valuetype',});
    $obj1->end($obj_end);
   }; 
 ok( $obj_end && !$EVAL_ERROR , "Create subelement object end and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#10
 my  $obj_datum  = undef;
 eval {
      $obj_datum  =  perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new({  'timeType' =>  'valuetimeType',  'ttl' =>  'valuettl',  'numBytes' =>  'valuenumBytes',  'value' =>  'valuevalue',  'name' =>  'valuename',  'valueUnits' =>  'valuevalueUnits',  'timeValue' =>  'valuetimeValue',  'seqNum' =>  'valueseqNum',});
    $obj1->addDatum($obj_datum);
  }; 
 ok( $obj_datum && !$EVAL_ERROR , "Create subelement object datum and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#11
 my $string = undef;
 eval {
      $string =  $obj1->asString 
 };
 ok($string   && !$EVAL_ERROR  , "  Converting to string XML:   $string " . $EVAL_ERROR);
 $EVAL_ERROR = undef;
#12
 my $obj22 = undef; 
 eval {
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#13
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
