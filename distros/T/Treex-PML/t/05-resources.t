#!/usr/bin/perl
use warnings;
use strict;

use Cwd qw(abs_path);
use File::Spec;
use XML::LibXML;

use Test::More tests => 3;

use Treex::PML;

Treex::PML::AddResourcePath(abs_path(File::Spec->catfile('test_data', 'resources')));

my $abs = abs_path(File::Spec->catfile('test_data', 'resources', 'res2.xml'));
my $template = File::Spec->catfile('test_data', 'pml', 'example12.xml');
my $tdom = XML::LibXML->load_xml(location => $template);
my ($href) = $tdom->findnodes('//@href[.="__REPLACE__"]');
$href->setValue($abs);

(my $output = $template) =~ s/xml$/out/;
my $instance = Treex::PML::Factory->createPMLInstance(
    {dom => $tdom,
     filename => $output,
     use_resources => 1});
$instance->save();

my $dom = XML::LibXML->load_xml(location => $output);
unlink $output;
my $xpc = XML::LibXML::XPathContext->new;
$xpc->registerNs(pml => 'http://ufal.mff.cuni.cz/pdt/pml/');

is $xpc->findvalue(
    '/pml:annotation/pml:head/pml:references/pml:reffile[@id="res"]/@href',
    $dom
), 'res1.xml',
    'path to resources';

is $xpc->findvalue(
    '/pml:annotation/pml:head/pml:references/pml:reffile[@id="rel"]/@href',
    $dom
), '../resources/res3.xml',
    'relative path';

like $xpc->findvalue(
    '/pml:annotation/pml:head/pml:references/pml:reffile[@id="abs"]/@href',
    $dom
), qr{test_data.*res2\.xml$},
    'absolute path';
