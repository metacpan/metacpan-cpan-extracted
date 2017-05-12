package Tie::SymlinkTree;
use strict;
use bytes;
use Encode;
use Tie::Indexer;

our $VERSION = '1.1';

{
    package Tie::SymlinkTree::Array;
    sub id { tied(@{shift()})->id(@_) }
    sub search { tied(@{shift()})->search(@_) }
}

{
    package Tie::SymlinkTree::Hash;
    sub id { tied(%{shift()})->id(@_) }
    sub search { tied(%{shift()})->search(@_) }
}

sub encode_value {
  no bytes;
  my $val = shift;
  return undef if !defined $val;
  $val =~ s#\x{feff}#\x{feff}feff#g;
  $val =~ s#\x{0000}#\x{feff}0000#g;
  $val = "\x{feff}" if (length($val) == 0);
  $val = encode_utf8($val);
  return $val;
}

sub decode_value {
  no bytes;
  my $val = shift;
  return undef if !defined $val;
  $val = decode_utf8($val);
  $val = "" if ($val eq "\x{feff}");
  $val =~ s#\x{feff}0000#\x{0000}#g;
  $val =~ s#\x{feff}feff#\x{feff}#g;
  return $val;
}

sub encode_key {
  no bytes;
  my $key = shift;
  $key = '' if !defined $key;
  $key =~ s#\x{feff}#\x{feff}feff#g;
  $key =~ s#\x{0000}#\x{feff}0000#g;
  $key =~ s#/#\x{feff}002f#g;
  $key =~ s#^\.#\x{feff}002e#g;
  $key = "\x{feff}" if (length($key) == 0);
  $key = encode_utf8($key);
  return $key;
}

sub decode_key {
  no bytes;
  my $key = shift;
  return undef if !defined $key;
  $key = decode_utf8($key);
  $key = "" if ($key eq "\x{feff}");
  $key =~ s#\x{feff}002e#.#g;
  $key =~ s#\x{feff}002f#/#g;
  $key =~ s#\x{feff}0000#\x{0000}#g;
  $key =~ s#\x{feff}feff#\x{feff}#g;
  return $key;
}

sub TIEARRAY {
  my ($package, $path) = @_;
  my $self = (ref $package?$package:bless {}, $package);
  $self->{ARRAY} = 1;
  return $self->TIEHASH($path);
}

sub TIEHASH {
  my ($package, $path) = @_;
  die "usage: tie(%hash, 'Tie::SymlinkTree', \$path)" if @_ != 2;
  my $self = (ref $package?$package:bless {}, $package);
  
  $path =~ s#/*$#/#;
  die "$path is invalid" if $path =~ m#/\.\.?(/|$)#;
  die "$path is not a directory" if -e $path and -l $path;
  if (! -e $path) {
    mkdir $path or -d $path or die "Can't create $path: $!";
    symlink(".",$path.".array") if $self->{ARRAY};
  } # race condition: assigning array and hash to one location at the same time
  die "$path has wrong type" if (-e $path.".array" xor $self->{ARRAY});
  $self->{PATH} = $path;
  
  return $self;
}

sub FETCH {
  my ($self, $key) = @_;
  $key = encode_key($key);
  if (-d $self->{PATH}.$key) {
	if (-e $self->{PATH}.$key."/.array") {
	    my @tmp;
	    tie @tmp, ref($self), $self->{PATH}.$key;
	    return bless \@tmp, 'Tie::SymlinkTree::Array';
	} else {
	    my %tmp;
	    tie %tmp, ref($self), $self->{PATH}.$key;
	    return bless \%tmp, 'Tie::SymlinkTree::Hash';
	}
  } else {
	return decode_value(readlink($self->{PATH}.$key));
  }
}


sub STORE {
    my ($self, $key, $val, $recursion) = @_;
    $key = encode_key($key);
    die "no objects allowed" if ref($val) && ref($val) ne 'HASH' && ref($val) ne 'ARRAY';
    Tie::Indexer::deindex_node($self,$val,$key);
    if (!defined($val)) {
  	open(my $fh,'>',$self->{PATH}.".$$~".$key) || die "Error while storing: $!";
	close($fh);
	rename($self->{PATH}.".$$~".$key,$self->{PATH}.$key) or $recursion or do {$self->DELETE($_[1]);$self->STORE($_[1],$val,1);};
    } elsif (!ref($val)) {
  	symlink(encode_value($val),$self->{PATH}.".$$~".$key) || die "Error while storing: $!";
	rename($self->{PATH}.".$$~".$key,$self->{PATH}.$key) or $recursion or do {$self->DELETE($_[1]);$self->STORE($_[1],$val,1);};
    } elsif (ref($val) eq 'ARRAY' || ref($val) eq 'Tie::SymlinkTree::Array') {
  	my @tmp = @$val;
	eval { tie @$val, ref($self), $self->{PATH}.$key; };
	if (!$recursion && $@) {$self->DELETE($key);$self->STORE($_[1],$val,1);}
	@$val = @tmp;
    } else {
  	my %tmp = %$val;
	eval { tie %$val, ref($self), $self->{PATH}.$key; };
	if (!$recursion && $@) {$self->DELETE($key);$self->STORE($_[1],$val,1);}
	%$val = %tmp;
    }
    Tie::Indexer::index_node($self,$val,$key);
}


sub DELETE {
  my ($self, $key) = @_;
  $key = encode_key($key);
  my $val = $self->FETCH($key);
  Tie::Indexer::deindex_node($self,$val,$key);
  if (UNIVERSAL::isa($val,'ARRAY')) {
  	my @tmp = @$val;
	for my $i (0..$#tmp) {
	    $tmp[$i] = delete $val->[$i];
	}
	$val = \@tmp;
	unlink $self->{PATH}.$key."/.array";
  } elsif (UNIVERSAL::isa($val,'HASH')) {
  	my %tmp = %$val;
	for my $k (keys %tmp) {
	    $tmp{$k} = delete $val->{$k};
	}
	$val = \%tmp;
  } else {
        if (substr($self->id,0,1) ne '.' && -d $self->{PATH}."../.index-$key") {
	    my $path = $self->{PATH};
	    $path =~ s#[^/]*/$##;
	    tie my %index, ref($self), $path.".index-$key/";
	    delete $index{$val}{$self->id};
	}
  }
  unlink $self->{PATH}.$key;
  rmdir $self->{PATH}.$key;
  return $val;
}

sub _clear {
  my ($dir) = @_;
  die "empty directory" unless $dir;
  my $dh;
  opendir($dh,$dir);
  while (defined (my $subdir = readdir($dh))) {
  	next if ($subdir eq '.' || $subdir eq '..');
	unlink($dir.$subdir) or do {
		_clear($dir.$subdir."/");
		rmdir($dir.$subdir);
	}
  }
  closedir($dh);
}

sub CLEAR {
  my ($self) = @_;
  $self->lock;
  _clear($self->{PATH});
  $self->unlock;
}

sub EXISTS {
  my ($self, $key) = @_;
  $key = encode_key($key);
  return -e $self->{PATH}.$key || -l $self->{PATH}.$key;
}


sub DESTROY {
}


sub FIRSTKEY {
  my ($self) = @_;
  
  my $dh;
  opendir($dh,$self->{PATH});
  $self->{HANDLE} = $dh;
  my $entry;
  while (defined ($entry = readdir($self->{HANDLE}))) {
    return decode_key($entry) unless (substr($entry,0,1) eq '.');
  }
  return;
}


sub NEXTKEY {
  my ($self) = @_;
  my $entry;
  while (defined ($entry = readdir($self->{HANDLE}))) {
    return decode_key($entry) unless (substr($entry,0,1) eq '.');
  }
  return;
}

sub FETCHSIZE {
  my ($self) = @_;
  my $dh;
  opendir($dh,$self->{PATH});
  my $max = -1;
  my $entry;
  while (defined ($entry = readdir($dh))) {
    next if substr($entry,0,1) eq '.';
    $max = int($entry) if $entry > $max;
  }
  return $max+1;
}

sub STORESIZE {
  my ($self, $size) = @_;
  $self->lock;
  $size = int($size);
  while (-e $self->{PATH}.$size) {
  	$self->DELETE($size);
	$size++;
  }
  $self->unlock;
}

sub EXTEND { }
sub UNSHIFT { scalar shift->SPLICE(0,0,@_) }
sub SHIFT { shift->SPLICE(0,1) }

sub PUSH {
  my ($self, $value) = @_;
  $self->lock;
  my $key = $self->FETCHSIZE;
  $self->STORE($key,$value);
  $self->unlock;
  return $key+1;
}

sub POP {
  my ($self, $value) = @_;
  $self->lock;
  my $key = $self->FETCHSIZE-1;
  my $val = $self->FETCH($key);
  $self->DELETE($key);
  $self->unlock;
  return $val;
}

sub SPLICE {
    my $self = shift;
    $self->lock;
    my $size  = $self->FETCHSIZE;
    my $off = (@_) ? shift : 0;
    $off += $size if ($off < 0);
    my $len = (@_) ? shift : $size - $off;
    $len += $size - $off if $len < 0;
    my @result;
    for (my $i = 0; $i < $len; $i++) {
        push(@result,$self->FETCH($off+$i));
    }
    $off = $size if $off > $size;
    $len -= $off + $len - $size if $off + $len > $size;
    if (@_ > $len) {
        # Move items up to make room
        my $d = @_ - $len;
        my $e = $off+$len;
        for (my $i=$size-1; $i >= $e; $i--) {
	    rename($self->{PATH}.$i,$self->{PATH}.($i+$d));
        }
    }
    elsif (@_ < $len) {
        # Move items down to close the gap
        my $d = $len - @_;
        my $e = $off+$len;
        for (my $i=$off+$len; $i < $size; $i++) {
	    rename($self->{PATH}.$i,$self->{PATH}.($i-$d));
        }
    }
    for (my $i=0; $i < @_; $i++) {
        $self->STORE($off+$i,$_[$i]);
    }
    $self->unlock;
    return wantarray ? @result : pop @result;
}

sub lock {
  my ($self) = @_;
  if (!$self->{locked}++) {
	  my $i = 0;
	  while (!symlink($$,$self->{PATH}.".lock") && $i++ < 40) {
		select('','','',.25);
	  }
  }
}

sub unlock {
  my ($self) = @_;
  if (!--$self->{locked}) {
	  unlink($self->{PATH}.".lock");
  }
}

sub id {
    my ($self) = @_;
    return ($self->{PATH} =~ m{/([^/]+)/$})[0];
}

sub _get_index {
	my ($tie, $create) = @_;
	return undef if (!$create && ! -d $tie->{PATH}.".index/");
	tie my %index, ref($tie), $tie->{PATH}.".index/";
	return \%index;
}

BEGIN {
	*search = \&Tie::Indexer::search;
}

no warnings;
"Dahut!";
__END__

=head1 NAME

Tie::SymlinkTree - Prototype SQL-, Class::DBI- or Tie::*-using apps by storing data in a directory of symlinks

=head1 SYNOPSIS

 use Tie::SymlinkTree;
 tie %hash, 'Tie::SymlinkTree', '/some_directory';
 $hash{'one'} = "some text";         # Creates symlink /some_directory/one
                                     # with contents "some text"
 $hash{'bar'} = "some beer";
 $hash{'two'} = [ "foo", "bar", "baz" ];
 $hash{'three'} = {
   one => { value => 1, popularity => 'high'},
   two => { value => 2, popularity => 'medium'},
   four => { value => 4, popularity => 'low'},
   eleven => { value => 11, popularity => 'medium'},
 };

 # Warning: experimental and subject to change without notice:
 my @entries = tied(%hash)->search(sub { m/some/ }); # returns ("some text","some beer")
 my $firstmatch = $hash{'two'}->search(sub { m/b/ }); # returns "bar"
 my @result1 = $hash{'three'}->search('popularity','medium'); # returns ($hash{'three'}{'two'}, $hash{'three'}{'eleven'})
 my @result2 = $hash{'three'}->search('popularity','=','medium'); # the same
 my @result3 = $hash{'three'}->search('popularity',sub { $_[0] eq $_[1] },'medium'); # the same
 print $hash{'two'}->id; # prints out "two"

=head1 DESCRIPTION

The Tie::SymlinkTree module is a TIEHASH/TIEARRAY interface which lets you tie a
Perl hash or array to a directory on the filesystem.  Each entry in the hash
represents a symlink in the directory. Nested arrays and hashes are represented as
sugbdirectories.

For applications with small storage requirements, this module is perfectly capable of
production usage. For example, web applications with less than a few hundred users
should work great with this module.

To use it, tie a hash to a directory:

 tie %hash, "Tie::SymlinkTree", "/some_directory";

Any changes you make to the hash will create, modify, or delete
symlinks in the given directory. 'undef' values are represented by
an empty file instead of a symlink.

If the directory itself doesn't exist C<Tie::SymlinkTree> will
create it (or die trying).

This module is fully reentrant, multi-processing safe, and still real
fast (as the OS permits; a modern filesystem is recommended when storing
lots of keys/array elements).

=head1 CAVEATS

C<Tie::SymlinkTree> hashes behave 99% like classic perl hashes. Key ordering
differs, and may also depend on the order of insertion. Moreover, two distinct
hashes with equal contents may differ in key order.

C<Tie::SymlinkTree> is restricted in what it can store: Values are
limited in length, depending on OS limits (modern Linux boxes can
store 4095 bytes, older systems might only support 256). Scalars, hashrefs
and arrayrefs will be transparently mapped to subdirs as neccessary,
nested as deeply as you wish, but no objects are allowed.

This module will probably only work on UNIXish systems.

How fast are ties? I can't tell. That is the most important bottleneck left.
Searches over more than a few hundred entries are slow if you don't use indexing.
If you tend to do many different complex queries, you should switch to something
SQL-based.

=head1 RATIONALE

This module was designed for quick prototyping of multi-processing
applications as often found in CGI scripts. It uses the fastest way to store and
retrive small bits of information: Symlinks. "Small bits" is the key: most
web-centric tasks involve a need for permanent storage, yet the usage pattern
and data set size usually doesn't require a full SQL database.

Setting up a database schema and designing queries can be quite tedious when you're
doing a prototype. A tie is much easier to use, but the usual Tie::* modules
are lacking mp-safety or performance (or both), since they usually store the
hash data in one big chunk. C<Tie::SymlinkTree> avoids this bottleneck and source
of bugs by only using atomic OS primitives on individual keys. Locking is not
completely avoidable, but reduces to a minimum.

TODO: the next paragraphs talk about experimental stuff and/or stuff not yet implemented.
Calling this release version 1.0 refers to the tie syntax: It is stable and working as
expected, as plain-hash-compatible as it can get.

The primary purpose is to prototype apps quickly through very easy setup (nothing but a
writable location is needed), good performance and several upgrade paths: depending on
the interface you use, it's easy to model apps using plain DBI, Class::DBI, or just
any Tie-interface of your liking. Just exchange your objects to "the real thing" and you
are set.

Additionally, since Tie::SymlinkTree offers several APIs at once, you can
upgrade your prototypes' code without messy storage conversion steps: Write a quick
CGI on tied hashes, upgrade to a decent DBI-based application when complexity raises,
and model the final application using Class::DBI - all with the same storage.

=head1 AUTHOR and LICENSE

Copyright (C) 2004, JÃ¶rg Walter

This plugin is licensed under either the GNU GPL Version 2, or the Perl Artistic
License.

=cut

