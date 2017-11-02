#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use File::Spec;
use HTML::Parser;
use URI;
use URI::file;

# uncomment this to run the ### lines
# use Smart::Comments;

my $count_files = 0;
my $count_links = 0;
my $count_downloads = 0;

my %externals
  = (
     'http://www.gnu.org/graphics/gplv3-127x51.png' => 1,
     'http://www.gnu.org/licenses/licenses.html#GPL' => 1,
     'http://www.gnu.org/graphics/license-logos.html' => 1,
     'http://www.gnu.org/philosophy/free-sw.html' => 1,

     'http://www.gnu.org/software/emacs/' => 1,
     'http://www.gnu.org/software/texinfo/' => 1,
     'http://schema.org/BrowserApplication' => 1,
     'http://schema.org/CommunicationApplication' => 1,
     'http://schema.org/DeveloperApplication' => 1,
     'http://schema.org/DesktopEnhancementApplication' => 1,
     'http://schema.org/FinanceApplication' => 1,
     'http://schema.org/GameApplication' => 1,
     'http://schema.org/NetworkingApplication' => 1,
     'http://schema.org/OtherApplication' => 1,
     'http://schema.org/UtilitiesApplication' => 1,
     'http://www.bom.gov.au/oceanography/projects/ntc/tide_tables.shtml' => 1,
     'http://www.tuxfamily.org' => 1,
     'http://donation.tuxfamily.org/' => 1,
    );

my $bad = 0;

my %seen_canonical;

sub check_link {
  my ($filename, $tagname, $rel, $target) = @_;
  ### check_link() ...
  ### $filename
  ### $tagname
  ### $rel
  ### $target

  return if $target =~ /^#/;
  return if $externals{$target};
  $count_links++;

  if (defined $rel && $rel eq 'canonical') {
    my $want = $filename;
    if ($want =~ s{^web/}{}) {
      $want = "http://user42.tuxfamily.org/$want";
    } elsif ($want =~ s{^data/}{}) {
      $want = "http://download.tuxfamily.org/user42/$want";
    }
    unless ($target eq $want) {
      print "$ENV{HOME}/tux/$filename:1: bad canonical\n  got  $target\n  want $want\n";
      $bad = 1;
    }
    if ($seen_canonical{$filename}++) {
      print "$ENV{HOME}/tux/$filename:1: duplicate canonical\n";
      $bad = 1;
    }
    return;
  }

  if ($target =~ s{^(http|https|ftp)://download.tuxfamily.org/user42/}{$ENV{HOME}/tux/data/}) {
    $count_downloads++;
  }
  if ($target =~ /^(http|ftp|rsync)/) {
    # print "$ENV{HOME}/tux/$filename:1: absolute\n  $target\n";
    return;
  }

  my ($volume,$dir,$basename) = File::Spec->splitpath(File::Spec->rel2abs($filename));
  $dir = File::Spec->catdir($volume,$dir);
  $target = File::Spec->rel2abs($target,$dir);
  $target =~ s/#.*//;
  if (! -e $target) {
    print "$ENV{HOME}/tux/$filename:1: missing $target\n";
    $bad = 1;
  }
}

sub check_file {
  my ($filename) = @_;
  return if $filename eq 'web/mpm/mpm.html';
  $count_files++;
  my $parser = HTML::Parser->new
    (api_version => 3,
     start_h => [ sub {
                    my ($tagname, $attr) = @_;
                    my $href = $attr->{'href'} // $attr->{'src'} // return;
                    check_link($filename, $tagname, $attr->{'rel'}, $href);
                  }, "tagname, attr"]);
  $parser->parse_file ($filename);
}

chdir "$ENV{HOME}/tux" or die;
foreach my $filename (
                      # "web/dragon/index.html",
                      glob("web/*.html"),
                      glob("web/*/*.html"),
                      glob("data/*.html"),
                      glob("data/*/*.html"),
                     ) {
  check_file($filename);
}
print "$count_files files $count_links links ($count_downloads downloads)\n";
print $bad ? "  bad\n" : "  ok\n";
exit($bad ? 0 : 1);
