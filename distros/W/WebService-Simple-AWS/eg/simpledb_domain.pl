#!/usr/bin/perl
use strict;
use warnings;
use WebService::Simple::AWS;
use YAML;

################ WARNING #######################
## RUNNING THIS SCRIPT SPENDS REAL COST MONEY ##
################################################

my $domain_name = 'webservice-simple-aws-test';
my $service     = WebService::Simple::AWS->new(
    base_url => 'http://sdb.amazonaws.com/',
    params   => {
        Version          => '2009-04-15',
        SignatureVersion => '2',
        id               => $ENV{'AWS_ACCESS_KEY_ID'},
        secret           => $ENV{'AWS_ACCESS_KEY_SECRET'},
    },
);
my $res;
my $params = {};
$res = get_simpledb('ListDomains');
$res = get_simpledb( 'CreateDomain', { DomainName => $domain_name } );
$res = get_simpledb('ListDomains');
$res = get_simpledb( 'DeleteDomain', { DomainName => $domain_name } );
$res = get_simpledb('ListDomains');

sub get_simpledb {
    my ( $action, $params ) = @_;
    warn "*Action: $action-------------------------\n";
    $params ||= {};
    $params->{Action} = $action;
    my $res = $service->get($params);
    my $ref = $res->parse_response();
    warn Dump $ref;
    warn "---------------------------------------------\n";
}
