#!perl 
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

#use SOAP::Lite +trace => [qw/ debug method fault /];
use lib 't/lib';
use Yahoo::Marketing::Test::TargetingConverterService;

Test::Class->runtests;

