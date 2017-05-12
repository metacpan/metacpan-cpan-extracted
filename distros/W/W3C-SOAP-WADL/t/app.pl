#!/usr/bin/perl

use Mojolicious::Lite;
use Data::Dumper qw/Dumper/;

# This is a test script of a dynamic wadl

get '/wadl' => sub {
    my ($self) = @_;

    $self->render(html => 'wadl', port => $ENV{PORT});
};

my $x_r = 0;
my $i_r = 1;
get '/ping' => sub {
    my ($self) = @_;

    $self->res->headers->header('X-Response-ID', $x_r++);
    $self->res->headers->header('I-Response-ID', $i_r++);
    $self->render( json => {message => 'get'} );
};
post '/ping' => sub {
    my ($self) = @_;

    $self->res->headers->header('X-Response-ID', $x_r++);
    $self->res->headers->header('Response-ID', $i_r++);

    my $status = $self->req->headers->{headers}{'i-status'}[0];
    if ( !$status ) {
        warn 1;
        $self->render(json => {message => 'post'}, status => 200 );
    }
    elsif ( $status == 400 ) {
        warn 2;
        $self->render(text => '', status => 400 );
    }
    elsif ( $status == 401 ) {
        warn 3;
        $self->app->types->type( multi => "x-application-urlencoded" );
        $self->render(text => "multi=true", format => 'multi', status => 401 );
    }
    elsif ( $status == 402 ) {
        warn 4;
        $self->app->types->type( form => "application/x-www-form-urlencoded" );
        $self->render(text => "multi=true&form=1", format => 'form', status => 402 );
    }
    elsif ( $status == 403 ) {
        warn 5;
        $self->app->types->type( url => "multipart/form-data" );
        $self->render(text => "multi=true&form=1&url=u", format => 'url', status => 403 );
    }
    elsif ( $status == 404 ) {
        warn 5;
        $self->app->types->type( xml => "text/xml" );
        $self->render(text => "<xml>text</xml>", format => 'xml', status => 404 );
    }
    else {
        warn 6;
        $self->render(json => {message => 'post'}, status => 300 );
    }
};

app->start;

__DATA__

@@ ping.json.ep
{"message":"pong"}

@@ wadl.html.ep
<?xml version="1.0" encoding="UTF-8"?>
<application xmlns="http://wadl.dev.java.net/2009/02"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:tns="http://rest.domain.gdl.optus.com.au/rest/3/service/bis/ping"
    xmlns:json="http://rest.domain.gdl.optus.com.au/rest/3/common-json"
    xsi:schemaLocation="http://wadl.dev.java.net/2009/02 wadl20090202.xsd
                     http://rest.domain.gdl.optus.com.au/rest/3/service/bis/ping ping.xsd">

    <doc xml:lang="en" title="Business - Ping" version="${project.version}">
        This service provides basic "ping" functionality which allows the calling
        clients/partners to test their connectivity to the platform.
    </doc>
    <resources path="http://localhost:<%= $port || 3000 %>/">
        <resource path="ping" id="Ping">
            <method name="GET" id="ping">
                <doc xml:lang="en" title="Ping">
                    A calling client/partner can request a GET ping to the server
                    to ensure connectivity.
                </doc>
                <request>
                    <param name="X-Request-ID"             style="header" type="xs:string" required="true"/>
                    <param name="X-Request-DateTime"       style="header" type="xs:string" required="true"/>
                    <param name="X-Request-TimeZone"       style="header" type="xs:string" required="true"/>
                    <param name="X-Partner-ID"             style="header" type="xs:string" required="true"/>
                    <param name="I-Request-ID"             style="header" type="xs:string" required="false"/>
                    <param name="I-Correlation-Request-ID" style="header" type="xs:string" required="false"/>
                    <param name="I-Partner-ID"             style="header" type="xs:string" required="false"/>
                    <param name="message"                  style="query"  type="xs:string" required="false"/>
                </request>
                <response status="200">
                    <param name="X-Response-ID"             style="header" type="xs:string" required="true"/>
                    <param name="I-Response-ID"             style="header" type="xs:string" required="false"/>
                    <param name="I-Correlation-Response-ID" style="header" type="xs:string" required="false"/>
                    <representation mediaType="application/json"
                        json:serialize="au.com.optus.gdl.rest.domain.v3.service.ping.dto.PingResponse"/>
                </response>
                <response status="400"/>
            </method>

            <method name="POST" id="pingPost">
                <doc xml:lang="en" title="Ping">
                    A calling client/partner can request a POST ping the server
                    to ensure connectivity.
                </doc>
                <request>
                    <param name="X-Request-ID"             style="header" type="xs:string" required="true"/>
                    <param name="X-Request-DateTime"       style="header" type="xs:string" required="true"/>
                    <param name="X-Request-TimeZone"       style="header" type="xs:string" required="true"/>
                    <param name="X-Partner-ID"             style="header" type="xs:string" required="true"/>
                    <param name="I-Request-ID"             style="header" type="xs:string" required="false"/>
                    <param name="I-Correlation-Request-ID" style="header" type="xs:string" required="false"/>
                    <param name="I-Partner-ID"             style="header" type="xs:string" required="false"/>
                    <param name="I-Status"                 style="header" type="xs:string" required="false"/>
                    <representation mediaType="application/json"
                        json:serialize="au.com.optus.gdl.rest.domain.v3.service.ping.dto.PingRequest"/>
                </request>
                <response status="200">
                    <param name="Response-ID"               style="header" type="xs:string" required="true"/>
                    <param name="X-Response-ID"             style="header" type="xs:string" required="true"/>
                    <param name="I-Response-ID"             style="header" type="xs:string" required="false"/>
                    <param name="I-Correlation-Response-ID" style="header" type="xs:string" required="false"/>
                    <representation mediaType="application/json"
                        json:serialize="au.com.optus.gdl.rest.domain.v3.service.ping.dto.PingResponse"/>
                </response>
                <response status="400"/>
                <response status="401">
                    <representation mediaType="x-application-urlencoded">
                        <param name="multi" style="query" type="xs:string" required="true" />
                    </representation>
                </response>
                <response status="402">
                    <representation mediaType="application/x-www-form-urlencoded">
                        <param name="form" style="query" type="xs:string" required="true" />
                    </representation>
                </response>
                <response status="403">
                    <representation mediaType="multipart/form-data">
                        <param name="url" style="query" type="xs:string" required="true" />
                    </representation>
                </response>
                <response status="404">
                    <representation mediaType="text/xml" />
                </response>
                <response status="412">
                    <representation mediaType="application/json"
                        json:serialize="au.com.optus.gdl.rest.domain.v3.service.ping.dto.PingResponse"/>
                    <representation mediaType="application/xml"/>
                </response>
            </method>

        </resource>
    </resources>
</application>
