#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;

## Unlinking and clearing a template in Zabbix can fail when PHP runs out of memory.
## This example has a hardcoded template name. It finds all hosts, linked to that
## template, then unlinks and clears them one by one.

my $username     = 'user';
my $password     = 'password';
my $url          = 'http://host/zabbix/api_jsonrpc.php';
my $templatename = "Template to unlink and clear";
my $result;

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);

print "Getting tempate ID for template $templatename...\n";
$result = $zabbix->do(
    'template.get',
    {
        output => "templateid",
        filter => { "host" => $templatename },
    }
);
my $templateid = $result->[0]{templateid};

print "Getting hosts linked to templateid $templateid...\n";
$result = $zabbix->do(
    'host.get',
    {
        output      => [ 'hostid', 'name' ],
        templateids => $templateid,
    }
);

for my $host (@$result) {
    print "\n$host->{name}\n";
    my $result_unlink = $zabbix->do(
        'host.update',
        {
            hostid          => $host->{hostid},
            templates_clear => $templateid,
        }
    );
    print "Request: - " . $zabbix->json_request . "\n";
    print "Response: - " . $zabbix->json_response . "\n";
}
