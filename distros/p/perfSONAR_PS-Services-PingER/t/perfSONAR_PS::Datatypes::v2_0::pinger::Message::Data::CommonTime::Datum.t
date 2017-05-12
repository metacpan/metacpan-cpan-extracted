use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum');
use    perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new({
  'timeType' =>  'value_timeType',  'ttl' =>  'value_ttl',  'numBytes' =>  'value_numBytes',  'value' =>  'value_value',  'name' =>  'value_name',  'valueUnits' =>  'value_valueUnits',  'timeValue' =>  'value_timeValue',  'seqNum' =>  'value_seqNum',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('datum');
 ok($ns  eq 'pinger', "  mapname('datum')...  ");
#4
 my $timeType  =  $obj1->timeType;
 ok($timeType  eq 'value_timeType', " checking accessor  obj1->timeType ...  ");
#5
 my $ttl  =  $obj1->ttl;
 ok($ttl  eq 'value_ttl', " checking accessor  obj1->ttl ...  ");
#6
 my $numBytes  =  $obj1->numBytes;
 ok($numBytes  eq 'value_numBytes', " checking accessor  obj1->numBytes ...  ");
#7
 my $value  =  $obj1->value;
 ok($value  eq 'value_value', " checking accessor  obj1->value ...  ");
#8
 my $name  =  $obj1->name;
 ok($name  eq 'value_name', " checking accessor  obj1->name ...  ");
#9
 my $valueUnits  =  $obj1->valueUnits;
 ok($valueUnits  eq 'value_valueUnits', " checking accessor  obj1->valueUnits ...  ");
#10
 my $timeValue  =  $obj1->timeValue;
 ok($timeValue  eq 'value_timeValue', " checking accessor  obj1->timeValue ...  ");
#11
 my $seqNum  =  $obj1->seqNum;
 ok($seqNum  eq 'value_seqNum', " checking accessor  obj1->seqNum ...  ");
#12
 my $string = undef;
 eval {
      $string =  $obj1->asString 
 };
 ok($string   && !$EVAL_ERROR  , "  Converting to string XML:   $string " . $EVAL_ERROR);
 $EVAL_ERROR = undef;
#13
 my $obj22 = undef; 
 eval {
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#14
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::pinger::Message::Data::CommonTime::Datum->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
