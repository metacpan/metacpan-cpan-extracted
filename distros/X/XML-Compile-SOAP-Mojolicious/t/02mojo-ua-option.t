#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 3;

use Test::Mojo;
use Mojo::File qw(curfile);
use Mojo::Promise;
use Mojo::Util qw(dumper);

use XML::Compile::WSDL11;      # use WSDL version 1.1
use XML::Compile::SOAP11;      # use SOAP version 1.1
use XML::Compile::SOAP12;
use XML::Compile::Transport::SOAPHTTP_MojoUA;

my $t = Test::Mojo->new('Mojolicious');

$t->get_ok('/SOAP')->status_is(404);

my $httpUa = XML::Compile::Transport::SOAPHTTP_MojoUA->new(
    mojo_ua => $t->ua,
    address => '/SOAP',
);

my $wsdlC = XML::Compile::WSDL11->new(curfile->sibling('02nameservice.wsdl'));

$wsdlC->importDefinitions(curfile->sibling('02nameservice.xsd'));

my $call = $wsdlC->compileClient(
    operation => 'getCountries',
    transport => $httpUa->compileClient,
    async     => 1,
);

my $res;

Mojo::Promise->new(sub {
    my ($resolve,$reject) = @_;
    $call->(
        _callback => sub {
            my ($answer,$trace) = @_;
            $resolve->($trace->response);
        }
    )
})->then(sub {
    $res = shift;
})->wait;
is($res->status_line,'404 Not Found','check response');

done_testing;
