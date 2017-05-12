#!perl

package WWW::ImageSpool::Directory;
use strict;
use warnings;

use Fcntl qw(S_IFREG S_IRUSR S_IWUSR);
use IO::Dir;
use URI;
use URI::Escape qw(uri_unescape);
use LWP::Simple qw(getstore is_success);
use HTTP::Status qw(status_message);
use Image::Size qw(imgsize);

return 1;

sub new
{
 my $class = shift;
 my $self = bless { @_ }, $class;
 my %tied;
 if(!$self->{dir})
 {
  warn "ImageSpool::Directory->new(): \"dir\" is required!\n";
  return;
 }
 elsif(!-d($self->{dir}))
 {
  warn "ImageSpool::Directory->new(): \"", $self->{dir}, "\" is not a directory.\n";
  return;
 }
 elsif((! -r($self->{dir}) || (! -x($self->{dir}))))
 {
  warn "ImageSpool::Directory->new(): Need read and execute permissions to \"", $self->{dir}, "\".\n";
  return;
 }
 
 $self->{max} ||= 104857600; # 100 megs
 $self->{minx} ||= 160;
 $self->{miny} ||= 120;
 $self->prune();
 return $self;
}

sub refresh
{
 my $self = shift;
 my %dir;
 tie %dir, "IO::Dir", $self->{dir};
 $self->{files} = {};
 $self->{total_size} = 0;
 my $rv = 0;

 while(my($file, $stat) = each(%dir))
 {
  if(($stat->mode & (S_IFREG | S_IRUSR | S_IWUSR)) == (S_IFREG | S_IRUSR | S_IWUSR))
  {
   $self->{files}->{$file} = $stat;
   $self->{total_size} += $stat->size;
   $rv++;
  }
  else
  {
   if($self->{verbose} > 1 && ($stat->mode & S_IFREG))
   {
    print "Bad file \"$file\" in directory.\n";
   }
  }
 }
 
 if($rv)
 {
  return $rv;
 }
 else
 {
  return;
 }
}

sub prune
{
 my $self = shift;
 $self->refresh();

 return -1
  if($self->{total_size} <= $self->{max});

 my $rv = 0;
 my(@keys) = sort { $self->{files}->{$b}->mtime <=> $self->{files}->{$a}->mtime } (keys(%{$self->{files}}));
 
 while(($self->{total_size} > $self->{max}) && (@keys))
 {
  my $file = shift(@keys);
  if(unlink($self->{dir} . "/$file"))
  {
   $self->{total_size} -= $self->{files}->{$file}->size;
   delete($self->{files}->{$file});
   $rv++;
  }
  else
  {
   warn "ImageSpool(", $self->{dir}, ")::Directory->prune(): unlink \"", $file, "\" failed: $!\n";
  }
 }
 
 if($rv)
 {
  return $rv;
 }
 else
 {
  return;
 }
}

sub uri_filename
{
 my($self, $uri) = @_;
 my $urio = URI->new($uri);
# my $fn = uri_unescape($urio->path());
 my $fn = $urio->path();
 $fn =~ s{^.*/}{}g;
# my $fileexpr = sprintf("%s+%s", $urio->host, $fn);
# if($fn =~ /\./)
# {
#  my $ffn = $fn;
#  $ffn =~ s{^(.*)\.(.*?)$}{$1-\%04d.$2}g;
#  $fileexpr = sprintf("%s+%s", $urio->host(), $ffn);
# }
# else
# {
#  $fileexpr = sprintf("%s+%s-%%04d", $urio->host(), $fn);
# }
 my $n = 0;
 my $file = sprintf("%s+%s", $urio->host, $fn);
 my $path = $self->{dir} . "/$file";

 if(-e($path))
 {
  if($self->{verbose} > 1)
  {
   print "\"$file\" already exists.\n";
  }
  return;
 }
 else
 {
  return $file;
 }

#  if(!-e($path))
# {
#  $n++;
#  $file = sprintf($fileexpr, $n);
#  $path = $self->{dir} . "/$file";
# }

}

sub fetch
{
 my($self, @urls) = @_;
 my $rv = 0;
 my $url;

 while($url = shift(@urls))
 {
  if(my $filename = $self->uri_filename($url))
  {
   my $pathname = $self->{dir} . "/$filename";
   my $code = getstore($url, $pathname);
    
   if(is_success($code))
   {
    my($x,$y) = (imgsize($pathname));
    if(defined($x) && defined($y) && ($x >= $self->{minx}) && ($y >= $self->{miny}))
    {
     if($self->{verbose} > 2)
     {
      print "$url -> $filename\n";
     }
     $rv++;
    }
    else
    {
     if($self->{verbose} > 3)
     {
      if(!defined($x) || !defined($y))
      {
       print "$url: Not an image.\n";
      }
      else
      {
       print "$url: Too small (${x}x${y}<", $self->{minx}, "x", $self->{miny}, ").\n";
      }
     }
     unlink($pathname);
    }
   }
   else
   {
    if($self->{verbose} > 2)
    {
     print "$url -> $filename failed: ", status_message($code), "\n";
    }
    unlink($pathname);
   }
  }
 }
 
 $self->prune();
 
 if($rv)
 {
  return $rv;
 }
 else
 {
  return;
 }
}
