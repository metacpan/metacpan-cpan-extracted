#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Class::Unload;

use VMOMI;

use_ok("VMOMI::ComplexType");
can_ok("VMOMI::ComplexType", "serialize", "deserialize", "get_class_ancestors", 
		"get_class_members", "TO_JSON");
Class::Unload->unload("VMOMI::ComplexType");

use_ok("VMOMI::SimpleType");
can_ok("VMOMI::SimpleType", "serialize", "deserialize", "val", "TO_JSON");
Class::Unload->unload("VMOMI::SimpleType");

use_ok("VMOMI::SoapBase");
can_ok("VMOMI::SoapBase", "agent_string", "service_version", "service_namespace", 
		"soap_call", "soap_node", "soap_fault");
Class::Unload->unload("VMOMI::SoapBase");


done_testing;