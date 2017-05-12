#!perl

=pod

=head1 NAME

WWW::ImageSpool - Cache images of interest from the web.

=head1 SYNOPSIS

	use WWW::ImageSpool;

	mkdir("/var/tmp/imagespool", 0700);
	
	my $spool = WWW::ImageSpool->new
	(
	 limit => 3,
	 searchlimit => 10,
	 max => 5 * 1048576,
	 dictionary => "sushi.txt",
	 verbose => 1,
	 dir => "/var/tmp/imagespool"
	);

	$spool->run();
	 while($spool->uptime < 86400);
	
=head1 DESCRIPTION

When A WWW::ImageSpool object's run() method is called, it randomly picks keywords
out of a chosen dictionary file and attempts to download images off of the
internet by doing searches on these keywords. (Currently only a Google Image
Search is done, via Guillaume Rousse's WWW::Google::Images module, but the
internals have been set up to make it easy to hook into other engines in the future.)
Images are stored in the specified directory. If the directory grows beyond
the maximum size, the oldest files in the directory are deleted.

The intended purpose behind this module is to supply images on demand for any
piece of software that wants abstract images, such as screensavers or
webpage generators or voice synthesizers (wouldn't it be cool if a voice
synthesizer extracted all the popular nouns out of a book and scrolled by
pertanent images as it read to you?)

=head1 Constructor

=head2 new(I<%args>)

Creates and returns a new C<WWW::ImageSpool> object.

Required parameters:

=over

=item dir => I<$dir>

Directory to hold the image files in. C<WWW::ImageSpool> will
delete files out of this directory when it reaches the
maximum size, so there shouldn't be anything in there that you
want to keep.

=back

Optional parameters:

=over

=item limit => I<$limit>

Maximum number of images to fetch from any one keyword search. Defaults to 3.

=item searchlimit => I<$searchlimit>

Maximum number of search results to ask the search engine for.
I<limit> results will be randomly picked out of the list that the search engine
returns. Default is search-engine specific (50 for Google). Most search engines will
return the results in the same order each time they are called with
the same keywords, so if you are using a small dictionary file it is generally
a good idea to make this a lot higher than I<limit>.

=item consume => 0 | 1

WWW::ImageSpool re-loads the dictionary file whenever it is modified, or
whenever it runs out of words. With I<consume> set to 0, WWW::ImageSpool
will never run out of words because it can re-use them as much as they
want. With I<consume> set to 1, WWW::ImageSpool deletes each word
from it's internal list as it uses it, ensuring that every single word
in the dictionary must be used once before any word may be used twice.

I<consume> is set to 1 by default.

=item retry => I<$retry>

How many times to retry image-searching or fetching operations if they
fail.

The actual maximum number of retries is (I<$retry> * I<$retry>);
WWW::ImageSpool will try up to I<$retry> times to find a word with
good search results, then with that word, will try up to I<$retry>
times to get images from it, stopping after at least one image
is successfully downloaded (or the retry is exhausted.)

I<retry> is set to 5 by default.

=item minx=> I<$minx>, miny => I<$miny>

Minimum X / Y resolution of images to return. Smaller images are discarded.

By default, I<minx> is set to 160, and I<miny> is set to 120.

=item max => I<$bytes>

Maximum size of the spool directory, in bytes. If the total size of all files in
that directory ever goes over this size, the oldest file in the directory is deleted
to make more room.

=item dictionary => I<$file>

Path to the dictionary file to use. Defaults to "/usr/share/dict/words".

=item verbose => I<0 - 4>

Level of verbosity. Defaults to 0, which prints nothing.
1 prints a logfile-like status line for each iteration of run().
2 prints each word that is picked, and advises if C<WWW::ImageSpool> picked a file that already exists in the spool.
3-4 print more verbose debugging information.

=back

Paramaters for making C<WWW::ImageSpool> re-entrant:

These parameters are only really useful if you are creating and destroying 
C<WWW::ImageSpool> objects throughout the lifespan of an application, but
want your statistics to remain constant throughout:

=over

=item n => I<$n>

How many iterations of C<run()> the application has done so far.

=item s => I<$s>

UNIX timestamp of when the application did it's first call to C<run()>
on a C<WWW::ImageSpool> object.

=item l => I<$l>

UNIX timestamp of when the application last did a call to C<run()>
on a C<WWW::ImageSpool> object.

=item got => I<$got>

How many images have been downloaded and stored over the life of the
application (including ones that have been deleted).

=back

=head1 Methods

=head2 run()

Pick a new keyword and attemt to download up to I<limit> images
from an image search.

Returns the actual number of images downloaded and stored.

=head2 s()

Returns the UNIX timestamp of the object's first operation.

=head2 l()

Returns the UNIX timestamp of the object's last operation.

=head2 n()

Returns how many times C<run()> has been called on this object.

=head2 uptime()

Returns the number of seconds between the object's first operation and it's last operation.

=head2 lag()

Returns the number of seconds between the object's last operation and the current time.

=head2 got()

Returns the total number of images that have been downloaded and stored by this object,
including images that have been deleted.

=head1 BUGS

If the dictionary file suddenly disappears, C<WWW::ImageSpool> does not act very
graceful.

=head1 TODO

There should be size limitations on individual files with a HEAD check before
they are actually downloaded.

Underlying modules (C<WWW::ImageSpool::Source::Google>, C<WWW::ImageSpool::Dictionary>,
etc need to be documented.

Support for multiple "Source" and "Dictionary" objects in one "ImageSpool" object.

Per-C<run()> control over the search configuration.

=head1 NOTE

This module may violate the terms of service of some search engines or content
providers. Use at your own risk.

=head1 VERSION

0.01

=head1 LICENSE

Copyright 2004, Tyler "Crackerjack" MacDonald <tyler@yi.org>
This is free software; you may redistribute it under the same terms as perl itself.

=cut

package WWW::ImageSpool;
use strict;
use warnings;

use POSIX qw(strftime);
use WWW::ImageSpool::Source::Google;
use WWW::ImageSpool::Directory;
use WWW::ImageSpool::Dictionary;

our $VERSION = "0.01";

return 1;

sub new
{
 my $class = shift;
 my (%args) = (@_);
 my $self = bless { args => \%args }, $class;
 my (%dict_args, %dir_args, %search_args) = ();

 if(!$args{dir})
 {
  warn "WWW::ImageSpool->new(): \"dir\" is required.\n";
  return;
 }

 $args{limit} = 3
  if(!defined($args{limit}));

 $args{consume} = 1
  if(!defined($args{consume}));

 $args{retry} = 5
  if(!defined($args{retry}));
 
 $dir_args{dir} = $args{dir};
 
 $dir_args{minx} = $args{minx}
  if($args{minx});
 
 $dir_args{miny} = $args{miny}
  if($args{miny});
 
 $search_args{limit} = $args{limit}
  if($args{limit});

 $search_args{searchlimit} = $args{searchlimit}
  if($args{searchlimit});
 
 $dict_args{file} = $args{dictionary}
  if($args{dictionary});
 
 $dir_args{max} = $args{max}
  if($args{max});
 
 $args{verbose} = 0
  if(!defined($args{verbose}));
 
 $dir_args{verbose} = $dict_args{verbose} = $search_args{verbose} = $args{verbose};
 
 return
  if(!($self->{dict} = WWW::ImageSpool::Dictionary->new(%dict_args)));

 return
  if(!($self->{dir} = WWW::ImageSpool::Directory->new(%dir_args)));
 
 return
  if(!($self->{search} = WWW::ImageSpool::Source::Google->new(%search_args)));
 
 return $self;
}

sub word
{
 shift->{dict}->word(@_);
}

sub search
{
 shift->{search}->search(@_);
}

sub fetch
{
 shift->{dir}->fetch(@_);
}

sub run
{
 my $self = shift;
 my $iretry = 0;
 my $oretry = 0;
 my @images;
 my $rv;
 
 if(!$self->{n})
 {
  $self->{s} = time();
  
  if($self->{args}->{verbose})
  {
   printf
   (
    "[%s] PID %d % 3dstor % 3.2fMb\n",
    strftime("%y-%m-%d %H:%M:%S", localtime()), $$, scalar(keys(%{$self->{dir}->{files}})), $self->{dir}->{total_size} / 1048576
   );
  }
 }
 
 while(($oretry < $self->{args}->{retry}) && (!$rv))
 {
  $self->{n}++;
  my $word = $self->word($self->{args}->{consume});
  while(($oretry < $self->{args}->{retry}) && (!$rv))
  {
   @images = ($self->search($word));
   $rv = $self->fetch(@images);
   $iretry ++;
  }
  $oretry++;
 }

 $self->{l} = time();

 if($rv)
 {
  $self->{got}+=$rv;
  if($self->{args}->{verbose})
  {
   printf
   (
    "[%s] % 4d: % 3dnow/% 3dstor/% 3dt % 3.2fMb % 2.2ffpm %dw %d*%dtry\n",
    strftime("%y-%m-%d %H:%M:%S", localtime()), $self->{n}, $rv, scalar(keys(%{$self->{dir}->{files}})), $self->{got},
    $self->{dir}->{total_size} / 1048576, $self->{got} / (($self->{l} - $self->{s}) / 60), scalar(@{$self->{dict}->{words}}), $iretry, $oretry
   );
  }
  return $rv;
 }
 else
 {
  return;
 }
}

sub s
{
 return shift->{s};
}

sub l
{
 return shift->{l};
}

sub n
{
 return shift->{n};
}

sub got
{
 return shift->{got};
}

sub uptime
{
 return $_[0]->{l} - $_[0]->{s};
}

sub lag
{
 return time() - $_[0]->{l};
}
