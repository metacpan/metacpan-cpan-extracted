use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data');
use    perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime;
use perfSONAR_PS::Datatypes::v2_0::nmwgr::Message::Data::Datum;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::Datum;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({
  'metadataIdRef' =>  'value_metadataIdRef',  'id' =>  'value_id',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('data');
 ok($ns  eq 'nmwg', "  mapname('data')...  ");
#4
 my $metadataIdRef  =  $obj1->metadataIdRef;
 ok($metadataIdRef  eq 'value_metadataIdRef', " checking accessor  obj1->metadataIdRef ...  ");
#5
 my $id  =  $obj1->id;
 ok($id  eq 'value_id', " checking accessor  obj1->id ...  ");
#6
 my  $obj_commonTime  = undef;
 eval {
      $obj_commonTime  =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::CommonTime->new({  'inclusive' =>  'valueinclusive',  'value' =>  'valuevalue',  'duration' =>  'valueduration',  'type' =>  'valuetype',});
    $obj1->addCommonTime($obj_commonTime);
  }; 
 ok( $obj_commonTime && !$EVAL_ERROR , "Create subelement object commonTime and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#7
 my  $obj_datum  = undef;
 eval {
      $obj_datum  =  perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::Datum->new({  'timeType' =>  'valuetimeType',  'ttl' =>  'valuettl',  'numBytes' =>  'valuenumBytes',  'value' =>  'valuevalue',  'name' =>  'valuename',  'valueUnits' =>  'valuevalueUnits',  'timeValue' =>  'valuetimeValue',  'seqNum' =>  'valueseqNum',});
    $obj1->datum($obj_datum);
   }; 
 ok( $obj_datum && !$EVAL_ERROR , "Create subelement object datum and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#8
 my  $obj_key  = undef;
 eval {
      $obj_key  =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key->new({  'id' =>  'valueid',});
    $obj1->key($obj_key);
   }; 
 ok( $obj_key && !$EVAL_ERROR , "Create subelement object key and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#9
 my $string = undef;
 eval {
      $string =  $obj1->asString 
 };
 ok($string   && !$EVAL_ERROR  , "  Converting to string XML:   $string " . $EVAL_ERROR);
 $EVAL_ERROR = undef;
#10
 my $obj22 = undef; 
 eval {
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#11
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
