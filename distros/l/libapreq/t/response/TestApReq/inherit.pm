package TestApReq::inherit;
use strict;
use Apache::Request;
use Apache::Constants qw/OK/;
sub handler {
    my $r = Apache->request;
    $r->send_http_header('text/plain');

    my $apr = Apache::Request->new($r);
    $r->printf("method => %s\n", $apr->method);
    return OK;
}

1;
