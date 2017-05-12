#!/usr/bin/perl
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 17;
use WWW::Webrobot::Ext::XHtml::HTTP::Response;
use HTTP::Response;


my $r = HTTP::Response->new();

$r->header(content_type => "");
is($r->content_type(), "",       "S undef: type");
is($r->content_charset(), undef, "S undef: charset");

$r->header(content_type => "text/html");
is($r->header("content_type"), "text/html", "set/get HTTP content-type");
is($r->content_type(), "text/html", "S type: type");
is($r->content_charset(), undef,    "S type: charset");

$r->header(content_type => "TEXT/HTML");
is($r->content_type(), "text/html", "S upper case type: type");
is($r->content_charset(), undef,    "S upper case type: charset");

$r->header(content_type => "text/plain; charset=utf-8");
is($r->content_type(), "text/plain", "S type+charset: type");
is($r->content_charset(), "utf-8",   "S type+charset: charset");

$r->header(content_type => "text/plain; charset=utf-8; version=3.2");
is($r->content_type(), "text/plain", "S type+charset+version: type");
is($r->content_charset(), "utf-8",   "S type+charset+version: charset");

$r->header(content_type => ["text/html; charset=utf-8", "text/plain; charset=iso-8859-1"]);
is($r->content_type(), "text/html", "A [type+charset, type+charset]: type");
is($r->content_charset(), "utf-8",  "A [type+charset, type+charset]: charset");

$r->header(content_type => ["text/html", "text/plain; charset=iso-8859-1"]);
is($r->content_type(), "text/html",     "A [type, type+charset]: type");
is($r->content_charset(), "iso-8859-1", "A [type, type+charset]: type");

$r->header(content_type => ["text/html; charset=utf-8", "text/plain"]);
is($r->content_type(), "text/html", "A [type+charset, type]: type");
is($r->content_charset(), "utf-8",  "A [type+charset, type]: type");

1;
