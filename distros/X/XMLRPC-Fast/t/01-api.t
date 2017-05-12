#!perl
use strict;
use warnings;
use Test::More;
use XMLRPC::Fast;


plan tests => 1;

can_ok "XMLRPC::Fast", qw<
    decode_xmlrpc encode_xmlrpc encode_xmlrpc_request encode_xmlrpc_response
>;

