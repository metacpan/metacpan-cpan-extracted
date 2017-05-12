use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint');
use    perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint;
use perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint::Address;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint->new({
  'protocol' =>  'value_protocol',  'role' =>  'value_role',  'port' =>  'value_port',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('endPoint');
 ok($ns  eq 'nmtl4', "  mapname('endPoint')...  ");
#4
 my $protocol  =  $obj1->protocol;
 ok($protocol  eq 'value_protocol', " checking accessor  obj1->protocol ...  ");
#5
 my $role  =  $obj1->role;
 ok($role  eq 'value_role', " checking accessor  obj1->role ...  ");
#6
 my $port  =  $obj1->port;
 ok($port  eq 'value_port', " checking accessor  obj1->port ...  ");
#7
 my  $obj_address  = undef;
 eval {
      $obj_address  =  perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint::Address->new({  'value' =>  'valuevalue',  'type' =>  'valuetype',});
    $obj1->address($obj_address);
   }; 
 ok( $obj_address && !$EVAL_ERROR , "Create subelement object address and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#8
 my  $obj_interface  = undef;
 eval {
      $obj_interface  =  perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->new({  'id' =>  'valueid',  'interfaceIdRef' =>  'valueinterfaceIdRef',});
    $obj1->interface($obj_interface);
   }; 
 ok( $obj_interface && !$EVAL_ERROR , "Create subelement object interface and set it  ..." . $EVAL_ERROR);
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
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#11
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmtl4::Message::Metadata::Subject::EndPointPair::EndPoint->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
