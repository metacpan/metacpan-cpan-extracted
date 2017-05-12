use strict;
use warnings;
use Yars::Client;
use Mojo::Asset::File;
use Mojo::ByteStream qw/b/;

my @filenames;
my @md5s;
my $how_many = $ARGV[0] || 100;

mkdir 'files';
for (1..$how_many)
{
  open my $fp, ">files/file.$_";
  print $fp "some data $_";
  print $fp 'more data' for 1..$how_many;
  close $fp;
}

my $y = Yars::Client->new();
my @locations;
for (1..$how_many)
{
  $y->upload("files/file.$_") or warn $y->errorstring;
  push @locations, $y->res->headers->location;
  push @filenames, "file.$_";
  my $a =  Mojo::Asset::File->new(path => "files/file.$_");
  push @md5s,b($a->slurp)->md5_sum;
}

system ('rm -rf ./got');
mkdir 'got';
chdir 'got';

for (1..$how_many)
{
  my $loc = shift @locations;
  my $filename = shift @filenames;
  my $md5 = shift @md5s;
  $y->download($filename,$md5);
}

chdir '..';

system 'diff -r files/ got/';
