#!/usr/bin/perl -l
package VirtualFS::ISO9660;
require 5.005_003;	# only tested on 5.8.0.

use strict;
use warnings;

use Scalar::Util qw(dualvar);
use File::Spec;
use Carp qw(carp croak);
use Fcntl ':mode';
use Symbol;	# need geniosym

# for debugging
#require Data::Dumper;

our $VERSION = 0.02;

our ($SEPARATOR_1, $SEPARATOR_2, $A_CHARACTERS, $D_CHARACTERS);
{ no strict 'vars';
	*SEPARATOR_1 = \ '.';
	*SEPARATOR_2 = \ ';';
	*D_CHARACTERS = \ '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
	*A_CHARACTERS = \ q# !"%&'()*+,-./0123456789:;<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ_#;
}


# see ECMA-119 for official ISO9660 format (available free of charge)
# http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-119.pdf

use constant { CDROM_SECTOR_SIZE => 2048, VOLUME_DESCRIPTOR_SECTOR => 16 };

sub new {
	my $class = shift;
	my $filename = shift or croak "No filename specified for " . __PACKAGE__ . "->new";
	my %options = @_;	# rest is in hash format
	CORE::open (my $fh, '<', $filename) or return;	# let *them* handle open failures!
	binmode $fh;
	
	my $buffer;
	# try not to croak() unless it's the fault of the caller.
	# that means, among other things, simply return undef (indicating an error)
	# when the format of the ISO is invalid.

	# read the boot-record volume descriptor
	__readsectors($fh, $buffer, VOLUME_DESCRIPTOR_SECTOR) or return;
	my $voldesc = __extract_voldesc($buffer);
	
	# read the path table
	# the path table is, for whatever reason, a brief listing of every directory
	# on the disc.  There are efefctively three copies of this; one has its integers
	# MSB-first, one has them LSB-first, and the third would be the actual complete
	# pile of directory entries.
	__readsectors($fh, $buffer, $voldesc->{lpathlocation}, 
			int (($voldesc->{pathtablesize} + CDROM_SECTOR_SIZE - 1) / CDROM_SECTOR_SIZE));
	my $pathtree = __build_pathtree(__extract_pathtable($buffer, $voldesc->{pathtablesize}));
	#print Data::Dumper::Dumper($pathtree);
	bless [$fh, $voldesc, $pathtree], $class;
}

# open a fake directory handle. $dirh->readdir() will do what you think it would.
# opendir(dirh, path);
# opendir(dirh, '/foo/bar/baz') opens /foo/bar/baz
# opendir(dirh, '/foo/bar/baz/') opens /foo/bar/baz
# opendir(dirh, 'foo/bar/baz') opens /foo/bar/baz
sub opendir {
	my $this = shift;
	my $loc;
	my $treepos = $this->[2];
	my (undef, $path) = @_;
	my @parts = grep {!/^$/} File::Spec->splitdir($path);	# ignore blank parts
	if (@parts) {
		for (@parts) {
			unless ($treepos = $treepos->[1]{+uc}) {
				$! = "Path part not found: $_";
				return;
			}
		}
		$loc = $treepos->[0];
	} else {
		# treat the root directory specially
		$loc = $this->[1]{rootdir}{location};
	}

	# FIXME: use File::Spec
	$_[0] = VirtualFS::ISO9660::DirHandle->__new($this->[0], $loc, $this, join('/', @parts) );
}

sub open {
	my $this = shift;
	croak "need 3-argument open" unless @_ == 3;
	croak "2nd arg must be '<'" unless $_[1] eq '<';
	my @stats = $this->stat($_[2]) or croak "can't stat $_[2]: $!";
	croak "can't open() a directory" if S_ISDIR($stats[2]);
	$_[0] = Symbol::geniosym();
	tie( *{$_[0]}, 'VirtualFS::ISO9660::FileHandle', $this->[0], $stats[1], $this)
		and return 1;
}

sub stat {
	my $this = shift;
	my $filename = uc shift; # note the call to uc; ISO9660 names are all UPPERCASE
	my $ref;
	my $version;
	# FIXME: use File::Spec
	$filename = '/'.$filename unless $filename =~ m#^/#;
	if ($filename =~ s/;(.*)//) {
		$version = $1-1;
	}
	unless (exists($this->[4]{$filename})) {
		my (undef, $path, undef) = File::Spec->splitpath($filename);
		$this->opendir(my $dirh, $path) or croak "can't open path $path: $!";
		() = $dirh->readdir();	# in list context -- this will read thru the entire dir, populating the cache
		croak "can't find file $filename" unless exists($this->[4]{$filename});
	}
	$ref = $this->[4]{$filename};
	unless (defined($version)) { $version = $#$ref; }
	croak "version $version of $filename doesn't exist" unless defined $ref->[$version];
	$ref = $ref->[$version][1];
	return $this->__stat($ref);
}


# ============================================================
#                         accessors
# ============================================================

# $o->identifier()
#		returns a hash containing the keys 'system', 'volume', 
#		'volume_set', 'publisher', 'preparer', and 'application',
#		as well as their corresponding values (of course).
#	$o->identifier(key)
#		assuming 'key' matches one of the above keys, returns the
#		value for that key.
# $o->identifier(key1, key2, key3)
#			assuming that key1,key2,key3 each match one of the above keys,
#		returns a list containing the values for those keys, in the
#		same order.

sub identifier {
	my $this = shift;
	if (@_ == 0) {
		# return a hashref
		my %h;
		
		@h{'system', 'volume', 'volume_set', 'publisher', 'preparer', 'application'} =
			@{$this->[1]}{'system_id', 'volume_id', 'volume_set_id', 'publisher_id', 'preparer_id', 'application_id'};
		return %h;
	} else {
		my @list = @{$this->[1]}{ map "$_\_id", @_ };
		return wantarray?@list:pop@list;
	}
}


# $o->id_file()
#		See the 'identifier' method; only, the keys here are:
#		'copyright', 'abstract', and 'biblio'.

sub id_file {
	my $this = shift;
	if (@_ == 0) {
		# return a hashref
		my %h;
		
		@h{'copyright', 'abstract', 'biblio'} =
			@{$this->[1]}{'copyright_file', 'abstract_file', 'biblio_file'};
		return %h;
	} else {
		my @list = @{$this->[1]}{ map "$_\_file", @_ };
		return wantarray?@list:pop@list;
	}
}

# $o->extract_file()
# 		$o->extract_file('/COPYRIGH', 'to-file');
#	This is done using CORE::open on the to-file, which means that
# in perl 5.8.0 you can do:
#			$o->extract_file('/COPYRIGH', \$scalar);
#	and the contents of the file will be extracted into $scalar.

sub extract_file {
	my $this = shift;
	croak 'usage: extract_file(iso-filename, output-filename)' unless @_>=2;
	my $from = shift;
	my $to = shift;
	$this->open(my $infh, '<', $from) or return;	# eh, right now open() will croak anyway.
	CORE::open(my $outfh, '>', $to);
	local $\;	# don't let $\ screw with us
	while(read($infh, my $buf, 4096)) { print $outfh $buf; }
}
	
# ============================================================
#                    internal functions
# ============================================================



# read a sector or sectors from the image
# usage: __readsectors(filehandle, buffer, start[, count])
# count defaults to 1 if not specified. And don't specify a 0.
#
# on success, returns 1   (a partial read is considered failure)
# on failure, returns undef
sub __readsectors {
	my $count = $_[3] || 1;
	unless (seek($_[0], $_[2] * CDROM_SECTOR_SIZE, 0)) { return }
	my $ret = read($_[0], $_[1], $count * CDROM_SECTOR_SIZE);
	unless ($ret == $count * CDROM_SECTOR_SIZE) { return }
	return 1;
}

# path table record (ECMA-119 section 9.4)
# see extract_direntry and extrapolate for basic use
sub __extract_pathtablerec {
	my %h;
	my $sref = ref($_[0])?$_[0]:\$_[0];
	my $len = unpack('C', $$sref);
	@h{'LEN-EAR', 'location', 'parent', 'name'} =
		unpack("x C V v A$len x![v]", $$sref);
	
	if (ref $_[0]) {
		my $totallen = 1 + 1 + 4 + 2 + $len + ($len&1);
		${$_[1]} -= $totallen if ref $_[1];
		substr($$sref, 0, $totallen, '');
	}
	return \%h;
}

# extract_pathtable($scalar, $pathtablesize)
#   extracts all the path table entries from $scalar
#	also, there'd sure as hell better be $pathtablesize bytes worth of entries
#	in there...
# in scalar context, returns an arrayref
sub __extract_pathtable {
	my @table;
	my $data = shift;
	my $left = shift;
	
	push @table, __extract_pathtablerec(\$data, \$left)
		while $left>0;

	return \@table;
}

# build_pathtree(\@array)
# 	returns a convenient hashref of all the directories.
sub __build_pathtree {
	my $h;
	my @hrefs;
	my $i=0;
	for (@{$_[0]}) {
		unless (@hrefs) {	# special case: the root directory
			$hrefs[0] = $h = [$_->{parent}];
			$i++;
			next;
		}
		$hrefs[$_->{parent} - 1][1]{ $_->{name} } =
			$hrefs[$i] = [ $_->{location} ];
		$i++;
	}
	return $h;
}

# directory record (ECMA-119 section 9.1)
# 		extract_direntry($scalar)
# returns a happy hashref.
#
# alternatively, you can do:
#		 __extract_direntry(\$scalar)
# which, in addition to returning the hashref, eats the directory
# entry out of $scalar.

sub __extract_direntry {
	my %h;
	my $sref = ref($_[0])?$_[0]:\$_[0];	# make sure we have a reference to ease unpacking
	
	@h{'LEN-DR', 'LEN-EAR', 'location', 'size', 'time', 'flags', 'unitsize',
		'gapsize', 'volseqnum', 'name'} = unpack(
			'C C Vx[N] Vx[N] a7 C C C vx[n] C/a', $$sref);

	# if they gave us a reference, eat the data out of the scalar.
	if (ref $_[0]) { substr($$sref, 0, $h{'LEN-DR'}, ''); }
	
	return \%h;
}

# volume descriptor (ECMA-119 section 8)
# __extract_voldesc($scalar)
sub __extract_voldesc {
	my %h;
	
	@h{'type', 'stdid', 'version'} = 
		unpack('CA5C', $_[0]);
	
	# how we grok the rest depends on the type.
	# 0=Boot record
	# 1=Primary volume descriptor
	# 2=Supplementary volume descriptor
	# 3=Volume partition descriptor
	# 4-254=RFU
	# 255=Volume descriptor set terminator
	
	if ($h{type} == 0) {
		# section 8.2: boot record
		@h{'sysid','bootid'} = unpack('x7A32A32', $_[0]);
	} elsif ($h{type} == 1) {
		# section 8.4: primary volume descriptor
		@h{'system_id', 'volume_id', 'size', 'setsize', 'seqnum', 'blocksize',
			'pathtablesize', 'lpathlocation', 'optlpathlocation',
			#'mpathlocation', 'optmpathlocation', 
			'rootdir',
			'volume_set_id', 'publisher_id', 'preparer_id', 'application_id', 
			'copyright_file', 'abstract_file', 'biblio_file',
			'create_time', 'modify_time', 'expire_time', 'effective_time',
			'format_version'} = unpack(q{
				x7		# skip over the 7 bytes we pulled out at the very beginning
				x		# byte 8 is RFU and should be 0 in the Primary Volume Descriptor
						# (probably for alignment purposes)
				A32		# System Identifier
				A32		# Volume Identifier
				x8		# RFU, should be 0
				V		# Volume Space Size	
				x[N]	# Volume Space Size again, only in Motorola order
				x32		# another RFU
				vx[n]	# Volume Set Size and its motorola form
				vx[n]	# Volume Sequence Number
				vx[n]	# Logical Block Size
				Vx[N]	# Path Table Size
				V		# Type L path table location
				V		# Type L path table location (Optional)
				x[N]	# Type M path table location
				x[N]	# Type M path table location (Optional)
				a34		# 'Directory Record for Root Directory' (??? wtf?)
				A128	# Volume Set Identifier
				A128	# Publisher Identifier
				A128	# Data Preparer Identifier
				A128	# Application Identifier
				A37		# Copyright File Identifier
				A37		# Abstract File Identifier
				A37		# Bibliographic File Identifier
				a17		# Volume Creation Timestamp
				a17		# Volume Modification Timestamp
				a17		# Volume Expiration Timestamp
				a17		# Volume Effective Timestamp
				C		# File Structure Version
				x		# RFU
			}, $_[0]);
			
		$h{rootdir} = __extract_direntry($h{rootdir});
	} elsif ($h{type} == 2) { 
		# section 8.5, Supplementary Volume Descriptor
		# gahhhh...
	} elsif ($h{type} == 3) {
		# section 8.6, Volume Partition Descriptor
		@h{'sysid', 'partition_id', 'partition_location', 'partition_size'} = 
			unpack('x7xA32A32Vx[N]Vx[N]', $_[0]);
	}
	return \%h;
}

# $obj->__startpos('/path/to/filename')
# returns the offset into the .ISO file where you can find the contents of that
# file (for debugging purposes).
sub __startpos {
	my $this = shift;
	my @x = $this->stat($_[0]);
	return undef unless @x;	# no data? give up.
	# $x[1] will point to the info object
	return ($x[1]{location} * CDROM_SECTOR_SIZE);
}

sub __stat {
	my $this = shift;
	my $ref = shift;
	
	my $perms = S_IRUSR|S_IRGRP|S_IROTH;	# everybody can read
											# nobody can write (ISO9660 is readonly)
											# nobody can execute (how's it gonna be executed?)
											
	if ($ref->{flags} & 2) {
		$perms |= S_IFDIR;
	} else {
		$perms |= S_IFREG;
	}
		
	return (
		$this,				# "device number", return this object
		$ref,				# "inode number", return the cache ref
		$perms,				# permissions
		1,					# number of hard links
		0,					# uid
		0,					# gid
		0,					# rdev(???)
		$ref->{size}, 		# size
		0,					# atime
		0,					# mtime
		0,					# ctime
		CDROM_SECTOR_SIZE,	# blksize
		int(($ref->{size} + CDROM_SECTOR_SIZE - 1) / CDROM_SECTOR_SIZE),	# block count
	);
}

package VirtualFS::ISO9660::DirHandle;

use Scalar::Util qw(dualvar);
use constant { CDROM_SECTOR_SIZE => 2048 };

*__extract_direntry = \&VirtualFS::ISO9660::__extract_direntry;

# new (iso_filehandle, sector, ISO9660 object, pathname)
# pathname won't start with '/', nor will it end with one.
sub __new {
	my $class = shift;
	my ($fromfh, $sector, $parent, $name) = @_;
	
	CORE::open(my $fh, '<&', $fromfh) or return;
	seek($fh, $sector * CDROM_SECTOR_SIZE, 0);
	# / (root) and /any/dir/here are different in that the former
	# ends in /, while the latter does not.  This causes confusion.

	# FIXME: use File::Spec
	$name = '/'.$name if $name ne '';
	bless [$fh, $sector, 0, $parent, $name, undef], $class;
}

sub rewinddir {
	my $this = shift;
	$this->[2] = 0;
	seek($this->[0], $this->[1] * CDROM_SECTOR_SIZE, 0);
}

# merely for completeness
sub closedir {}

sub readdir {
	if (wantarray) {
		my $this = shift;
		my @x;
		my $x;
		push @x, $x while $x=$this->__readdir;
		return @x;
	} else {
		goto &__readdir;
	}
}

sub __readdir {
	# $this->
	# [0] = filehandle of ISO image
	# [1] = sector to start at
	# [2] = byte offset within directory
	# [3] = VirtualFS::ISO9660 object that spawned us (used for caching)
	# [4] = path of directory, parts separated by '/' and ending with '/'
	# [5] = total size of directory, undef if we don't know it yet.
	
	my ($buf, $len);
	
	# check EOF (err, EOD)
	return if (defined($_[0][5]) && $_[0][5] <= $_[0][2]);
	
	read($_[0][0], $len, 1)==1 or return;	# find out the size of the entry
	$len = unpack('C',$len);
	return unless $len;						# I can't find what officially marks the end,
											# but this seems to work

	seek($_[0][0], -1, 1)   or return;
	my $where = tell($_[0][0]);
	read($_[0][0], $buf, $len)==$len or return;
	$_[0][2] += $len;
	my $info = __extract_direntry($buf);
	# cache the location of this file for future reference
	
	# if there's a version (;<number>), extract it.
	if ($info->{name} =~ s/;(.*)//) {
		$info->{version} = $1-1;	
	} else {
		$info->{version} = dualvar(0, ''); # this is equivalent to, but distinguishable from, an explicit version of 1.
	}
	$info->{name} =~ s/\.$//; # remove any trailing .'s
	
	# if $this->[5] is undef, then this is the very first entry in the directory.
	if ($info->{name} eq "\c@") { 
		$_[0][5] = $info->{size};
		$info->{name} = '.';
		if ($_[0][4] eq '') {
			# special case to cache the root directory
			$_[0][3][4]{'/'}[$info->{version}] = [$where, $info];
		}
	} elsif ($info->{name} eq "\cA") {
		$info->{name} = '..';
	} else {
		# not a special name; cache this entry.
		# FIXME: use File::Spec
		$_[0][3][4]{$_[0][4] . '/' . $info->{name}}[$info->{version}] = [$where, $info];
	}
	return $info->{name};
}

1;

package VirtualFS::ISO9660::FileHandle;

use constant { CDROM_SECTOR_SIZE => 2048 };

# TIEHANDLE (iso_filehandle, info, ISO9660 object)

sub TIEHANDLE {
	my $class = shift;
	my ($fromfh, $info, $parent) = @_;
	open(my $fh, '<&', $fromfh) or return;
	seek($fh, $info->{location} * CDROM_SECTOR_SIZE, 0) or return;
	
	bless [$fh, $info, $parent, 
				$info->{location} * CDROM_SECTOR_SIZE,		# byte 0 is here
				$info->{location} * CDROM_SECTOR_SIZE + $info->{size} # EOF is here
		  ], $class;
}

# no need to support WRITE -- the ISO format is read-only except when it's being
# built from scratch.
# Same goes for PRINT and PRINTF.

# We need: READ, READLINE, and GETC.

sub GETC {
	my $this = shift;
	my $ret;
	my $where = tell($this->[0]);
	# if we're "outside" the file, fail
	return undef unless $where >= $this->[3] && $where < $this->[4];
	read($this->[0], $ret, 1) == 1 or return;
	return $ret;
}

sub READ {
	my $this = shift;
	# READ(buffer, len, offset)
	my (undef,$len,$ofs) = @_;
	$ofs = 0 unless defined($ofs);
	my $b = \$_[0];
	# don't read past the end of our virtual file!
	if ($len > $this->[4] - tell($this->[0])) { $len = $this->[4] - tell($this->[0]); }
	# if $len ends up being 0 bytes, bail
	return 0 unless $len>0;
	return read($this->[0], $$b, $len, $ofs);
}

# My wish: That Perl_do_readline (pp_hot.c) was nice enough to provide readline()
# on tied filehandles by falling back to $obj->READ.  This would do two things:
#	-> Simplify this object
#	-> As it is presently implemented, future extensions to how <$fh> handles
#		$RS or $/ won't work here, as we are effectively reimplementing 
#		Perl_do_readline() here.  If  Perl_do_readline() worked by calling our
#		READ method, however, it would work fine.

sub __READLINE {
	my $buf;
	my $len = 0;
	my $rlen;
	
	# read 4K of data at a time until we get something or run out of file.
	$rlen = $len = READ($_[0], $buf, 4096);
	until ($rlen==0 || (defined($/) && $buf =~ m[\Q$/]g)) {	# the g makes perl set pos()
		$len += ($rlen = READ($_[0], $buf, 4096, $len));
	}
	return undef if ($len == 0); # no more file!
	return $buf if ($rlen == 0); # we ate the rest of the file!
	$rlen = pos($buf);
	substr($buf, $rlen, $len-$rlen, '');	# eat the rest of the buffer
	seek($_[0][0], $rlen-$len, 1);			# and fix the file position
	return $buf;
}


sub READLINE {
	if (wantarray) {
		my @lines;
		my $line;
		push @lines, $line while defined($line = $_[0]->__READLINE);
		return @lines;
	}
	goto &__READLINE;
}

sub STAT {
	my $this = shift;
	return $this->[2]->__stat($this->[1]);
}
