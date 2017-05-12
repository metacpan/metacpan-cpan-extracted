use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use English qw( -no_match_vars);
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface');
use    perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress;
use perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IfAddress;
Log::Log4perl->init("logger.conf"); 

my $obj1 = undef;
#2
eval {
$obj1 = perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->new({
  'id' =>  'value_id',  'interfaceIdRef' =>  'value_interfaceIdRef',})
};
  ok( $obj1  && !$EVAL_ERROR , "Create object perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#3
 my $ns  =  $obj1->nsmap->mapname('interface');
 ok($ns  eq 'nmtl3', "  mapname('interface')...  ");
#4
 my $id  =  $obj1->id;
 ok($id  eq 'value_id', " checking accessor  obj1->id ...  ");
#5
 my $interfaceIdRef  =  $obj1->interfaceIdRef;
 ok($interfaceIdRef  eq 'value_interfaceIdRef', " checking accessor  obj1->interfaceIdRef ...  ");
#6
 my  $obj_ipAddress  = undef;
 eval {
      $obj_ipAddress  =  perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IpAddress->new({  'value' =>  'valuevalue',  'type' =>  'valuetype',});
    $obj1->ipAddress($obj_ipAddress);
   }; 
 ok( $obj_ipAddress && !$EVAL_ERROR , "Create subelement object ipAddress and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
#7
 my  $obj_ifAddress  = undef;
 eval {
      $obj_ifAddress  =  perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface::IfAddress->new({  'value' =>  'valuevalue',  'type' =>  'valuetype',});
    $obj1->ifAddress($obj_ifAddress);
   }; 
 ok( $obj_ifAddress && !$EVAL_ERROR , "Create subelement object ifAddress and set it  ..." . $EVAL_ERROR);
  $EVAL_ERROR = undef; 
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
    $obj22   =   perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->new({xml => $string});
 };
 ok( $obj22  && !$EVAL_ERROR , "  re-create object from XML string:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
#10
 my $dom1 = $obj1->getDOM();
 my $obj2 = undef; 
 eval {
    $obj2   =   perfSONAR_PS::Datatypes::v2_0::nmtl3::Message::Metadata::Subject::EndPointPair::EndPoint::Interface->new($dom1);
 };
 ok( $obj2  && !$EVAL_ERROR , "  re-create object from DOM XML:  ".   $EVAL_ERROR);
 $EVAL_ERROR = undef;
