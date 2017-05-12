# Copyright (c) 1998 Martin Hamilton.  All rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# $Id: Digest.pm,v 1.2 1999/03/12 19:05:30 martin Exp $

package WebCache::Digest;

use strict;
use vars qw($VERSION);

use Carp;
use IO::Socket;
use MD5;
use Sys::Hostname;


$VERSION = "1.00";


sub new {
  my ($this, %args) = @_;
  my $class = ref($this) || $this;
  my ($a, $v);
  my ($self) = {};

  while(($a, $v) = each %args) { $self->{$a} = $v; }
  bless $self, $class;

  return $self;
}


sub create {
  my($self,%args) = @_;
  my($a, $v);

  # set defaults
  $self->{capacity} = 500;     # number of URLs in digest - variable
  $self->{bits_per_entry} = 5; # bits per entry - set in store_digest.c

  # override defaults with arguments to object creation
  while(($a, $v) = each %args) { $self->{$a} = $v; }

  $self->{size_in_bytes} =
    int(($self->{capacity} * $self->{bits_per_entry} + 7) / 8);
  $self->{bit_count} = $self->{size_in_bytes} * 8;

  # This is the actual digest, and it's initially all zeroes
  @{ $self->{cdigest} } = unpack("C*", 0x00 x $self->{size_in_bytes});

  $self->{current_version} = 5;
  $self->{required_version} = 3;
  $self->{count} = 0;
  $self->{del_count} = 0;
  $self->{hash_func_count} = 4;
  $self->{reserved_short} = 0;
  $self->{reserved} = 0;
}


sub fetch {
  my($self, %args) = @_;
  my($sock, $digest, $digest_length, $content_length, $nread, $buffer);
  my($host) = $args{host};
  my($port) = $args{port};

  $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);
  unless(defined($sock)) {
    carp "$0: couldn't connect to the server $host on port $port: $!";
    return 0;
  }

  print $sock 
"GET http://$host:$port/squid-internal-periodic/store_digest HTTP/1.0\r\n\r\n";

  # Skip HTTP headers - XXX need to check status code here
  while(<$sock>) {
#      print ">> skipping $_";
    if (/^Content-Length: (\d+)/i) {
      $content_length = $1;
      $digest_length = $content_length - 128;
#      print ">>>> got Content-Length of $content_length\n";
    }
    last if /^\r?$/;
  }

  # Cache digest control block: (header for cache digest)
  $nread = read($sock, $buffer, 128);# || die "$0: sysread failed: $!";
  $self->{header} = $buffer;
#  print "number of digest header bytes read: $nread\n";
#  print "raw buffer:\n" . unpack("H*", $buffer) . "\n";

  $nread = read($sock, $buffer, $digest_length);

#  print "number of digest bytes read: $nread\n";
#  print "raw buffer:\n" . unpack("H*", $buffer) . "\n";

  close($sock);
  $self->unpack_header;
  @{ $self->{cdigest} } = unpack("C*", $buffer);
  return 1;
}


sub unpack_header {
  my($self) = @_;

  ($self->{current_version}, $self->{required_version}, $self->{capacity},
   $self->{count}, $self->{del_count}, $self->{size_in_bytes},
   $self->{bits_per_entry}, $self->{hash_func_count},
   $self->{reserved_short}, $self->{reserved})
     = unpack("n n N N N N C C n C*", $self->{header});
}


sub pack_header {
  my($self) = @_;

  $self->{header} = pack("n n N N N N C C n C104",
                           $self->current_version,
                           $self->required_version, $self->capacity,
                           $self->count, $self->del_count,
                           $self->size_in_bytes, $self->bits_per_entry,
                           $self->hash_func_count, $self->reserved_short,
                           $self->reserved);
}


sub dump_header {
  my($self) = @_;

  return
    "Current version:      " . $self->current_version  . "\n" .
    "Required version:     " . $self->required_version . "\n" .
    "Capacity:             " . $self->capacity         . "\n" .
    "Count:                " . $self->count            . "\n" .
    "Deletion count:       " . $self->del_count        . "\n" .
    "Size in bytes:        " . $self->size_in_bytes    . "\n" .
    "Bits per entry:       " . $self->bits_per_entry   . "\n" .
    "Hash function count:  " . $self->hash_func_count  . "\n";
}


# return raw header, digest, header fields...
sub header           { shift->{header}; }
sub digest           { pack("C*", @{ shift->{cdigest} }); }
sub current_version  { shift->{current_version}; }
sub required_version { shift->{required_version}; }
sub capacity         { shift->{capacity}; }
sub count            { shift->{count}; }
sub del_count        { shift->{del_count}; }
sub size_in_bytes    { shift->{size_in_bytes}; }
sub bits_per_entry   { shift->{bits_per_entry}; }
sub hash_func_count  { shift->{hash_func_count}; }
sub reserved_short   { shift->{reserved_short}; }
sub reserved         { shift->{reserved}; }


# XXX - should load/save be network order or host order ?

sub save {
  my($self, $filename) = @_;

  unless(open(OUT, ">$filename")) {
    carp "$0: couldn't open $filename: $!";
    return 0;
  }

  print OUT $self->pack_header;
  print OUT $self->digest;
  print "digest is... " . unpack("H*", $self->digest) . "\n";

  # XXX check written correct number of bytes here
  close(OUT);
  return 1;
}


sub load {
  my($self, $filename) = @_;
  my($size) = -s "$filename";
  my($digest);

  unless(open(IN, "$filename")) {
    carp "$0: couldn't open $filename: $!";
    return 0;
  }

  read(IN, $self->{header}, 128);
  read(IN, $digest, $size - 128); # XXX check on size here

  close(IN);
  $self->unpack_header;
  @{ $self->{cdigest} } = unpack("C*", $digest);
  return 1;
}


sub lookup {
  my($self, $method, $url) = @_;
  my(@hash_keys) = $self->calc_hash_key($method, $url);
  my($hit_potential) = 0;
  my($val, $i);

  for $i (0 .. 3) {
    $val = $self->bit_test($hash_keys[$i]);
    $val = 1 if $val >= 1;
    $hit_potential += $val;
  }

  return 1 if ($hit_potential >= 4);
  return 0;
}


sub register {
  my($self, $method, $url) = @_;
  my(@hash_keys) = $self->calc_hash_key($method, $url);
  my($i);

  for $i (0 .. 3) {
    $self->bit_set($hash_keys[$i]);
  }
  $self->{count} ++;

  return 1;
}


sub bit_test {
  my($self, $bit) = @_;
  my($byte, $test);

  $byte = int($bit / 8);
  $test = 1 << ($bit % 8);
  return (@{ $self->{cdigest} }[$byte] & $test);
}


sub bit_set {
  my($self, $bit) = @_;
  my($byte, $test);

  $byte = int($bit / 8);
  $test = 1 << ($bit % 8);
  @{ $self->{cdigest} }[$byte] |= $test;

   ##printf("byte: %x, test: %x\n", $byte, $test);
   #printf("bit: %x (%d), digest[$byte]: %x, test: %x (%x)\n",
   #  $bit, $bit, $digest[$byte], $test, $bit % 8);
}


sub calc_hash_key {
  my($self, $method_p, $url_p) = @_;
  my(%METHODS, $method, $url, $h, @temp_keys, @hash_keys);

  %METHODS = (
    'get'     => 0x1,
    'post'    => 0x2,
    'put'     => 0x3,
    'head'    => 0x4,
    'connect' => 0x5,
    'trace'   => 0x6,
    'purge'   => 0x7,
  );

  if ($METHODS{$method_p}) {
    $method = pack("C", $METHODS{$method_p});
  } else {
    $method = pack("C", $METHODS{"get"});
  }
  
  $url = $method . $url_p;
  #print "url (hex): " . unpack("H*", $url) . "\n";
  
  $h = MD5->hash($url);
  #print "\nh: " . unpack("H*", $h) . "\n";
  
  @temp_keys = unpack("NNNN", MD5->hash($url));
  #foreach ($i = 0; $i <= 3; $i++) {
  #  printf("temp_keys[$i] = %x\n", $temp_keys[$i]);
  #}
  
  $hash_keys[0] = $temp_keys[0] % ($self->{size_in_bytes} * 8);
  $hash_keys[1] = $temp_keys[1] % ($self->{size_in_bytes} * 8);
  $hash_keys[2] = $temp_keys[2] % ($self->{size_in_bytes} * 8);
  $hash_keys[3] = $temp_keys[3] % ($self->{size_in_bytes} * 8);
  
  #foreach ($i = 0; $i <= 3; $i++) {
  #  printf("hash_keys[$i] = %x (%d)\n", $hash_keys[$i], $hash_keys[$i]);
  #}

  return @hash_keys;
}


sub test_digest {
  my($self) = @_;
  my($host) = $self->{host};
  my($port) = $self->{port};
  my(@retval) = ();
  my($test_prefix, $path);

  $test_prefix = "http://$host:$port/squid-internal-static/icons";

  foreach $path (
      "anthony-binhex.gif", "anthony-bomb.gif", "anthony-box.gif",
      "anthony-box2.gif", "anthony-c.gif", "anthony-compressed.gif",
      "anthony-dir.gif", "anthony-dirup.gif", "anthony-dvi.gif",
      "anthony-f.gif", "anthony-image.gif", "anthony-image2.gif",
      "anthony-layout.gif", "anthony-link.gif", "anthony-movie.gif",
      "anthony-pdf.gif", "anthony-portal.gif", "anthony-ps.gif",
      "anthony-quill.gif", "anthony-script.gif", "anthony-sound.gif",
      "anthony-tar.gif", "anthony-tex.gif", "anthony-text.gif",
      "anthony-unknown.gif", "anthony-xbm.gif", "anthony-xpm.gif"
  ) {
    push(@retval, "$test_prefix/$path");

    if ($self->lookup("GET", "$test_prefix/$path")) {
      print "HIT  ";
    } else {
      print "MISS ";
    }
    print "$test_prefix/$path\n";
  }
}


1;


=head1 NAME

WebCache::Digest - a Cache Digest implementation in Perl

=head1 SYNOPSIS

  use WebCache::Digest;

  # fetching a digest via HTTP
  $d = new WebCache::Digest;
  $d->fetch("flibbertigibbet.swedish-chef.org", 3128);

  # dump header fields out for info
  print STDERR $d->dump_header();

  # saving a digest
  $d->save("flib");

  # loading a digest
  $e = new WebCache::Digest;
  $e->load("flib");

  # creating a new digests
  $f = new WebCache::Digest;
  $f->create; # defaults to a digest with 500 URL capacity

  # registering a URL and method in the digest
  $f->register("get", "http://www.kha0s.org/">;
  if ($f->lookup("get", "http://www.kha0s.org/">) {
    print "hit!\n";
  }

  # access to raw header and digest contents
  print "header: " . unpack("H*", $f->header) . "\n";
  print "digest: " . unpack("H*", $f->digest) . "\n";

  # access to digest header block elements
  print "Current version:      " . $f->current_version . "\n";
  print "Required version:     " . $f->required_version . "\n";
  print "Capacity:             " . $f->capacity . "\n";
  print "Count:                " . $f->count . "\n";
  print "Deletion count:       " . $f->del_count . "\n";
  print "Size in bytes:        " . $f->size_in_bytes . "\n";
  print "Bits per entry:       " . $f->bits_per_entry . "\n";

=head1 DESCRIPTION

This Perl module implements version 5 of the Cache Digest specification.
For more information about Cache Digests, check out the Squid FAQ:

  http://squid.nlanr.net/Squid/FAQ/FAQ-16.html

A copy of the specification is included with this distribution as the
file F<cache-digest-v5.txt>.

This code has been benchmarked on a 400MHz PII running Linux at 1866 
lookups per second (or 112000 per minute, 560000 in five minutes),
with a cache digest of 500000 URLs.

Cache Digests are summaries of the contents of WWW cache servers, which
are made available to other WWW caches and may also be used internally
within the server which generates them.  They allow a WWW cache server
such as Squid to determine whether or not a particular Internet resource
(designated by its URL and the HTTP method which is being used to fetch
it) was cached at the time the digest was generated.  Unlike other
mechanisms such as the Internet Cache Protocol (ICP - see RFC 2186),
Cache Digests do not generate a continuous stream of request/response
pairs, and do not add latency to each URL which is looked up.

Since we provide routines to both lookup URLs in Cache Digests and also
register them in Cache Digests, it should be trivial to use this code
to devise innovative applications which take advantage of Cache Digests
to fool genuine WWW caches into treating them like WWW caches.  For
example, mirror servers could register all the URLs which they're aware
of for the resources they mirror, so that cache servers which peer with
them will always get a cache 'hit' on the mirror server for any reference
to any of the mirrored resources.

We also provide methods to store Cache Digests to disk and load them
back in again, in addition to creating new Digests and fetching them
from WWW caches which support the protocol.  This can be used to take
a 'snapshot' of the state of a WWW cache at any particular point in
time, or for saving state if building a Cache Digest powered server.

=head1 METHODS

We only describe public methods and method arguments here.  Anything
else should be considered private, at least for now.

=over 4

=item new

Constructor function, creates a new WebCache::Digest object.  As yet this
takes no arguments.

=item create 

Fills in the data structures for a WebCache::Digest object, given the
number of lots to make available for URLs via the B<capacity> parameter.

=item fetch

Tries to fetch a Cache Digest from the machine whose domain name (or
IP address) and port number are specified (in this order) in the first
and second parameters.  Returns 0 on failure, and 1 on success.

=item dump_header

Dump the fields in the Cache Digest header out as plain text to, e.g.
for debugging purposes.

=item save

Saves the WebCache::Digest object to the filename supplied as its parameter.
Returns 0 on failure, 1 on success.

=item load

Populates the WebCache::Digest object with contents of the filename supplied
as its parameter.  Returns 0 on failure, 1 on success.

=item lookup

Given an HTTP method and URL (in that order) as parameters, try to look
them up in the Cache Digest.  Returns 1 if the URL is a Cache Digest hit,
or 0 otherwise.

=item register

Given an HTTP method and URL (in that order) as parameters, register them
in the Cache Digest.

=item header

The raw Cache Digest header.

=item digest

The raw Cache Digest object, sans header.

=item current_version

The current version number from the Digest object.

=item required_version

The required version number from the Digest object.  Implementations should
support at least this version for interoperability.

=item capacity

The number of 'slots' for URLs in the Digest.

=item count

The number of slots which have been filled.

=item del_count

The number of deletion attempts - Squid doesn't currently delete any
URLs (e.g. on their becoming stale) but simply discards them the next
time the Digest is rebuilt.  Deleting one URL's information without
affecting others is impossible with Cache Digests as currently
conceived - where a given bit of the Digest may be used in looking up
multiple URLs.

=item size_in_bytes

The size of the Digest in bytes when stored in transfer format.

=item bits_per_entry

The number of bits in the Cache Digest consumed for each entry.

=item hash_func_count

The number of times the Cache Digest hash function (see the
specification for more information on this) is called for each URL.

=back

=head1 BUGS

This is a first release, and there are probably lots of hideous bugs
waiting to catch you out - consider it pre-alpha code!

Something else to watch out for is that the name may well change -
depending on feedback from the B<comp.lang.perl.modules> Usenet
conference.

We use far too much memory - a more efficient approach to processing
the Cache Digest needs to be hacked in.

We should be consistent and always use one form of arguments - either
hash array or fixed position arguments.  Mixing the two is confusing.
However...  most methods don't need named (hash array) arguments,
except for B<create>.

=head1 COPYRIGHT

Copyright (c) 1999, Martin Hamilton.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

It was developed by the JANET Web Cache Service, which is funded by
the Joint Information Systems Committee (JISC) of the UK Higher
Education Funding Councils.

=head1 AUTHOR

Martin Hamilton E<lt>martinh@gnu.orgE<gt>

