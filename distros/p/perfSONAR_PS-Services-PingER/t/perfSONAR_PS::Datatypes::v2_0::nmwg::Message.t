use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmwg::Message');
use    perfSONAR_PS::Datatypes::v2_0::nmwg::Message;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data::Key::Parameters;
use perfSONAR_PS::Datatypes::v2_0::select::Message::Metadata::Parameters;
use perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject::Parameters;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata;
use perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmwg::Message->new({
  'type' =>  'value_type',  'id' =>  'value_id',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmwg::Message..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('message');
 ok($ns  eq 'nmwg', "  mapname('message')...  ");
#4
 my $type  =  $obj1->type;
 ok($type  eq 'value_type', " checking accessor  obj1->type ...  ");
#5
 my $id  =  $obj1->id;
 ok($id  eq 'value_id', " checking accessor  obj1->id ...  ");
#6
 my  $obj_parameters  = undef;
 eval {
      $obj_parameters  =  perfSONAR_PS::Datatypes::v2_0::pinger::Message::Metadata::Subject::Parameters->new({  'id' =>  'valueid',});
    $obj1->addParameters($obj_parameters);
  }; 
 ok( $obj_parameters && !$EVAL_ERROR , "Create subelement object parameters and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#7
 my  $obj_metadata  = undef;
 eval {
      $obj_metadata  =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Metadata->new({  'metadataIdRef' =>  'valuemetadataIdRef',  'id' =>  'valueid',});
    $obj1->addMetadata($obj_metadata);
  }; 
 ok( $obj_metadata && !$EVAL_ERROR , "Create subelement object metadata and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#8
 my  $obj_data  = undef;
 eval {
      $obj_data  =  perfSONAR_PS::Datatypes::v2_0::nmwg::Message::Data->new({  'metadataIdRef' =>  'valuemetadataIdRef',  'id' =>  'valueid',});
    $obj1->addData($obj_data);
  }; 
 ok( $obj_data && !$EVAL_ERROR , "Create subelement object data and set it  ..." . $EVAL_ERROR);
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
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#11
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmwg::Message->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
