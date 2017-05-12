#!/usr/bin/perl

use strict;
use WWW::HtmlUnit;

my $webClient = WWW::HtmlUnit->new('FIREFOX_3');
my $page = $webClient->getPage("http://google.com/");
my $f = $page->getFormByName('f');
my $submit = $f->getInputByName("btnG");
my $query  = $f->getInputByName("q");
$page = $query->type("HtmlUnit");
$page = $query->type("\n");

my $content = $page->asXml;
print "Result:\n$content\n\n";

