# ddb by Dan Brumleve
# stupid berkeleydb always corrupts my files

package ddb;
use POSIX qw(:sys_wait_h);
use Fcntl qw(:seek :flock O_RDONLY O_RDWR O_TRUNC O_CREAT);
use Digest::MD5;

BEGIN {
  eval { require File::Sync; };
  $@ and *File::Sync::fsync = sub { 1 };
}

# usage
#
# use ddb;
# $db = tie %db, ddb, 'file.ddb';
# 
# $db{$key} = $val;
# ...
#
# $db->repair;
# $db->defrag;
# untie %db;

# globals
$VERSION	= '1.3.1';
$hash_size	= 16381; # default, or pass to tie after filename
$sentinel	= 1;
$empty_buf_size	= 256;
$magic		= 0xDDB10000;
$debug		= 0;
$max_procs	= 10; # for test
$show_step	= 100;
$ptr_pos	= undef;

# file format
#
# [magic, int32] [hash_size, int32] [hash_table, hash_size * int32]
# ... [record] ... [record] ... [record] ...

# record format
#
# [sentinel, byte] [next_pos, int32]
# [key_len int32] [key, key_len * byte]
# [padding, 0-3 bytes] [val_hash int32]
# [val_len int32] [val, val_len * byte]
#
# in between each record can be zero or more null-bytes of free space.
# the hash table values are absolute file offsets pointing to the
# first byte of a record.  all int32s are big-endian and aligned.
# so every sentinel byte position % 4 == 3.

# tie implementation comes first

sub EXISTS {
  my ($db, $key) = @_;

  $db->lock_sh;
  my ($pos, $next_pos) = $db->find($key);
  $db->lock_un;

  defined($pos)
}

sub FETCH {
  my ($db, $key) = @_;
  my $val;

  $db->lock_sh;
  my ($pos, $next_pos) = $db->find($key);
  defined $pos or goto DONE;

  $val = $db->read_val(length($key));

DONE:
  $db->lock_un;
  $val
}

sub STORE {
  my ($db, $key, $val) = @_;

  unless (defined $val) {
    # how else to make it undef?
    $db->DELETE($key);
    return undef;
  }

  $db->lock_ex;
  my ($pos, $next_pos) = $db->find($key);

  if (defined($pos)) {
    my $key_len = length($key);
    my $val_len = length($val);
    $db->align_val($key_len);
    $db->seek(4, SEEK_CUR);
    my $old_val_len = $db->read_int;

    if ($old_val_len < $val_len) {
      my $rec = $db->pack_rec($key, $val, $next_pos);
      $db->append_rec($rec);
      my $old_rec_len = $db->rec_len($key_len, $old_val_len);
      $db->erase($pos, $old_rec_len);
    } else {
      $db->replace_val($key, $val, $pos, $next_pos, $old_val_len);
    }
  } else {
    my $rec = $db->pack_rec($key, $val, 0);
    $db->append_rec($rec);
  }

  $db->lock_un;
  $val
}

sub DELETE {
  my ($db, $key) = @_;
  my $val;

  $db->lock_ex;
  my ($pos, $next_pos) = $db->find($key);
  defined $pos or goto DONE;

  my $key_len = length($key);
  $val = $db->read_val($key_len);
  my $val_len = length($val);

  $db->seek($ptr_pos, SEEK_SET);
  $db->write_int($next_pos);
  $db->sync;

  my $rec_len = $db->rec_len($key_len, $val_len);
  $db->erase($pos, $rec_len);
  $db->sync;

DONE:
  $db->lock_un;
  $val
}

sub CLEAR {
  my $db = shift;

  $db->lock_ex;
  $db->seek(0, SEEK_SET);
  $db->write_int($magic);
  $db->write_int($db->{hash_size});
  $db->write_zero(4 * $db->{hash_size});

  my $pos = $db->tell;
  $db->truncate($pos);

  $db->sync;
  $db->lock_un;
  ( )
}

sub NEXTKEY {
  my $db = shift;

  $db->lock_sh;
  my ($pos, $key) = $db->next_pos;
  $db->lock_un;

  $key
}

sub FIRSTKEY {
  my $db = shift;
  undef $db->{cur_hash};
  @{$db->{cur_keys}} = ( );
  $$db{rec_count} = 0;
  $db->NEXTKEY
}

sub TIEHASH {
  my ($p, $filename, $hash_size) = @_;

  my $db = bless {
    fh		=> undef,
    filename	=> $filename,
    hash_size	=> $hash_size,
    cur_hash	=> undef,
    cur_keys	=> [ ],
    rec_count	=> 0,
    lock_count	=> 0,
    lock_type	=> undef,
  }, $p;

  $db->reopen;

  $db->lock_ex;
  my $end_pos = $db->seek(0, SEEK_END);

  if ($end_pos == 0) {
    my $hash_size = $db->{hash_size} || $ddb::hash_size;
    $db->warn("empty, creating $hash_size hash entries");
    $db->write_int($magic);
    $db->write_int($hash_size);
    $db->write_zero(4 * $hash_size);
    $end_pos = $db->tell;
  }

  $db->seek(0, SEEK_SET);
  local $ptr_pos = 'magic';
  my $check_magic = $db->read_int;
  pack('N', $check_magic) eq pack('N', $magic) or
    $db->die("bad magic $check_magic");

  local $ptr_pos = 'hash_size';
  $db->{hash_size} = $db->read_int;

  my $min_size = $db->data_section;
  $end_pos < $min_size and
    $db->die("file truncated, $end_pos / $min_size expected bytes");
  $db->sync;
  $db->lock_un;

  $db
}

sub UNTIE {
  my $db = shift;

  $db->{lock_count} = 0;
  $db->{lock_type} = undef;
  @{$db->{cur_keys}} = ( );
  $db->{rec_count} = 0;
  $db->{cur_hash} = undef;

  close $db->{fh};
  undef $db->{fh};
}


# now everything else, bottom-up

sub data_section {
  my $db = shift;
  8 + 4 * $db->{hash_size}
}

sub rec_len {
  my ($db, $key_len, $val_len) = @_;
  17 + $key_len + (-$key_len % 4) + $val_len
}

sub key_hash {
  my ($db, $key) = @_;
  my $hash = 0;
  $hash ^= $_ for unpack 'N4', Digest::MD5::md5($key);
  $hash % $db->{hash_size}
}

sub val_hash {
  my ($db, $val) = @_;
  my $hash = 0;
  $hash ^= $_ for unpack 'N4', Digest::MD5::md5($val);
  # no modulus
  unpack 'l', pack 'l', $hash
}

sub key_hash_pos {
  my ($db, $hash) = @_;
  8 + 4 * $hash
}

sub cur_keys {
  my $db = shift;
  @{$db->{cur_keys}}
}

sub die {
  my ($db, $msg) = @_;

  $msg ||= $! . "\n";
  unless ($msg =~ /\n$/) {
    my $pos = $db->tell;
    $msg .= " at $pos";
    defined($ptr_pos) and $msg .= " from $ptr_pos";
    $msg .= "\n";
  }

  $db->{lock_count} > 0 and $db->lock_un;
  die "$0: $$db{filename}: $msg";
}

sub warn {
  my ($db, $msg) = @_;

  $msg ||= $! . "\n";
  unless ($msg =~ /\n$/) {
    $msg .= "\n";
  }

  warn "$0: $$db{filename}: $msg";
}

sub show_status {
  my $db = shift;

  defined($$db{cur_hash}) or return;
  my $last_complete = int(100 * ($$db{cur_hash} - 1) / $$db{hash_size});
  my $complete = int(100 * $$db{cur_hash} / $$db{hash_size});
  $last_complete == $complete && $$db{rec_count} % $show_step and return;
  my $nl = ($complete == 100) ? "  \r\n" : "  \r";
  print STDERR "$0: $$db{rec_count} records, $complete% complete  $nl";
}


# file operations

sub sync {
  my $db = shift;
  File::Sync::fsync($db->{fh}) or $db->warn('fsync failed');
}

sub tell {
  my $db = shift;
  sysseek $db->{fh}, 0, SEEK_CUR
}

sub seek {
  my ($db, $where, $whence) = @_;
  sysseek $db->{fh}, $where, $whence
}

sub truncate {
  my ($db, $size) = @_;
  truncate($db->{fh}, $size)
}

sub read {
  my ($db, undef, $len) = @_;
  my $check_len = sysread($db->{fh}, $_[1], $len);
  unless ($check_len == $len) {
    my $pos = $db->tell - $check_len;
    $db->die("cannot read $len bytes");
  }
  $_[0]
}

sub read_byte {
  my $db = shift;
  $db->read(my $p_byte, 1);
  unpack C => $p_byte
}

sub read_sentinel {
  my $db = shift;
  my $byte = $db->read_byte;
  $byte eq $sentinel or $db->die("bad sentinel $byte");
}

sub read_int {
  my $db = shift;

  if ($debug) {
    my $pos = $db->tell;
    $pos % 4 and $db->warn(
      "misaligned read_int at $pos" .
      (defined($ptr_pos) ? " from $ptr_pos" : "")
    );
  }

  $db->read(my $p_int, 4);
  my $int = unpack 'l', pack 'l', unpack 'N', $p_int;

  $int
}

sub read_empty {
  my $db = shift;
  my $total = 0;

  while ((my $buf_size = sysread($db->{fh}, my $buf, $empty_buf_size)) > 0) {
    $buf =~ /^(\0*)/;
    my $empty = length($1);
    $total += $empty;

    if ($empty < $buf_size) {
      $db->seek($empty - $buf_size, SEEK_CUR);
      last;
    }
  }

  $total
}

sub read_key {
  my ($db, $pos, $end_pos) = @_;

  $db->read_sentinel;
  my $next_pos = $db->read_int;
  my $key_len = $db->read_int;

  if (@_ > 1) {
    $key_len < 0 || $pos + 9 + $key_len > $end_pos and
      $db->die("key_len $key_len out of bounds");
  }

  $db->read(my $key, $key_len);
  wantarray ? ($key, $next_pos, $key_len) : $key
}

sub read_val {
  my ($db, $key_len, $pos, $end_pos) = @_;

  $db->align_val($key_len);
  my $val_hash = $db->read_int;
  my $val_len = $db->read_int;
  my $rec_len = $db->rec_len($key_len, $val_len);

  if (@_ > 2) {
    $val_len < 0 || $pos + $rec_len > $end_pos and
      $db->die("val_len $val_len out of bounds");
  }

  $db->read(my $val, $val_len);
  wantarray ? ($val, $val_hash, $rec_len) : $val
}

sub read_rec {
  my ($db, $pos, $end_pos) = @_;
  my ($key, $next_pos, $key_len) = $db->read_key($pos, $end_pos);
  my ($val, $val_hash, $rec_len) = $db->read_val($key_len, $pos, $end_pos);
  ($key, $val, $next_pos, $val_hash, $rec_len)
}

sub align_val {
  my ($db, $key_len) = @_;
  $db->seek((defined($key_len) ? -$key_len : -$db->tell) % 4, SEEK_CUR);
}

sub write {
  my ($db, $str) = @_;

  my $len = length($str);
  my $check_len = syswrite($db->{fh}, $str, $len);

  unless ($check_len == $len) {
    my $missed = $check_len - $len;
    $db->die("cannot write $missed/$check_len bytes");
  }

  $len
}

sub write_byte {
  my ($db, $byte) = @_;
  $db->write(pack C => $byte)
}

sub write_sentinel {
  my $db = shift;
  $db->write_byte($sentinel)
}

sub write_int {
  my ($db, $int) = @_;

  if ($debug) {
    my $pos = $db->tell;
    $pos % 4 and $db->warn(
      "misaligned write_int at $pos" .
      (defined($ptr_pos) ? " from $ptr_pos" : "")
    );
  }

  $db->write(pack 'N', $int);
}

sub write_key {
  my ($db, $key) = @_;
  my $lkey = pack('N', length($key)) . $key;
  $db->write($lkey)
}

sub write_val {
  my ($db, $val) = @_;
  my $val_hash = $db->val_hash($val);
  my $lval = pack('NN', $val_hash, length($val)) . $val;
  $db->write($lval)
}

sub write_zero {
  my ($db, $len) = @_;
  $db->write("\0" x $len)
}

sub pack_rec {
  my ($db, $key, $val, $next_pos, $val_hash) = @_;

  my $val_align = "\0" x (-length($key) % 4);
  defined($val_hash) or $val_hash = $db->val_hash($val);

  my $rec = join '',
    pack('C', $sentinel),
    pack('N', $next_pos),
    pack('N', length($key)), $key,
    $val_align,
    pack('N', $val_hash),
    pack('N', length($val)), $val,
    ;

  if ($debug) {
    length($rec) == $db->rec_len(length($key), length($val))
      or $db->warn('record length problem');
  }

  $rec
}

sub write_rec {
  my ($db, $pos, $rec) = @_;

  $db->seek($pos, SEEK_SET);

  if ($debug) {
    $db->tell % 4 == 3 or $db->warn("writing misaligned record at $pos");
  }

  $db->write($rec);
  $db->sync;

  $db->seek($ptr_pos, SEEK_SET);
  $db->write_int($pos);
  $db->sync;
}

sub append_rec {
  my ($db, $rec) = @_;

  # prewrite zero for file integrity
  my $pos = $db->seek(0, SEEK_END);
  my $align = 3 - $pos % 4;
  $pos += $align;
  $db->write_zero($align + length($rec));

  $db->write_rec($pos, $rec);

  $pos
}

sub move_rec {
  my ($db, $rec, $old_pos, $new_pos) = @_;
  my $rec_len = length($rec);

  # always move backwards
  if ($old_pos < $new_pos + $rec_len) {
    # swap using the end of the file as a buffer
    my $tmp_pos = $db->append_rec($rec);
    $db->erase($old_pos, $rec_len);
    $db->write_rec($new_pos, $rec);
    $db->truncate($tmp_pos);
  } else {
    $db->write_rec($new_pos, $rec);
    $db->erase($old_pos, $rec_len);
  }
  
  $new_pos
}

sub replace_val {
  my ($db, $key, $val, $pos, $next_pos, $old_val_len) = @_;

  my $val_len = length($val);
  my $val_hash = $db->val_hash($val);
  my $rec = $db->pack_rec($key, $val, $next_pos, $val_hash);
  my $val_pos = $pos + length($rec) - $val_len - 8;

  my $new_pos = $db->append_rec($rec);

  # put it back where it was
  $db->seek($val_pos + 8, SEEK_SET);
  $db->write($val . ("\0" x ($old_val_len - $val_len)));

  $db->seek($val_pos, SEEK_SET);
  $db->write_int($val_hash);
  $db->write_int($val_len);

  $db->seek($ptr_pos, SEEK_SET);
  $db->write_int($pos);
  $db->sync;

  $db->truncate($new_pos);

  $pos
}

sub lock_ex {
  my $db = shift;
  $$ == $db->{pid} or $db->reopen;

  if ($db->{lock_count} > 0) {
    # this is allowed by flock but it releases the LOCK_SH
    # while waiting for the LOCK_EX to avoid deadlock.
    # ddb disallows it to avoid any confusion; just
    # LOCK_UN first if you want the flock behavior.
    $db->{lock_type} == LOCK_EX or $db->die("lock conversion");
  } elsif ($db->{lock_count} == 0) {
    RETRY: unless (flock($db->{fh}, LOCK_EX)) {
      $db->warn("flock error, retrying: $!");
      $db->reopen;
      goto RETRY;
    }
  } else {
    $db->die("negative lock count");
  }

  $db->{lock_type} = LOCK_EX;
  ++$db->{lock_count}
}

sub lock_sh {
  my $db = shift;
  $$ == $db->{pid} or $db->reopen;

  if ($db->{lock_count} == 0) {
    RETRY: unless (flock($db->{fh}, LOCK_SH)) {
      $db->warn("flock error, retrying: $!");
      $db->reopen;
      goto RETRY;
    }
    $db->{lock_type} = LOCK_SH;
  } elsif ($db->{lock_count} < 0) {
    $db->die("negative lock count");
  }

  ++$db->{lock_count}
}

sub lock_un {
  my $db = shift;

  if ($db->{lock_count} < 1) {
    $db->warn("no locks held");
    flock($db->{fh}, LOCK_UN);
    0
  } elsif ($db->{lock_count} == 1) {
    flock($db->{fh}, LOCK_UN);
    undef $db->{lock_type};
    --$db->{lock_count}
  } else {
    --$db->{lock_count}
  }
}

sub lock   { shift->lock_ex }
sub unlock { shift->lock_un }

# we call this after fork so locks work again
sub reopen {
  my $db = shift;

  $db->{fh} and close $db->{fh};
  undef $db->{fh};
  if ($db->{lock_count} > 0) {
    $db->warn('reopening with held locks');
    undef $db->{lock_type};
    $db->{lock_count} = 0;
  }

  sysopen($db->{fh}, $db->{filename}, O_RDWR | O_CREAT) or $db->die;
  binmode $db->{fh};

  $db->{pid} = $$; # keep track of forks

  $db
}

sub find {
  my ($db, $key) = @_;

  my $hash = $db->key_hash($key);
  $ptr_pos = $db->key_hash_pos($hash);

  $db->seek($ptr_pos, SEEK_SET);
  my $pos = $db->read_int;
  my %loop_test; # debug

  while ($pos != 0) {
    $pos % 4 == 3 && $pos >= 0 or
      $db->die("found misaligned record");

    if ($debug) {
      $loop_test{$pos}++ and
        $db->die("loop record");
    }

    $db->seek($pos, SEEK_SET);
    my ($check_key, $next_pos) = $db->read_key;

    $check_key eq $key and
      return wantarray ? ($pos, $next_pos) : $pos;

    $ptr_pos = $pos + 1;
    $pos = $next_pos
  }

  ( )
}

sub erase {
  my ($db, $pos, $rec_len) = @_;
  $db->seek($pos, SEEK_SET);
  $db->write_zero($rec_len);
  $rec_len
}

# no rec_len known
sub erase_panic {
  my ($db, $pos, $status_cb) = @_;
  $status_cb ||= sub { };
  $db->$status_cb(0);

  my $end_pos = $db->seek(0, SEEK_END);

  local $db->{cur_keys} = [ ];
  local $db->{cur_hash} = undef;
  local $db->{rec_count} = 0;
  my $count = 0;
  
  while (1) {
    my ($k_pos, $k) = $db->next_pos;
    defined($k_pos) or last;
    $db->$status_cb(++$count);
    $k_pos > $pos or next;
    $k_pos < $end_pos and $end_pos = $k_pos;
  }
  
  my $rec_len = $end_pos - $pos;
  $db->warn("erasing corrupted record at $pos+$rec_len");

  $db->seek($pos, SEEK_SET);
  $db->write_zero($rec_len);

  $rec_len
}

# during iteration we preload a hash-bucket at a time and
# check each key right before returning it.

sub next_pos {
  my ($db, $status_cb) = @_;
  $status_cb ||= sub { };

  $db->{cur_keys} ||= [ ];
  my $cur_keys = $db->{cur_keys};
  my $end_pos = $db->seek(0, SEEK_END);

  while (1) {
    while (defined(my $key = shift @$cur_keys)) {
      my ($pos, $next_pos) = $db->find($key);
      if (defined($pos)) {
        ++$db->{rec_count};
        return ($pos, $key);
      }
      $debug and $db->warn("skipping unlinked cached record");
    }

    $db->{cur_hash} =
      defined($db->{cur_hash}) ?
      $db->{cur_hash} + 1 : 0;
    $db->$status_cb;
    unless ($db->{cur_hash} < $db->{hash_size}) {
      undef $db->{cur_hash};
      return ( );
    }

    $ptr_pos = $db->key_hash_pos($db->{cur_hash});
    $db->seek($ptr_pos, SEEK_SET);
    my $pos = $db->read_int;

    my %loop_test; # debug-only

    while ($pos != 0) {
      $pos % 4 == 3 && $pos >= 0 or
        $db->die("misaligned record");

      if ($debug) {
        $loop_test{$pos}++ and
          $db->die("loop found");
      }

      $db->seek($pos, SEEK_SET);
      my ($key, $next_pos, $key_len) = $db->read_key($pos, $end_pos);

      if ($debug) {
        $db->{cur_hash} == $db->key_hash($key) or
          $db->die("key_hash mismatch");

        my ($val, $val_hash) = $db->read_val($key_len, $pos, $end_pos);
        my $check_val_hash = $db->val_hash($val);
        $check_val_hash == $val_hash or
          $db->die("val_hash mismatch");
      }

      push @$cur_keys, $key;
      $ptr_pos = $pos + 1;
      $pos = $next_pos
    }
  }
}

# scan the data section linearly and remove empty space
sub defrag {
  my ($db, $status_cb) = @_;
  $status_cb ||= sub { };

  local $debug = 1;

  $db->lock_ex;
  my $end_pos = $db->seek(0, SEEK_END);
  $db->$status_cb(0, $end_pos);
  
  my $empty_pos = $db->data_section;
  my $empty_len = 0;
  
  while ($empty_pos < $end_pos) {
    $db->seek($empty_pos + $empty_len, SEEK_SET);
    $empty_len += $db->read_empty;
    my $pos = $empty_pos + $empty_len;

    unless ($pos < $end_pos) {
      $empty_pos < $end_pos and $db->truncate($end_pos = $empty_pos);
      last;
    }

    sub ep_status_cb
      { shift->$status_cb($empty_pos, $end_pos - $empty_len, @_) }
    ep_status_cb($db);
    $ptr_pos = "defrag $pos";

    $db->lock_ex;
    my ($key, $val, $next_pos, $val_hash, $rec_len) = eval {
      $db->read_rec($pos, $end_pos)
    };
    if ($@) {
      warn($@);
      $empty_len += $db->erase_panic($pos, \&ep_status_cb);
      next;
    }
    $db->lock_un;

    my $check_val_hash = $db->val_hash($val);

    my $check_pos = $db->find($key);
    unless ($check_pos == $pos) {
      if ($check_val_hash == $val_hash) {
        if (defined($check_pos)) {
          # this can delete indexed data in a pathological case
          # (a corrupted record with valid hash that overlaps indexed
          # records, very unlikely by accident).  but it's doesn't
          # have to scan the entire database like erase_panic.
        
          $db->warn("erasing unlinked record at $pos+$rec_len");
          $empty_len += $db->erase($pos, $rec_len);
        } else {
          # this record is left over from an aborted delete or
          # part of a chain after an erased corrupted record,
          # so we relink it.

          $db->warn("relinking unlinked record at $pos+$rec_len");

          $db->seek($pos + 1, SEEK_SET);
          $db->write_int(0);

          $db->seek($ptr_pos, SEEK_SET);
          $db->write_int($pos);
          $db->sync;
        }
      } else {
        $db->warn("val_hash mismatch at $pos+$rec_len");
        $empty_len += $db->erase_panic($pos, \&ep_status_cb);
      }
      next;
    }

    $check_val_hash == $val_hash or
      $db->die("val_hash mismatch");

    my $align = 3 - $empty_pos % 4;
    $empty_pos += $align;
    $empty_len -= $align;

    if ($empty_len > 0) {
      my $rec = $db->pack_rec($key, $val, $next_pos, $val_hash);
      $db->move_rec($rec, $pos, $empty_pos);
    } else {
      # should never happen
      $empty_len = 0;
    }

    $empty_pos += $rec_len;
  }
  
  $db->sync;
  $db->$status_cb($end_pos, $end_pos);
  $db->lock_un;
}

# this will null out any pointers to corrupted records
sub repair {
  my ($db, $status_cb) = @_;
  $status_cb ||= sub { };

  local $debug = 1;
  local $db->{cur_keys} = [ ];
  local $db->{cur_hash} = undef;
  local $db->{rec_count} = 0;

  $db->lock_ex;

  while (1) {
    $db->lock_sh;
    my $pos = eval { $db->next_pos($status_cb) };

    unless ($@) {
      $db->lock_un;
      defined($pos) or last;
      $db->$status_cb;
      next;
    }
    warn $@;

    unless ($ptr_pos > 0) {
      $db->warn("bad ptr $ptr_pos, cannot repair bucket $$db{cur_hash}");
      next;
    }

#    $db->seek($ptr_pos, SEEK_SET);
#    my $pos = $db->read_int;
#    $db->seek($pos, SEEK_SET);
#    $db->lock_sh;
#    my ($key, $next_pos) = eval { $db->read_key };
#    $@ or $db->lock_un;
#    $next_pos ||= 0;
#    $next_pos == $ptr_pos - 1 and $next_pos = 0; # loops

    my $next_pos = 0;
    $db->warn("unlinking from $ptr_pos, to $next_pos (run defrag)");
    $db->seek($ptr_pos, SEEK_SET);
    $db->write_int($next_pos);
  }

  $db->sync;
  $db->lock_un;
}

# run a bunch of tests.  this will erase your database.
sub test {
  my ($db, $db_hash, $ok_cb) = @_;

  ref($db_hash) or $db->die('test requires ref to tied hash');
  local *db = \%$db_hash;
  tied(%db) == $db or $db->die('tied hash does not match object');

  $ok_cb ||= sub { $_[2] or $_[0]->die("not ok $_[1]\n") };
  sub ok { $db->$ok_cb(@_) }

  local $SIG{PIPE} = sub { };
  local $debug = 1;
  my $procs = 0;

  ok 0, 65;

  # clear
  $db->{hash_size} = 19;
  %db = ( );

  # store, fetch, delete, exists
  $db{hello} = 'world';
  ok 1, $db{hello} eq 'world';
  ok 2, 'world' eq delete $db{hello};
  ok 3, !exists $db{hello};

  # small key and value
  $db{''} = '';
  ok 4, exists $db{''};
  ok 5, defined $db{''};
  ok 6, $db{''} eq '';
  ok 7, '' eq delete $db{''};
  ok 8, keys(%db) == 0;

  # parallel inserts
  for my $key (1 .. 100) {
    wait, --$procs until $procs < $max_procs;
    ++$procs; fork and next;
    $db{$key} = $key; 
    exit 0;
  }
  --$procs until wait < 0;
  delete $db{50};

  my ($ksum, $vsum);
  $ksum += $_ for keys %db;
  $vsum += $_ for values %db;
  ok 9, keys(%db) == 99;
  ok 10, $ksum == 5000;
  ok 11, $vsum == 5000;

  # swap a bunch of values with recursive locks in parallel
  for (1 .. 99) {
    wait, --$procs until $procs < $max_procs;
    ++$procs; fork and next;
    my $key1 = 1 + int rand 49;
    my $key2 = 51 + int rand 49;
    $db->lock_ex;
    @db{$key1, $key2} = @db{$key2, $key1};
    $db->lock_un;
    exit 0;
  }
  --$procs until wait < 0;

  my $sum = 0; $sum += $_ for values %db;
  ok 12, $sum == 5000;
  ok 13, scalar grep $_ ne $db{$_}, keys %db; # odd number of swaps

  # remove half the keys, making holes for defragging
  $_ & 1 or delete $db{$_} for 1 .. 100;
  ok 14, keys(%db) == 50;

  # defragging does not change iteration order
  my $db_str0 = join ":", map "$_-$db{$_}", keys %db;
  $db->defrag;
  my $db_str1 = join ":", map "$_-$db{$_}", keys %db;
  ok 15, $db_str0 eq $db_str1;

  # big values
  my $big = 100000;
  $db{'x' x $big} = 'y' x $big;
  ok 16, $db{'x' x $big} eq 'y' x $big;
  ok 17, $procs == 0;

  # growing values in parallel
  while (my ($k, $v) = each %db) {
    wait, --$procs until $procs < $max_procs;
    ++$procs; fork and next;
    $db{$k} = $v . $v;
    exit 0;
  }
  --$procs until wait < 0;

  ok 18, keys(%db) == 51;
  ok 19, $db{'x' x $big} eq 'y' x (2 * $big);
  ok 20, exists $db{51};

  # defrag should shrink after value growth
  my $end0 = $db->seek(0, SEEK_END);
  $db->defrag;
  my $end1 = $db->seek(0, SEEK_END);
  ok 21, $end1 < $end0;

  # but not again
  $db->defrag;
  my $end2 = $db->seek(0, SEEK_END);
  ok 22, $end1 == $end2;

  # clear should truncate
  %db = ('a' .. 'z');
  my $end3 = $db->seek(0, SEEK_END);
  ok 23, $end3 < $end2;
  ok 24, values(%db) == 13;

  $db->reopen;
  ok 25, join('', map $_ . $db{$_}, sort keys %db) eq join('', 'a' .. 'z');

  # grow a value for a while and add noise in front of it
  %db = ( );
  $db{a} = 'a' x $_ for 1 .. 5;
  my $offset = $db->data_section + 20;
  $offset += 3 - $offset % 4;
  $db->seek($offset, SEEK_SET);
  $db->write(pack('C', $sentinel) . "\x02\x03\x04\x05");

  # defrag should erase the noise and warn
  $db->warn("warnings expected on test 26");
  $db->defrag;
  my $end4 = $db->seek(0, SEEK_END);
  my $check_end4 = $db->data_section;
  $check_end4 += 3 - $check_end4 % 4;
  $check_end4 += $db->rec_len(1, 5);
  ok 26, $end4 == $check_end4;
  ok 27, $db{a} eq 'a' x 5;

  $db{pack 'C', $_} = $_ for 0 .. 255;
  ok 28, $db{a} == ord 'a';

  # skeet-shooting test
  $db->warn("warnings permitted on test 29");
  my @pid;

  $SIG{ALRM} = sub { };
  for (1 .. $max_procs) {
    if (my $pid = fork) {
      ++$procs;
      push @pid, $pid;
      next;
    }
    $db{pack 'C', int rand 256} = 'x';
    exit 0;
  }
  undef $SIG{ALRM};

  while ($procs > 0)  {
    kill ALRM => $_ for @pid;
    select undef, undef, undef, 0.1;
    --$procs while waitpid(-1, &WNOHANG) > 0;
  }

  $db->defrag;
  ok 29, join('', sort keys %db) eq pack('C*', 0 .. 255);
  ok 30, $procs == 0;

  # delete future records while iterating
  $db->warn("warnings permitted on test 31");
  my $total = 256;
  while (my ($k, $v) = each %db) {
    my $unp_k2 = 2 * unpack('C', $k);
    my $k2 = pack('C', $unp_k2);
    if (exists $db{$k2}) {
      --$total;
      delete $db{$k2};
    }
  }

  ok 31, keys(%db) == $total;

  while (my $k = each %db) { delete $db{$k}; }
  ok 32, keys(%db) == 0;

  $db->defrag;
  my $size = $db->seek(0, SEEK_END);
  ok 33, $size == $db->data_section;

  for (1 .. 100) {
    if ($_ & 1) {
      $db{$_} = 'x' x $_;
    } else {
      $db{'x' x $_} = $_;
    }
  }

  ok 34, length($db{87}) == 87;
  ok 35, $db{'x' x 50} == 50;

  # link corruption
  %db = (1 .. 200);

  my ($pos, $next_pos) = $db->find(101);
  ok 36, defined($pos);
  $db->seek($ptr_pos, SEEK_SET);
  $db->write("\xFF" x 4); # oops

  my ($pos, $next_pos) = $db->find(99);
  ok 37, defined($pos);
  $db->seek($ptr_pos, SEEK_SET);
  $db->write("\xFE" x 4); # oops again

  $db->warn("warnings expected on test 38");
  $db->repair;
  ok 38, keys(%db) <= 98;
  ok 39, !exists $db{101}; 
  ok 40, !exists $db{99}; 

  $db->warn("warnings expected on test 41");
  $db->defrag;
  ok 41, keys(%db) == 100;

  # no warnings
  my $keys = keys(%db);
  $db->repair;
  $db->defrag;
  ok 42, keys(%db) == $keys;

  my $end_pos = $db->seek(0, SEEK_END);
  my $key = 'hello';
  $db{$key} = 'world';
  my $keys = keys(%db);
  my ($pos) = $db->find($key);
  ok 43, defined($pos);

  # corrupt a sentinel, expect error
  $db->warn('warnings expected on test 44');
  $db->seek($pos, SEEK_SET);
  $db->write("\x03");
  eval { my @keys = keys %db };
  $@ and warn $@;
  ok 44, $@;

  # fix the hash table
  $db->warn('warnings expected on test 45');
  $db->repair;
  ok 45, !exists $db{$key};
  ok 46, keys(%db) < $keys;

  # fix the data
  $db->warn('warnings expected on test 47');
  my $keys = keys(%db);
  $db->defrag;
  ok 47, keys(%db) == $keys;
  ok 48, $db->seek(0, SEEK_END) == $end_pos;

  $db->lock_sh;
  my ($k_pos, $k) = $db->next_pos;
  $db->lock_un;
  ok 49, defined($k_pos) && defined($k);

  # defrag fails on bad link
  $db->warn('warnings expected on test 50');
  $db->seek($k_pos + 1, SEEK_SET);
  $db->write("\x07" x 4);
  eval { $db->defrag };
  $@ and warn $@;
  ok 50, $@;

  # fix it
  $db->warn('warnings expected on test 51');
  $db->repair;
  $db->defrag;
  ok 51, exists $db{$k};

  # write random data
  $db->warn('warnings expected on test 52');
  %db = ( );
  $db{$_} = 'x' x $_ for 1 .. 100;
  $db->seek(1139, SEEK_SET);
  $db->write(pack 'C*', map int(rand(256)), 1 .. 101);

  $db->repair;
  $db->defrag;

  my $keys = keys %db;
  ok 52, $keys > 0;
  ok 53, $keys < 100;

  # no warnings
  $db->repair;
  $db->defrag;
  ok 54, keys(%db) == $keys;

  # loop test
  $db{$_} = 'x' x $_ for 1 .. 200;
  my $keys = 200;
  my ($k1_pos, $k1) = $db->next_pos;
  ok 55, defined($k1_pos);
  my ($k2_pos, $k2) = $db->next_pos;
  ok 56, defined($k2_pos);
  my ($k3_pos, $k3) = $db->next_pos;
  ok 57, defined($k3_pos);
  ok 58, $db->{cur_hash} == 0;

  $db->warn('warnings expected on test 59');
  $db->seek($k2_pos + 1, SEEK_SET);
  $db->write_int($k1_pos);
  $db->repair;
  $db->defrag;

  ok 59, exists $db{$k1};
  ok 60, exists $db{$k2};
  ok 61, exists $db{$k3};
  ok 62, keys(%db) == $keys;

  # ultimate test
  $db->warn('warnings expected on test 63');
  $db->seek(8, SEEK_SET);
  $db->write_int(int rand(1 << 16)) for 1 .. 3000;

  $db->seek($db->key_hash_pos($db->key_hash('hello')), SEEK_SET);
  $db->write_int(0);
  $db{hello} = 'world';

  $db->repair;
  $db->defrag;
  ok 63, $db{hello} eq 'world';

  # no warnings or truncation
  my $size = $db->seek(0, SEEK_END);
  $db->repair;
  $db->defrag;
  ok 64, $db->seek(0, SEEK_END) == $size;
  ok 65, keys(%db) == 1;

  1
}

1
# the end
