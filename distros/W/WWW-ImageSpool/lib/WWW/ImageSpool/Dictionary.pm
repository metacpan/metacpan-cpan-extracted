#!perl

package WWW::ImageSpool::Dictionary;

use strict;
use warnings;
use IO::File;

return 1;

sub new
{
 my $class = shift;
 my $self = bless { @_ }, $class;
 $self->{file} ||= "/usr/share/dict/words";
 $self->{mtime} = -1;
 if(!-e($self->{file}))
 {
  warn "ImageSpool::Dictionary->new() File \"", $self->{file}, "\" does not exist!\n";
  return;
 }
 elsif(!-r($self->{file}))
 {
  warn "ImageSpool::Dictionary->new(): File \"", $self->{file}, "\" is not readable!\n";
  return;
 }
 elsif(!$self->refresh_words(1))
 {
  return;
 }
 
 return $self;
}

sub refresh_words
{
 my($self, $force) = @_;
 
 my $mtime = -M($self->{file});
 
 if(($force) || ($mtime != $self->{mtime}) || (!$self->{words}) || (!scalar(@{$self->{words}})))
 {
  my $fh;
  if($fh = IO::File->new($self->{file}, "r"))
  {
   my(@words) = (grep(!/^$/, $fh->getlines()));
   $fh->close();
   chomp(@words);
   if(scalar(@words))
   {
    $self->{mtime} = $mtime;
    $self->{words} = \@words;
    return scalar(@words);
   }
   else
   {
   	warn "ImageSpool::Dictionary->refresh_words(): No words in dictionary file \"", $self->{file}, "\"!\n";
   	return;
   }
  }
  else
  {
   warn "ImageSpool::Dictionary->refresh_words(): open(", $self->{file}, ") failed: $!\n";
   return;
  }
 }
 else
 {
  return -1;
 }
}

sub word
{
 my($self, $consume) = @_;
 $self->refresh_words();
 my $pos = int(rand(scalar(@{$self->{words}})));
 my $word = $self->{last_word} = $self->{words}->[$pos];

 splice(@{$self->{words}}, $pos, 1)
  if($consume);

 if($self->{verbose} > 3)
 {
  print "Picked ", ($consume ? "and consumed " : ""), "word \"$word\".\n";
 }

 return $word;
}
