#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
# use lib '/so/perl/html-extractmain/html-extractmain/lib';

{
  require HTML::ExtractMain;

  require File::Slurp;
  # my $str = File::Slurp::slurp('samp/swellnet-daily-2.html', binmode=>':utf8');

  # my $str = File::Slurp::slurp('/tmp/daily');
  my $str = <<'HERE';
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
  <html>
  <head>
    <meta name="Author" content="Blah">
  </head>
  <body>
  <p> Hello'
  </p>
  </body>
  </html>
HERE

  my $main = HTML::ExtractMain::extract_main_html($str,
                                                  output_type => 'html');
# ,
#                                                   output_parts => 'document');
  print $main;

  print "\n\n";
  require HTML::FormatText::W3m;
  my $formatter = HTML::FormatText::W3m->new(rightmargin => 50);
  print $formatter->format_string($main);
  exit 0;

  $main =~ s/&apos;/&#39;/;

  print <<HERE;
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
</head>
<body>
$main
</body>
HERE
  # require HTML::FormatText;
  # my $formatter = HTML::FormatText->new(rightmargin => 50);
  exit 0;
}
{
  require HTML::TreeBuilder;
  require File::Slurp;
  my $str = File::Slurp::slurp('samp/swellnet-daily-2.html');
  my $tree = HTML::TreeBuilder->new_from_content($str);
  $tree->dump;
  exit 0;
}

