#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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
use warnings;
use Carp;
use File::Spec;
use File::stat;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # MLSD

  my $hostname = "localhost";
  require App::Upfiles::FTPlazy;
  my $ftp = App::Upfiles::FTPlazy->new
    or die "Cannot connect: $@";
  $ftp->host($hostname);
  $ftp->login("anonymous",'')
    or die "Cannot login: ", $ftp->message;

  $ftp->cwd("/pub");

  require File::Temp;
  my @pending_directories = ('/');
  my %seen;

  while (@pending_directories) {
    my $dirname = pop @pending_directories;
    ### $dirname
    $ftp->cwd($dirname);
    my @lines = $ftp->mlsd('');
    ### @lines
    foreach my $line (@lines) {
      my ($filename, %facts) = MLSD_line_parse($line);
      my $type = $facts{'type'} // '';
      if ($type eq 'file') {
        check_file ($dirname, $filename, \%facts);
      } elsif ($type eq 'dir') {
        my $unique = $facts{'unique'};
        if (defined $unique && $seen{$unique}++) {
          next;
        }
        push @pending_directories, File::Spec->catfile($dirname, $filename);
      }
    }
  }

  sub check_file {
    my ($dirname, $filename, $facts) = @_;
    my $remote_size = $facts->{'size'};
    if (! defined $remote_size) {
      print "  no size from server\n";
    }
    my $local_fullname = File::Spec->catfile("/tmp", $dirname, $filename);
    my $local_st = File::stat::stat($local_fullname);
    print "$dirname  $filename size server $remote_size\n";

  }
  exit 0;

  # $str is like
  #   type=pdir; ..\r\n
  #   type=file;size=2061;UNIX.mode=0644; index.html\r\n
  # Return a list ($filename => $href, $filename => $href, ...)
  # where $href is a hashref of facts.
  sub MLSD_parse {
    my ($str) = @_;
    return map { my ($filename, %facts) = MLSD_line_parse($$_);
                 ($filename, \%facts) }
      split /\r\n/, $str;
  }

  # MLST line is preceded by a space
  sub MLST_line_parse {
    my ($str) = @_;
    $str =~ s/^ //;
    return MLSD_line_parse($str);
  }

  # $str is like
  #   "type=file;size=2061;UNIX.mode=0644; index.html"
  # Return a list ($filename, key => value, key => value, ...)
  # The keys are forced to lower case since they are specified to be
  # case-insensitive.
  sub MLSD_line_parse {
    my ($str) = @_;
    $str =~ /(.*?) (.*)$/ or return;
    my $facts = $1;
    my $filename = $2;
    return ($filename, MLST_facts_parse($facts));
  }

  # $str is like
  #     type=file;size=2061;modify=20150304222544;UNIX.mode=0644; index.html
  # Return a list (key => value, key => value, ...)
  # The keys are forced to lower case since they are specified to be
  # case-insensitive.
  sub MLST_facts_parse {
    my ($str) = @_;

    return map { my ($key, $value) = split /=/, $_, 2;
                 lc($key) => $value }
      split /;/, $str;
  }
}



    # if (defined $dirname) {
    # 
    # 
    #   my $fh = File::Temp->new;
    # 
    #   print "MLSD $dirname\n";
    #   $ftp->mlsd('', $fh);
    #   seek $fh, 0, 0;
    #   push @pending, { fh => $fh, dirname => $dirname };
    #   undef $dirname;
    # }


    # my $line;
    # if (! defined($line = readline $pending[-1]->{'fh'})) {
    #   ### eof on: $pending[-1]->{'dirname'}
    #   pop @pending;
    #   next;
    # }
    # ### $line
    # 
    # # Eg.
    # # type=file;size=2061;modify=20150304222544;UNIX.mode=0644;UNIX.uid=7631781;UNIX.gid=7631781;unique=811g2a360; index.html
    # $line =~ /(.*?) (.*)/ or croak "Unrecognised MLSD line ",$line;
    # my ($facts, $filename) = split / /, $line, 2;
    # if (! defined $filename) {
    #   croak "Unrecognised MLSD line ",$line;
    # }
    # $filename =~ s/[\r\n]+$//;
    # 
    # my %facts = (map { my ($key, $value) = split /=/, $_, 2; $key => $value }
    #              split /;/, $facts);
    # 
    # ### $filename
    # ### %facts
