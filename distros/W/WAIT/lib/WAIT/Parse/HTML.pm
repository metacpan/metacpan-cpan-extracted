#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# $Basename: HTML.pm $
# $Revision: 1.2 $
# Author          : Ulrich Pfeifer with Andreas König
# Created On      : Sat Nov 1 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Nov  5 16:48:17 1997
# Language        : CPerl
# Update Count    : 1
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

package WAIT::Parse::HTML;
use vars qw(@ISA);
require HTML::Parse;
require HTML::FormatText;
use HTML::Entities qw(decode_entities);
@ISA = qw(WAIT::Parse::Base);


sub split {
  my ($self, $html_source) = @_;

  my ($title) = $html_source =~ /<title\s*>(.*?)<\/title\s*>/si;
  my $html = HTML::Parse::parse_html($html_source);
  my $formatter = HTML::FormatText->new;

  {
   'text',  $formatter->format($html),
   'title', $formatter->format(HTML::Parse::parse_html($title)),
  };
}

sub tag {
  my ($self, $html_source) = @_;

  $html_source =~ tr/\r/\n/;

  my ($pre,$title,$body) 
      = $html_source =~ /^(.*?<title\s*>)(.*?)(<\/title\s*>.+)/si;

  (
   {'text'  => 1},  decode_entities($pre),
   {'title' => 1},  decode_entities($title),
   {'text'  => 1},  decode_entities($body),
  );
}
