#!/usr/bin/perl

use strict;
use lib 'lib';
use WWW::HtmlUnit;
use Test::More tests => 1;

my $webClient = WWW::HtmlUnit->new;
my $page = $webClient->getPage("http://htmlunit.sf.net");
my $title = $page->getTitleText();

is $title, 'HtmlUnit - Welcome to HtmlUnit';

