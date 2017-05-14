#!/usr/bin/perl5.8.0


use strict;
use XML::Template;
use XML::Template::Config;
use XML::Template::Element::File::Load;
use XML::Template::Element::Block::Load;


my $path = $ENV{PATH_INFO} || 'index.xhtml';
$path =~ s[^/][];

my $xmlt = XML::Template->new (
             Load => [
               XML::Template::Element::File::Load->new (
                 IncludePath	=> ['.', XML::Template::Config->admindir]),
               XML::Template::Element::Block::Load->new (
                 StripPattern	=> '\/?([^\/]+)\..*$')
             ],
             ErrorTemplate	=> 'error.xhtml')
  || XML::Template->handle_error ('Template', XML::Template->error ());
$xmlt->process ($path)
  || print "Error: " . $xmlt->error () . "\n";
