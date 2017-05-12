#!perl
use strict;
use Apache::test;

my $r = Apache->request;
$r->send_http_header('text/plain');

eval {
    require Apache::Request;
};

unless (have_module "Apache::Request" and Apache::Request->can('upload')) {
    print "1..0\n";
    print $@ if $@;
    print "$INC{'Apache/Request.pm'}\n";
    return;
}

my $apr = Apache::Request->new($r);
printf "method => %s\n", $apr->method;
printf "hostname => %s\n", $apr->hostname;

#for ($apr->param) {
#    my(@v) = $apr->param($_);
#    print "param $_ => ", join ",", @v;
#    print $/;
#}
