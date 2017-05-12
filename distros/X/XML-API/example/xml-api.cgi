#!/usr/bin/perl

use lib '../lib';
use Data::Dumper;
use XML::API::XHTML;

my $h = XML::API->new();
$h->head_open;
$h->_set_lang('de');
$h->_comment("A Comment inside the head");
$h->title('A Test XML::API Script');
$h->head_close;

my $x = XML::API::XHTML->new();
$x->html_open;
$x->_add($h);

$x->_set_lang('en');

$x->body_open;
$x->h1('A Test XML::API Page');
$x->p("A paragraph");
$x->_comment("Second comment");

my $src   = $x->_as_string;
my $lsrc  = length($src);
my $rsrc  = $x->_fast_string;
my $lrsrc = length($rsrc);
my $hsrc  = $h->_as_string;
my $lhsrc = length($hsrc);

$x->hr;

$x->p("The source of this page is $lsrc bytes:");
$x->pre_open( -style => 'color: #005555; background-color: #cfcfcf;' );
$x->_cdata($src);
$x->pre_close;

$x->p("The reduced source of this page is $lrsrc bytes:");
$x->pre_open( -style => 'color: #005555; background-color: #cfcfcf;' );
$x->_cdata($rsrc);
$x->pre_close;

print "Content-Type: application/xhtml+xml\n\n";
print $x . "\n";

