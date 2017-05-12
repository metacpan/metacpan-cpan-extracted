#!/usr/bin/perl 
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

use strict;
use warnings;

use testAssigningAuth;
use LS::Assigning::Service transport=>'HTTP::CGI';


my $test = testAssigningAuth->new;

my $svc = LS::Assigning::Service->new();
$svc->handler($test);


$svc->dispatch;




1;

__END__
