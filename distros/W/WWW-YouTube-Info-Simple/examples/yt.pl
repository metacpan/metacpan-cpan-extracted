#!/usr/bin/perl

# CLI example usage of WWW::YouTube::Info::Simple
# to directly download YouTube videos
# with means of lwp-download
# by a given URL or VIDEO_ID.
# e.g.: ./yt.pl http://youtube.com/watch?v=foobar
# e.g.: ./yt.pl http://www.youtube.com/v/foobar
# e.g.: ./yt.pl foobar

# change /usr/bin/lwp-download to the appropriate path/bin
# and use it at your own risk.

use strict;
use warnings;

use Data::Dumper;
use WWW::YouTube::Info::Simple;
use LWP::Simple;
use File::stat;

my $val = $ARGV[0] || die "usage: $0 '<yturl|id>'\n";

# get VIDEO_ID from $ARGV[0]
my $id = get_id($val) or die "no VIDEO_ID found at $val!";

my $yt = WWW::YouTube::Info::Simple->new($id);

# check status
my $info = $yt->get_info();
die "status ne 'ok' ('$info->{status}')!" if $info->{status} ne 'ok';

# get details
my $url   = $yt->get_url();
my $res   = $yt->get_resolution();
my $title = $yt->get_title();

# title is to be used as filename
# hence, remove slashes
$title =~ s/\///g;

# show qualities to choose from
print "Sources found:\n";
foreach my $key ( keys %$res ) {
  printf "Quality: %-2s [%s]\n", $key, $res->{$key};
}

# ask what quality to choose
my $q;
while ( 1 ) {
  print "Enter quality of choice: ";
  my $in = <STDIN>;
  chomp $in;
  # check whether choice exists
  $q = $in and last if exists $url->{$in};
  print "Choice has no URL!\n";
}

# get remote filetype/fileextension
my (
  $content_type,
  $document_length,
  $modified_time,
  $expires,
  $server
) = head($url->{$q});

my $ext;
if ( $content_type ) {
  # .. by header info
  $ext = '.flv' if ( $content_type =~ m/flv/ );
  $ext = '.mp4' if ( $content_type =~ m/mp4/ );
  die "no known content_type found: ($content_type)!" unless $ext;
}
else {
  die "no content_type found!";
}
my $file = $title.$ext;
print "Filename: $file\n";

# check whether file exists?
if ( -e $file ) {
  # get remote filesize
  # .. by header info
  my $url_size_mb  = $document_length ? sprintf "%.3f", $document_length/1048576 : 'n.a.';
  # get local filesize
  my $file_size_mb = sprintf "%.3f", stat($file)->size/1048576;

  print "Filename exists! [$file]\n";
  print "Local:  $file_size_mb MB\n";
  print "Remote: $url_size_mb MB\n";
  print "Overwrite? [y/N]: ";

  # ask what to do
  my $in = <STDIN>;
  chomp $in;
  unless ( $in =~ /^(y|yes|Y|Yes)$/ ) {
    print "Aborting.\n";
    exit(0);
  }
}

# download
print "Downloading ..\n";
# remark: remote mtime will be preserved
my @args;
push @args, '/usr/bin/lwp-download';
push @args, $url->{$q};
push @args, $file;
system(@args);

exit(0);


sub get_id {
  my $val = shift;

  my $uri   = URI->new($val);
  my $path  = $uri->path();
  my $query = $uri->query();

  my $id;
  # http://youtube.com/watch?v=foobar
  if ( $path =~ /\/watch/ ) {
    $id = $query;
    $id =~ s/^v=//;
  }
  # http://www.youtube.com/v/foobar
  elsif ( $path =~ /\/v\// ) {
    $id = $path;
    $id =~ s/\/v\///;
  }
  # foobar
  elsif ( $path !~ /\// ) {
    $id = $path;
  }

  return $id;
}

1;

