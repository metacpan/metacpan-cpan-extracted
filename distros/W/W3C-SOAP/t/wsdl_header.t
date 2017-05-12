#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::WSDL::Parser;
use lib path($0)->parent->child('lib').'';
use MechMock;

my $dir = path($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->child('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
my $ua = MechMock->new;
# create the parser object
my $parser = W3C::SOAP::WSDL::Parser->new(
    location      => $dir->child('in_header.wsdl').'',
    module        => 'MyApp::Headers',
    template      => $template,
    lib           => $dir->child('lib').'',
    ns_module_map => {
        'urn:HeaderTest'     => 'MyApp::HeaderTest',
    },
);

parser();

ok $parser, "Got a parser object";
isa_ok $parser->document, "W3C::SOAP::WSDL::Document", 'document';
is $parser->document->target_namespace, 'urn:HeaderTest', "Get target namespace";
is scalar( @{ $parser->document->messages }      ),3,"got the right number of messages";
ok scalar( @{ $parser->document->schemas }  ), "Got some schemas";
ok scalar( @{ $parser->document->port_types } ), "Got some port types";
ok scalar(@{ $parser->document->services }), "got some services";

my $service = $parser->document->services->[0];
is $service->name, "HeaderTestService", "got the service expected";
ok scalar(@{$service->ports}), "Got some ports";
my $port = $service->ports->[0];
is $port->name, "HeaderTestSoap", "got the right port";
ok scalar(@{ $port->binding->operations }), "got some operations";
my $operation = $port->binding->operations->[0];
isa_ok $operation, "W3C::SOAP::WSDL::Document::Operation", 'operation';
is $operation->name, "OpGet", "and got the right operation";
is $operation->action(), 'urn:HeaderTest/OpGet', "got the right action";
is $operation->style(), 'document',"got the right style";


ok scalar(@{$operation->inputs}), "got some inputs";
my $input = $operation->port_type->inputs->[0];


isa_ok $input, "W3C::SOAP::WSDL::Document::InOutPuts";
ok $input->message, "got message";


ok $input->header, "got a header";
isa_ok $input->header, 'W3C::SOAP::WSDL::Document::Message', 'header';

is $input->header->element->perl_name, 'authentication_info', "got the perl name we expected";

ok my $class_name = $parser->dynamic_classes(), "dynamic_classes";

ok my $object = $class_name->new(), "make an object";

can_ok $object, 'op_get';

ok my $meth = $object->meta()->get_method('op_get'), "get the method metaclass";
ok $meth->has_in_header_attribute(), "has in header attribute";
is $meth->in_header_attribute(), 'authentication_info', "and it is what was expected";
ok my $header_class = $meth->in_header_class(), "get in_header_class";
can_ok $header_class, $meth->in_header_attribute();

my $head_att = $meth->in_header_attribute();

ok my $head_obj = $header_class->new($head_att => { user_name => 'foo', password => 'bar'}), "create object of header class" ;

my $xml_doc = XML::LibXML::Document->new('1.0', 'utf-8');

ok my ($head_xml) = $head_obj->to_xml($xml_doc), "header to_xml";


my $xpc = XML::LibXML::XPathContext->new($head_xml);
$xpc->registerNs(xs   => 'http://www.w3.org/2001/XMLSchema');
$xpc->registerNs(xsd  => 'http://www.w3.org/2001/XMLSchema');
$xpc->registerNs(wsdl => 'http://schemas.xmlsoap.org/wsdl/');
$xpc->registerNs(wsp  => 'http://schemas.xmlsoap.org/ws/2004/09/policy');
$xpc->registerNs(wssp => 'http://www.bea.com/wls90/security/policy');
$xpc->registerNs(soap => 'http://schemas.xmlsoap.org/wsdl/soap/');
$xpc->registerNs(my  => $parser->document->target_namespace);

is $head_xml->localname(), 'AuthenticationInfo', "got the right node name";
is $head_xml->namespaceURI(), $parser->document->target_namespace, "got the right namespace";

ok my ($user_node) = $xpc->findnodes("my:userName"), "get username";
is $user_node->textContent(), "foo", "got the right value";

ok my ($pass_node) = $xpc->findnodes("my:password"), "get password";
is $pass_node->textContent(), "bar", "got the right value";

$object->ua($ua);
$ua->content('<?xml version="1.0" encoding="UTF-8"?>
   <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body /></soapenv:Envelope>');

eval
{
   my $res = $object->op_get(cr_ref => '123456', header => { user_name => 'foo', password => 'bar'});
};

ok !$@, "run the method";

ok my $head_obj_new = $object->header->message(), "got a message in the header";
isa_ok $head_obj_new, $header_class, "header message";

ok my $head_att_obj = $head_obj_new->$head_att(), "and the right attribute is defined";

is $head_att_obj->user_name, "foo", "got right user_name";
is $head_att_obj->password, "bar", "got right password";

done_testing();
exit;

sub parser {


}

