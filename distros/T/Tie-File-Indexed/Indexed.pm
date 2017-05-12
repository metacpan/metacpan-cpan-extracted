##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files

package Tie::File::Indexed;
use 5.10.0; ##-- for // operator
use Tie::Array;
use JSON qw();
use Fcntl qw(:DEFAULT :seek :flock);
use File::Copy qw();
use IO::File;
use Carp qw(confess);
use strict;

##======================================================================
## Globals

our @ISA     = qw(Tie::Array);
our $VERSION = '0.09';

##======================================================================
## Constructors etc.

## $tied = CLASS->new(%opts)
## $tied = CLASS->new($file,%opts)
##  + %opts, object structure:
##    (
##     file   => $file,    ##-- file basename; uses files "${file}", "${file}.idx", "${file}.hdr"
##     mode   => $mode,    ##-- open mode (fcntl flags or perl-style; default='rwa')
##     perms  => $perms,   ##-- default: 0666 & ~umask
##     pack_o => $pack_o,  ##-- file offset pack template (default='J')
##     pack_l => $pack_l,  ##-- string-length pack template (default='J')
##     bsize  => $bsize,   ##-- block-size in bytes for index batch-operations (default=2**21 = 2MB)
##     temp   => $bool,    ##-- if true, call unlink() on object destruction (default=false)
##     ##
##     ##-- pack lengths (after open())
##     len_o  => $len_o,   ##-- packsize($pack_o)
##     len_l  => $len_l,   ##-- packsize($pack_l)
##     len_ix => $len_ix,  ##-- packsize($pack_ix) == $len_o + $len_l
##     pack_ix=> $pack_ix, ##-- "${pack_o}${pack_l}"
##     ##
##     ##-- guts (after open())
##     idxfh => $idxfh,    ##-- $file.idx : [$i] => pack("${pack_o}${pack_l}",  $offset_in_datfh_of_item_i, $len_in_datfh_of_item_i)
##     datfh => $datfh,    ##-- $file     : raw data (concatenated)
##     #size  => $nrecords, ##-- cached number of records for faster FETCHSIZE()  ##-- potentially UNSAFE for concurrent access: DON'T USE
##    )
sub new {
  my $that = shift;
  my $file = (@_ % 2)==0 ? undef : shift;
  my %opts = @_;
  my $tied = bless({
		   $that->defaults(),
		   file => $file,
		   @_,
		  }, ref($that)||$that);
  return $tied->open() if (defined($tied->{file}));
  return $tied;
}

## %defaults = CLASS_OR_OBJECT->defaults()
##  + default attributes for constructor
sub defaults {
  return (
	  #file  => $file,
	  perms  => (0666 & ~umask),
	  mode   => 'rwa',
	  pack_o => 'J',
	  pack_l => 'J',
	  block  => 2**21,
	 );
}

## undef = $tied->DESTROY()
##  + implicitly calls unlink() if 'temp' attribute is set to a true value
##  + implicitly calls close()
sub DESTROY {
  $_[0]->unlink() if ($_[0]{temp});
  $_[0]->close();
}

##======================================================================
## Utilities

##--------------------------------------------------------------
## Utilities: fcntl

## $flags = CLASS_OR_OBJECT->fcflags($mode)
##  + returns Fcntl flags for symbolic string $mode
sub fcflags {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $mode = shift;
  $mode //= 'r';
  return $mode if ($mode =~ /^[0-9]+$/); ##-- numeric mode is interpreted as Fcntl bitmask
  my $fread  = $mode =~ /[r<]/;
  my $fwrite = $mode =~ /[wa>\+]/;
  my $fappend = ($mode =~ /[a]/ || $mode =~ />>/);
  my $flags = ($fread
	       ? ($fwrite ? (O_RDWR|O_CREAT)   : O_RDONLY)
	       : ($fwrite ? (O_WRONLY|O_CREAT) : 0)
	      );
  $flags |= O_TRUNC  if ($fwrite && !$fappend);
  return $flags;
}

## $fcflags = fcgetfl($fh)
##  + returns Fcntl flags for filehandle $fh
sub fcgetfl {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $fh = shift;
  return CORE::fcntl($fh,F_GETFL,0);
}

## $bool = CLASS_OR_OBJECT->fcread($mode)
##  + returns true if any read-bits are set for $mode
sub fcread {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $flags = fcflags(shift);
  return ($flags&O_RDONLY)==O_RDONLY || ($flags&O_RDWR)==O_RDWR;
}

## $bool = CLASS_OR_OBJECT->fcwrite($mode)
##  + returns true if any write-bits are set for $mode
sub fcwrite {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $flags = fcflags(shift);
  return ($flags&O_WRONLY)==O_WRONLY || ($flags&O_RDWR)==O_RDWR;
}

## $bool = CLASS_OR_OBJECT->fctrunc($mode)
##  + returns true if truncate-bits are set for $mode
sub fctrunc {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $flags = fcflags(shift);
  return ($flags&O_TRUNC)==O_TRUNC;
}

## $bool = CLASS_OR_OBJECT->fccreat($mode)
sub fccreat {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $flags = fcflags(shift);
  return ($flags&O_CREAT)==O_CREAT;
}

## $str = CLASS_OR_OBJECT->fcperl($mode)
##  + return perl mode-string for $mode
sub fcperl {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $flags = fcflags(shift);
  return (fcread($flags)
	  ? (fcwrite($flags)    ##-- +read
	     ? (fctrunc($flags) ##-- +read,+write
		? '+>' : '+<')  ##-- +read,+write,+/-trunc
	     : '<')
	  : (fcwrite($flags)    ##-- -read
	     ? (fctrunc($flags) ##-- -read,+write
		? '>' : '>>')   ##-- -read,+write,+/-trunc
	     : '<')             ##-- -read,-write : default
	 );
}

## $fh_or_undef = CLASS_OR_OBJECT->fcopen($file,$mode)
## $fh_or_undef = CLASS_OR_OBJECT->fcopen($file,$mode,$perms)
##  + opens $file with fcntl- or perl-style mode $mode
sub fcopen {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my ($file,$flags,$perms) = @_;
  $flags    = fcflags($flags);
  $perms  //= (0666 & ~umask);
  my $mode = fcperl($flags);

  my ($sysfh);
  if (ref($file)) {
    ##-- dup an existing filehandle
    $sysfh = $file;
  }
  else {
    ##-- use sysopen() to honor O_CREAT and O_TRUNC
    sysopen($sysfh, $file, $flags, $perms) or return undef;
  }

  ##-- now open perl-fh from system fh
  open(my $fh, "${mode}&=", fileno($sysfh)) or return undef;
  if (fcwrite($flags) && !fctrunc($flags)) {
    ##-- append mode: seek to end of file
    seek($fh, 0, SEEK_END) or return undef;
  }
  return $fh;
}

##--------------------------------------------------------------
## Utilities: pack sizes

## $len = CLASS->packsize($packfmt)
## $len = CLASS->packsize($packfmt,@args)
##  + get pack-size for $packfmt with args @args
sub packsize {
  use bytes; ##-- deprecated in perl v5.18.2
  no warnings;
  return bytes::length(pack($_[0],@_[1..$#_]));
}


##--------------------------------------------------------------
## Utilities: JSON

## $data = CLASS->loadJsonString( $string,%opts)
## $data = CLASS->loadJsonString(\$string,%opts)
##  + %opts passed to JSON::from_json(), e.g. (relaxed=>0)
##  + supports $opts{json} = $json_obj
sub loadJsonString {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $bufr = ref($_[0]) ? $_[0] : \$_[0];
  my %opts = @_[1..$#_];
  return $opts{json}->decode($$bufr) if ($opts{json});
  return JSON::from_json($$bufr, {utf8=>!utf8::is_utf8($$bufr), relaxed=>1, allow_nonref=>1, %opts});
}

## $data = CLASS->loadJsonFile($filename_or_handle,%opts)
sub loadJsonFile {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $file = shift;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  return undef if (!$fh);
  binmode($fh,':raw');
  local $/=undef;
  my $buf = <$fh>;
  close($fh) if (!ref($file));
  return $that->loadJsonString(\$buf,@_);
}

## $str = CLASS->saveJsonString($data)
## $str = CLASS->saveJsonString($data,%opts)
##  + %opts passed to JSON::to_json(), e.g. (pretty=>0, canonical=>0)'
##  + supports $opts{json} = $json_obj
sub saveJsonString {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $data = shift;
  my %opts = @_;
  return $opts{json}->encode($data)  if ($opts{json});
  return JSON::to_json($data, {utf8=>1, allow_nonref=>1, allow_unknown=>1, allow_blessed=>1, convert_blessed=>1, pretty=>1, canonical=>1, %opts});
}

## $bool = CLASS->saveJsonFile($data,$filename_or_handle,%opts)
sub saveJsonFile {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $data = shift;
  my $file = shift;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  logconfess((ref($that)||$that)."::saveJsonFile() failed to open file '$file': $!") if (!$fh);
  binmode($fh,':raw');
  $fh->print($that->saveJsonString($data,@_)) or return undef;
  if (!ref($file)) { close($fh) || return undef; }
  return 1;
}

##--------------------------------------------------------------
## Utilities: debugging

## $idxbuf = $tied->slurpIndex()
##  + slurps whole raw index-file into a string-buffer (for debugging)
sub slurpIndex {
  my $tied = shift;
  return undef if (!$tied->opened);
  my $fh = $tied->{idxfh};
  CORE::seek($fh, 0, SEEK_SET) or return undef;
  local $/ = undef;
  return <$fh>;
}

## $idxtxt = $tied->indexText()
## @idxtxt = $tied->indexText()
##  + slurps whole index file and returns it as a text-buffer (for debugging)
sub indexText {
  my $tied = shift;
  my @idx = map {join(' ',unpack($tied->{pack_ix},$_))} unpack("(A[$tied->{len_ix}])*", $tied->slurpIndex//'');
  return wantarray ? @idx : join("\n",@idx)."\n";
}

## $datbuf = $tied->slurpData()
##  + slurps whole raw data-file into a string-buffer (for debugging)
sub slurpData {
  my $tied = shift;
  return undef if (!$tied->opened);
  my $fh = $tied->{datfh};
  CORE::seek($fh, 0, SEEK_SET) or return undef;
  local $/ = undef;
  return <$fh>;
}


##======================================================================
## Subclass API: Data I/O

## $bool = $tied->writeData($data)
##  + write item $data to $tied->{datfh} at its current position
##  + after writing, $tied->{datfh} should be positioned to the first byte following the written item
##  + $tied is assumed to be opened in write-mode
##  + default implementation just writes $data as a byte-string (undef is written as the empty string)
##  + can be overridden by subclasses to perform transparent encoding of complex data
sub writeData {
  return $_[0]{datfh}->print($_[1]//'');
}

## $data_or_undef = $tied->readData($length)
##  + read item data record of length $length from $tied->{datfh} at its current position
##  + default implementation just reads a byte-string of length $length
sub readData {
  CORE::read($_[0]{datfh}, my $buf, $_[1])==$_[1] or return undef;
  return $buf;
}

##======================================================================
## Subclass API: Index I/O

## ($off,$len) = $tied->readIndex($index)
## ($off,$len) = $tied->readIndex(undef)
##  + gets index-record for item at logical index $index from $tied->{idxfh}
##  + if $index is undef, read from the current position of $tied->{idxfh}
##  + $index is assumed to exist in the array
##  + returns the empty list on error
sub readIndex {
  !defined($_[1]) or CORE::seek($_[0]{idxfh}, $_[1]*$_[0]{len_ix}, SEEK_SET) or return qw();
  CORE::read($_[0]{idxfh}, my $buf, $_[0]{len_ix})==$_[0]{len_ix} or return qw();
  return unpack($_[0]{pack_ix}, $buf);
}

## $tied_or_undef = $tied->writeIndex($index,$off,$len)
## $tied_or_undef = $tied->writeIndex(undef,$off,$len)
##  + writes index-record for item at logical index $index to $tied->{idxfh}
##  + if $index is undef, write at the current position of $tied->{idxfh}
##  + returns undef list on error
sub writeIndex {
  !defined($_[1]) or CORE::seek($_[0]{idxfh}, $_[1]*$_[0]{len_ix}, SEEK_SET) or return undef;
  $_[0]{idxfh}->print(pack($_[0]{pack_ix}, $_[2], $_[3])) or return undef;
  return $_[0];
}

## $tied_or_undef = $tied->shiftIndex($start,$n,$shift)
##  + moves $n index records starting from $start by $shift positions (may be negative)
##  + operates directly on $tied->{idxfh}
##  + doesn't change old values unless they are overwritten
sub shiftIndex {
  my ($tied,$start,$n,$shift) = @_;

  ##-- common variables
  my $idxfh  = $tied->{idxfh};
  my $len_ix = $tied->{len_ix};
  my $bsize  = $tied->{bsize} // 2**21;
  my $bstart = $len_ix * $start;
  my $bn     = $len_ix * $n;
  my $bshift = $len_ix * $shift;
  my ($buf,$boff,$blen);

  ##-- dispatch by shift direction
  if ($shift > 0) {
    ##-- shift right (copy right-to-left)
    CORE::seek($tied->{idxfh}, $bstart+$bn, SEEK_SET) or return undef;
    while ($bn > 0) {
      $blen = $bn > $bsize ? $bsize : $bn;
      CORE::seek($idxfh, -$blen, SEEK_CUR) or return undef;
      CORE::read($idxfh, $buf, $blen)==$blen or return undef;
      CORE::seek($idxfh, $bshift-$blen, SEEK_CUR) or return undef;
      $idxfh->print($buf) or return undef;
      CORE::seek($idxfh, -$bshift, SEEK_CUR) or return undef;
      $bn -= $blen;
    }
  } else {
    ##-- shift left (copy left-to-right)
    CORE::seek($tied->{idxfh}, $bstart, SEEK_SET) or return undef;
    while ($bn > 0) {
      $blen = $bn > $bsize ? $bsize : $bn;
      CORE::read($idxfh, $buf, $blen)==$blen or return undef;
      CORE::seek($idxfh, $bshift-$blen, SEEK_CUR) or return undef;
      $idxfh->print($buf) or return undef;
      CORE::seek($idxfh, -$bshift, SEEK_CUR) or return undef;
      $bn -= $blen;
    }
  }

  return $tied;
}



##======================================================================
## Object API

##--------------------------------------------------------------
## Object API: header

## @keys = $tied->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:file|mode|perms)$}} keys %{$_[0]};
}

## \%header = $tied->headerData()
##  + data to save as header
sub headerData {
  my $tied = shift;
  return {(map {($_=>$tied->{$_})} $tied->headerKeys), class=>ref($tied)};
}

## $tied_or_undef = $tied->loadHeader()
## $tied_or_undef = $tied->loadHeader($headerFile,%opts)
##  + loads header from "$tied->{file}.hdr"
##  + %opts are passed to loadJsonFile()
sub loadHeader {
  my ($tied,$hfile,%opts) = @_;
  $hfile //= $tied->{file}.".hdr" if (defined($tied->{file}));
  confess(ref($tied)."::loadHeader(): no header-file specified and no 'file' attribute defined") if (!defined($hfile));
  my $hdata = $tied->loadJsonFile($hfile,%opts)
    or confess(ref($tied)."::loadHeader(): failed to load header data from '$hfile'");
  @$tied{keys %$hdata} = values %$hdata;
  return $tied;
}

## $tied_or_undef = $tied->saveHeader()
## $tied_or_undef = $tied->saveHeader($headerFile)
##  + saves header data to $headerFile
##  + %opts are passed to saveJsonFile()
sub saveHeader {
  my ($tied,$hfile,%opts) = @_;
  $hfile //= $tied->{file}.".hdr" if (defined($tied->{file}));
  confess(ref($tied)."::saveHeader(): no header-file specified and no 'file' attribute defined") if (!defined($hfile));
  return $tied->saveJsonFile($tied->headerData(), $hfile, %opts);
}

##--------------------------------------------------------------
## Object API: open/close

## $tied_or_undef = $tied->open($file,$mode)
## $tied_or_undef = $tied->open($file)
## $tied_or_undef = $tied->open()
##  + opens file(s)
sub open {
  my ($tied,$file,$mode) = @_;
  $file //= $tied->{file};
  $mode //= $tied->{mode};
  $tied->close() if ($tied->opened);
  $tied->{file} = $file;
  $tied->{mode} = $mode = fcflags($mode);

  if (fcread($mode) && !fctrunc($mode)) {
    (!-e "$file.hdr" && fccreat($mode))
      or $tied->loadHeader()
      or confess(ref($tied)."::failed to load header from '$tied->{file}.hdr': $!");
  }

  $tied->{idxfh} = fcopen("$file.idx", $mode, $tied->{perms})
    or confess(ref($tied)."::open failed for index-file $file.idx: $!");
  $tied->{datfh} = fcopen("$file", $mode, $tied->{perms})
    or confess(ref($tied)."::open failed for data-file $file: $!");
  binmode($_) foreach (@$tied{qw(idxfh datfh)});

  ##-- pack lengths
  #use bytes; ##-- deprecated in perl v5.18.2
  $tied->{len_o}   = packsize($tied->{pack_o});
  $tied->{len_l}   = packsize($tied->{pack_l});
  $tied->{len_ix}  = $tied->{len_o} + $tied->{len_l};
  $tied->{pack_ix} = $tied->{pack_o}.$tied->{pack_l};

  return $tied;
}

## $tied_or_undef = $tied->close()
##   + close any opened file, writes header if opened in write mode
sub close {
  my $tied = shift;
  return $tied if (!$tied->opened);
  if ($tied->opened && fcwrite($tied->{mode})) {
    $tied->saveHeader() or
      confess(ref($tied)."::close(): failed to save header file");
  }
  delete @$tied{qw(idxfh datfh)}; ##-- should auto-close if not shared
  undef $tied->{file};
  return $tied;
}

## $bool = $tied->reopen()
##  + closes and re-opens underlying filehandles
##  + should cause a "real" flush even on systems without a working IO::Handle::flush
sub reopen {
  my $tied = shift;
  my ($file,$mode) = @$tied{qw(file mode)};
  return $tied->opened() && $tied->close() && $tied->open($file, $mode & ~O_TRUNC);
}

## $bool = $tied->opened()
##  + returns true iff object is opened
sub opened {
  my $tied = shift;
  return (ref($tied)
	  && defined($tied->{idxfh})
	  && defined($tied->{datfh})
	 );
}

## $tied_or_undef = $tied->flush()
## $tied_or_undef = $tied->flush($flushHeader)
##  + attempts to flush underlying filehandles using underlying filehandles' flush() method
##    (ususally IO::Handle::flush)
##  + also writes header file
##  + calls reopen() if underlying filehandles don't support a flush() method
sub flush {
  my ($tied,$flushHeader) = @_;
  my $rc = $tied->opened;
  if (0 && $rc && UNIVERSAL::can($tied->{idxfh},'flush') && UNIVERSAL::can($tied->{datfh},'flush')) {
    ##-- use fh flush() method
    $rc = $tied->{idxfh}->flush() && $tied->{datfh}->flush() && (!$flushHeader || $tied->saveHeaderFile());
  }
  else {
    ##-- use reopen()
    $rc = $tied->reopen();
  }
  return $rc ? $tied : undef;
}

##--------------------------------------------------------------
## Object API: file operations

## $tied_or_undef = $tied->unlink()
## $tied_or_undef = $tied->unlink($file)
##  + attempts to unlink underlying files
##  + implicitly calls close()
sub unlink {
  my ($tied,$file) = @_;
  $file //= $tied->{file};
  $tied->close();
  return undef if (!defined($file));
  foreach ('','.idx','.hdr') {
    CORE::unlink("${file}$_") or return undef;
  }
  return $tied;
}

## $tied_or_undef = $tied->rename($newname)
##  + renames underlying file(s) using CORE::rename()
##  + implicitly close()s and re-open()s $tied
##  + object must be opened in write-mode
sub rename {
  my ($tied,$newfile) = @_;
  my $flags   = fcflags($tied->{mode});
  my $oldfile = $tied->{file};
  return undef if (!$tied->opened() || !fcwrite($flags) || !$tied->close);
  foreach ('','.idx','.hdr') {
    CORE::rename("${oldfile}$_","${newfile}$_") or return undef;
  }
  return $tied->open($newfile, ($flags & ~O_TRUNC));
}

## $dst_object_or_undef = $tied_src->copy($dst_filename, %dst_opts)
## $dst_object_or_undef = $tied_src->copy($dst_object)
##  + copies underlying file(s) using File::Copy::copy()
##  + source object must be opened
##  + implicitly calls flush() on both source and destination objects
##  + if a destination object is specified, it must be opened in write-mode
sub copy {
  my ($src,$dst,%opts) = @_;
  return undef if (!$src->opened || !$src->flush);
  $dst = $src->new($dst, %opts, mode=>'rw') if (!ref($dst));
  return undef if (!$dst->opened && !$dst->open($opts{file}, 'rw'));

  foreach (qw(idxfh datfh)) {
    CORE::seek($src->{$_}, 0, SEEK_SET) or return undef;
    CORE::seek($dst->{$_}, 0, SEEK_SET) or return undef;
    File::Copy::copy($src->{$_}, $dst->{$_}) or return undef;
  }
  return $dst->flush();
}

## $tied_or_undef = $tied->move($newname)
##  + renames underlying file(s) using File::Copy::move()
##  + implicitly close()s and re-open()s $tied
##  + object must be opened in write-mode
sub move {
  my ($tied,$newfile) = @_;
  my $flags   = fcflags($tied->{mode});
  my $oldfile = $tied->{file};
  return undef if (!$tied->opened() || !fcwrite($flags) || !$tied->close);
  foreach ('','.idx','.hdr') {
    File::Copy::move("${oldfile}$_","${newfile}$_") or return undef;
  }
  return $tied->open($newfile, ($flags & ~O_TRUNC));
}



##--------------------------------------------------------------
## Object API: consolidate

## $tied_or_undef = $tied->consolidate()
## $tied_or_undef = $tied->consolidate($tmpfile)
##  + consolidates file data: ensures data in $tied->{datfh} are in index-order and contain no gaps or unused blocks
##  + object must be opened in write-mode
##  + uses $tmpfile as a temporary file for consolidation (default="$tied->{file}.tmp")
sub consolidate {
  my ($tied,$tmpfile) = @_;

  ##-- open tempfile
  $tmpfile //= "$tied->{file}.tmp";
  my $tmpfh = fcopen($tmpfile, $tied->{mode}, $tied->{perms})
    or confess(ref($tied)."::open failed for temporary data-file $tmpfile: $!");
  binmode($tmpfh);

  ##-- copy data
  my ($file,$idxfh,$datfh,$len_ix,$pack_ix) = @$tied{qw(file idxfh datfh len_ix pack_ix)};
  my ($buf,$off,$len);
  my $size = $tied->size;
  CORE::seek($idxfh, 0, SEEK_SET) or return undef;
  CORE::seek($tmpfh, 0, SEEK_SET) or return undef;
  for (my $i=0; $i < $size; ++$i) {
    CORE::read($idxfh, $buf, $len_ix)==$len_ix or return undef;
    ($off,$len) = unpack($pack_ix, $buf);

    ##-- update index record (in-place)
    CORE::seek($idxfh, $i*$len_ix, SEEK_SET) or return undef;
    $idxfh->print(pack($pack_ix, CORE::tell($tmpfh),$len)) or return undef;

    ##-- copy data record
    next if ($len == 0);
    CORE::seek($datfh, $off, SEEK_SET) or return undef;
    CORE::read($datfh, $buf, $len)==$len or return undef;
    $tmpfh->print($buf) or return undef;
  }

  ##-- close data-filehandles
  CORE::close($tmpfh)
      or confess(ref($tied)."::consolidate(): failed to close temp-file '$tmpfile': $!");
  CORE::close($datfh)
    or confess(ref($tied)."::consolidate(): failed to close old data-file '$file': $!");

  ##-- replace old datafile
  undef $tmpfh;
  undef $datfh;
  delete $tied->{datfh};
  CORE::unlink($file)
      or confess(ref($tied)."::consolidate(): failed to unlink old data-file '$tied->{file}': $!");
  #CORE::rename($tmpfile, $file) ##-- win32 chokes here with "Permission denied"
  File::Copy::move($tmpfile, $file)
      or confess(ref($tied)."::consolidate(): failed to move temp-file '$tmpfile' to '$file': $!");

  ##-- re-open
  $tied->{datfh} = fcopen("$file", (fcflags($tied->{mode}) & ~O_TRUNC), $tied->{perms})
    or confess(ref($tied)."::consolidate(): failed to re-open data-file $file: $!");

  return $tied;
}

##--------------------------------------------------------------
## Object API: advisory locking

## $bool = $tied->flock()
## $bool = $tied->flock($lock)
##  + get an advisory lock of type $lock (default=LOCK_EX) on $tied->{datfh}, using perl's flock() function
##  + implicitly calls flush() prior to locking
sub flock {
  my ($tied,$op) = @_;
  return undef if (!$tied->opened);
  $tied->flush();
  return CORE::flock($tied->{datfh}, ($op // LOCK_EX));
}

## $bool = $tied->funlock()
## $bool = $tied->funlock($lock)
##  + unlock $tied->{datfh} using perl's flock() function; $lock defaults to LOCK_UN
sub funlock {
  return $_[0]->flock( LOCK_UN | ($_[1]//0) );
}


##======================================================================
## API: Tied Array

##--------------------------------------------------------------
## API: Tied Array: mandatory methods

## $tied = tie(@array, $tieClass, $file,%opts)
## $tied = TIEARRAY($tieClass, $file,%opts)
BEGIN { *TIEARRAY = \&new; }

## $count = $tied->FETCHSIZE()
##  + like scalar(@array)
##  + re-positions $tied->{idxfh} to eof
BEGIN { *size = \&FETCHSIZE; }
sub FETCHSIZE {
  return undef if (!$_[0]{idxfh});
  #return ((-s $_[0]{idxfh}) / $_[0]{len_ix}); ##-- doesn't handle recent writes correctly (probably due to perl i/o buffering)
  ##
  CORE::seek($_[0]{idxfh},0,SEEK_END) or return undef;
  return CORE::tell($_[0]{idxfh}) / $_[0]{len_ix};
}

## $val = $tied->FETCH($index)
## $val = $tied->FETCH($index)
sub FETCH {
  ##-- sanity check
  return undef if ($_[1] >= $_[0]->size);

  ##-- get index record from $idxfh
  my ($off,$len) = $_[0]->readIndex($_[1]) or return undef;

  ##-- get data record from $datfh
  CORE::seek($_[0]{datfh}, $off, SEEK_SET) or return undef;
  return $_[0]->readData($len);
}

## $val = $tied->STORE($index,$val)
##  + no consistency checking or optimization; just appends a new record to the end of $datfh and updates $idxfh
sub STORE {
  ##-- append encoded record to $datfh
  CORE::seek($_[0]{datfh}, 0, SEEK_END) or return undef;
  my $off0 = CORE::tell($_[0]{datfh});
  $_[0]->writeData($_[2]) or return undef;
  my $off1 = CORE::tell($_[0]{datfh});

  ##-- update index record in $idxfh
  $_[0]->writeIndex($_[1], $off0, ($off1-$off0)) or return undef;

  ##-- return
  return $_[2];
}

## $count = $tied->STORESIZE($count)
## $count = $tied->STORESIZE($count) ##-- local extension
##  + modifies only $idxfh
sub STORESIZE {
  my $oldsize = $_[0]->size;
  if ($_[1] < $oldsize) {
    ##-- shrink
    CORE::truncate($_[0]{idxfh}, $_[1]*$_[0]{len_ix}) or return undef;
  } elsif ($_[1] > $oldsize) {
    ##-- grow (idxfh only)
    CORE::seek($_[0]{idxfh}, $_[1]*$_[0]{len_ix}-1, SEEK_SET) or return undef;
    $_[0]{idxfh}->print("\0");
  }
  return $_[1];
}

## $bool = $tied->EXISTS($index)
sub EXISTS {
  return $_[1] < $_[0]->size;
}

## undef = $tied->DELETE($index)
##  + really just wraps $tied->STORE($index,undef)
sub DELETE {
  return $_[0]->STORE($_[1],undef);
}

##--------------------------------------------------------------
## API: Tied Array: optional methods

## undef = $tied->CLEAR()
sub CLEAR {
  CORE::truncate($_[0]{idxfh}, 0) or return undef;
  CORE::truncate($_[0]{datfh}, 0) or return undef;
  return $_[0];
}

## $newsize = $tied->PUSH(@vals)
sub PUSH {
  my $tied = shift;

  CORE::seek($tied->{datfh}, 0, SEEK_END) or return undef;
  CORE::seek($tied->{idxfh}, 0, SEEK_END) or return undef;
  my ($off0,$off1);
  foreach (@_) {
    my $off0 = CORE::tell($tied->{datfh});
    $tied->writeData($_) or return undef;
    my $off1 = CORE::tell($tied->{datfh});

    ##-- update index record in $idxfh
    $tied->writeIndex(undef, $off0, ($off1-$off0)) or return undef;
  }

  return $tied->size if (defined(wantarray));
}

## $val = $tied->POP()
##  + truncates data-file if we're popping the final data-record
sub POP {
  return undef if (!(my $size=$_[0]->size));

  ##-- get final index record (& truncate it)
  my ($off,$len) = $_[0]->readIndex($size-1) or return undef;
  CORE::truncate($_[0]{idxfh}, ($size-1)*$_[0]{len_ix}) or return undef;

  ##-- get corresponding data-record
  CORE::seek($_[0]{datfh}, $off, SEEK_SET) or return undef;
  my $val = $_[0]->readData($len);

  ##-- maybe trim data-file
  CORE::truncate($_[0]{datfh}, $off) if (($off+$len) == (-s $_[0]{datfh}));
  return $val;
}

## $val = $tied->SHIFT()
##  + truncates data-file if we're shifting the final data-record
sub SHIFT {
  ##-- get first index record
  my ($off,$len) = $_[0]->readIndex(0) or return undef;

  ##-- defer to SPLICE
  my $val = $_[0]->SPLICE(0,1);

  ##-- maybe trim data-file
  CORE::truncate($_[0]{datfh}, $off) if (($off+$len) == (-s $_[0]{datfh}));
  return $val;
}

## @removed      = $tied->SPLICE($offset, $length, @newvals)
## $last_removed = $tied->SPLICE($offset, $length, @newvals)
sub SPLICE {
  my $tied = shift;
  my $size = $tied->size();
  my $off  = (@_) ? shift : 0;
  $off    += $size if ($off < 0);
  my $len  = (@_) ? shift : ($size-$off);
  $len    += $size-$off if ($len < 0);

  ##-- get result-list
  my ($i,@result);
  if (wantarray) {
    for ($i=$off; $i <= $len; ++$i) {
      push(@result, $tied->FETCH($i));
    }
  } elsif ($len > 0) {
    @result = ($tied->FETCH($off+$len-1));
  }

  ##-- shift post-splice index records (expensive, but generally not so bad as default Tie::Array iterated FETCH()+STORE())
  my $shift = scalar(@_) - $len;
  $tied->shiftIndex($off+$len, $size-($off+$len), $shift) if ($shift != 0);

  ##-- store new values
  for ($i=0; $i < @_; ++$i) {
    $tied->STORE($off+$i, $_[$i]);
  }

  ##-- maybe shrink array
  CORE::truncate($tied->{idxfh}, ($size+$shift)*$tied->{len_ix}) or return undef if ($shift < 0);

  ##-- return
  return wantarray ? @result : $result[0];
}

## @vals = $tied->UNSHIFT(@vals)
##  + just defers to SPLICE
sub UNSHIFT {
  return scalar shift->SPLICE(0,0,@_);
}

## ? = $tied->EXTEND($newcount)

1; ##-- be happpy
