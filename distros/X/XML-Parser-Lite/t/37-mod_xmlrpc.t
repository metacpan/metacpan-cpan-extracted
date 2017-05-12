#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'XMLRPC::Lite' => 0.717,
    'XMLRPC::Test' => 0.717,
};

XMLRPC::Test::Server::run_for( shift || 'http://localhost/mod_xmlrpc' );

