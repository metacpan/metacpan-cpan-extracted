package Win32::UrlCache;

use strict;
use warnings;
use Carp;

BEGIN {
  if ( $^O eq 'MSWin32' ) {
    require Win32::UrlCache::FileTime;
    Win32::UrlCache::FileTime->import;
  }
  else {
    require Win32::UrlCache::FileTimePP;
    Win32::UrlCache::FileTimePP->import;
  }
}

our $VERSION = '0.06';

use constant BADFOOD => chr(0x0D).chr(0xF0).chr(0xAD).chr(0x0B);

sub new {
  my $class = shift;
  my $self = bless {}, $class;

  $self->_read_file( @_ );
  $self->_version_check;
  $self->_size_check;
  $self->_get_pointer_to_first_hash;

  $self;
}

sub _read_file {
  my ($self, $file) = @_;

  open my $fh, '<', $file or croak $!;
  binmode $fh;
  sysread $fh, ( my $data ), ( my $size = -s $fh );
  close $fh;

  $self->{_data} = $data;
  $self->{_size} = $size;
  $self->{_pos}  = 0;
}

sub _version_check {
  my $self = shift;
  my $header = 'Client UrlCache MMF Ver 5.2';
  my $read   = $self->_read_string;
  unless ( $read eq $header ) {
    croak "unsupported file type: $read";
  }
}

sub _size_check {
  my $self = shift;
  my $read = _to_int( $self->_read );
  unless ( $read == $self->{_size} ) {
    croak "index file seems broken: $read / ".$self->{_size};
  }
}

sub _get_pointer_to_first_hash {
  my $self = shift;

  $self->{_from} = _to_int( $self->_read );
}

sub _read_hashes {
  my ($self, $target, %options) = @_;

  my $pointer = $self->{_from};

  while( $pointer ) {
    unless ( $self->_read_from( $pointer ) eq 'HASH' ) {
      croak "index file seems broken: HASH not found";
    }
    my $hash_length = _to_int( $self->_read );
    my $next_hash   = _to_int( $self->_read );
    my $unknown     = _to_int( $self->_read );
    my $hash_end    = $pointer + ( $hash_length * 0x80 );

    while ( $self->{_pos} < $hash_end ) {
      my ( $hashkey, $offset ) = ( $self->_read, $self->_read );
      next if $offset eq BADFOOD;

      my $int_offset = _to_int( $offset );
      next unless $int_offset;

      # last of the offset should be 0x80/0x00 (not 0x03 etc)
      next unless ( $int_offset & 0xf ) == 0;

      my $tag = $self->_test_from( $int_offset );
      next if $tag eq BADFOOD;

      if ( $tag =~ /^(?:URL|REDR|LEAK)/ ) {
        next if $target && $target ne $tag;

        my $pos = $self->{_pos};
        $self->_read_entry( $int_offset, %options );
        $self->{_pos} = $pos;
      }
    }
    $pointer = $next_hash or last;
  }
}

sub _read_entry {
  my ($self, $offset, %options) = @_;

  my $tag = $self->_read_from( $offset );
     $tag =~ s/ $//;
  my $class = 'Win32::UrlCache::'.$tag;

  my $item;
  if ( $tag eq 'REDR' ) {
    my $block   = $self->_read;
    my $unknown = $self->_read(8);
    my $url     = $self->_read_string;

    $item = { url => $url };
  }
  if ( $tag eq 'URL' or $tag eq 'LEAK' ) {
    my $block              = $self->_read;
    my $last_modified      = filetime( $self->_read(8) );
    my $last_accessed      = filetime( $self->_read(8) );
    my $maybe_expire       = $self->_read(8);
    my $maybe_filesize     = $self->_read(8);
    my $unknown            = $self->_read(20);
    my $offset_to_filename = _to_int( $self->_read );
    my $unknown2           = $self->_read;
    my $offset_to_headers  = _to_int( $self->_read );
    my $unknown3           = $self->_read(32);
    my $url                = $self->_read_string;
    my $filename           = $offset_to_filename
      ? $self->_read_string_from( $offset + $offset_to_filename )
      : '';
    my $headers            = $offset_to_headers
      ? $self->_read_string_from( $offset + $offset_to_headers )
      : '';

    $item = {
      url           => $url,
      filename      => $filename,
      headers       => $headers,
      filesize      => $maybe_filesize,
      last_modified => $last_modified,
      last_accessed => $last_accessed,
    };
  }
  return unless $item;

  my $object = bless $item, $class;
  if ( $options{callback} ) {
    my $ret = $options{callback}->( $object );
    return unless $ret;
  }

  if ( $options{extract_title} && $item->{filename} && $^O eq 'MSWin32' ) {
    require Win32::UrlCache::Title;
    Win32::UrlCache::Title->import;
    $item->title( Win32::UrlCache::Title->extract( $item->filename ) );
  }

  push @{ $self->{$tag} ||= [] }, $object;
}

sub urls  {
  my $self = shift;
  $self->_read_hashes( 'URL ', @_ );
  return @{ $self->{URL} || [] };
}

sub redrs  {
  my $self = shift;
  $self->_read_hashes( 'REDR', @_ );
  return @{ $self->{REDR} || [] };
}

sub leaks  {
  my $self = shift;
  $self->_read_hashes( 'LEAK', @_ );
  return @{ $self->{LEAK} || [] };
}

sub _to_int {
  my $dword = shift;
  my @bytes = split //, $dword;
  return (
    ord( $bytes[3] ) * (256 ** 3) +
    ord( $bytes[2] ) * (256 ** 2) +
    ord( $bytes[1] ) * (256 ** 1) +
    ord( $bytes[0] ) * (256 ** 0)
  );
}

sub _read {
  my ($self, $length) = @_;

  $length ||= 4;
  my $str = substr( $self->{_data}, $self->{_pos}, $length );
  $self->{_pos} += $length;
  return $str;
}

sub _read_from {
  my ($self, $from, $length) = @_;
  $self->{_pos} = $from;
  $self->_read( $length );
}

sub _read_string {
  my $self = shift;
  my $from = $self->{_pos};
  my $to   = index( $self->{_data}, "\000", $from );
  my $str  = substr( $self->{_data}, $from, $to - $from );
  $self->{_pos} = $to + 1;
  return $str;
}

sub _read_string_from {
  my ($self, $from) = @_;
  $self->{_pos} = $from;
  $self->_read_string;
}

sub _test_from {
  my ($self, $from, $length) = @_;
  $length ||= 4;
  $from     = $self->{_pos} unless defined $from;
  return substr( $self->{_data}, $from, $length );
}

package #
  Win32::UrlCache::URL;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw(
  url filename headers filesize last_modified last_accessed
  title
));

package #
  Win32::UrlCache::LEAK;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw(
  url filename headers filesize last_modified last_accessed
  title
));

package #
  Win32::UrlCache::REDR;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( url ));

1;

__END__

=head1 NAME

Win32::UrlCache - parse Internet Explorer's history/cache/cookies

=head1 SYNOPSIS

    use Win32::UrlCache;
    my $index = Win32::UrlCache->new( 'index.dat' );
    foreach my $url ( $index->urls ) {
      print $url->url, "\n";
    }

    Or, you can use callback function if you care memory usage.

    use Win32::UrlCache;
    my $index = Win32::UrlCache->new( 'index.dat' );
    $index->urls( callback => \&callback )

    sub callback {
      my $entry = shift;
      my $url = $entry->url;
         $url =~ s/^Visited: //;
      $entry->url( $url );

      print $entry->url, "\n";
      return;  # to prevent the entry from being kept in the object
    }

    If you want to know the title of the cached page (for Win32 only):

    use Win32::UrlCache::Cache;
    use Win32::UrlCache::Title;
    use Encode;
    my $cache = Win32::UrlCache::Cache->new;
       $cache->urls( callback => \&callback )

    sub callback {
      my $entry = shift;

      print $entry->url, "\n";
      my $title = Win32::UrlCache::Title->extract( $entry->filename );
      print encode( shiftjis => $title ), "\n\n" if $title;

      return;
    }

=head1 DESCRIPTION

This parses so-called "Client UrlCache MMF Ver 5.2" index.dat files, which are used to store Internet Explorer's history, cache, and cookies. As of writing this, I've only tested on Win2K + IE 6.0, but I hope this also works with some of the other versions of OS/Internet Explorer. However, note that this is not based on the official/public MSDN specification, but on a hack on the web. So, caveat emptor in every sense, especially for the redr entries ;)

Patches and feedbacks are welcome.

=head1 METHODS

=head2 new

receives a path to an 'index.dat', and parses it to create an object.

=head2 urls

returns URL entries in the 'index.dat' file. Each entry has url, filename, headers, filesize, last_modified, last_accessed, and optionally, title accessors (note that some of them would return meaningless values). As of 0.02, it can receive a callback function. See below. As of 0.04, you can also pass ( extract_title => 1 ) to extract title. However, this extraction is processed after a callback. So, if you want both to use a callback and to extract title, you might want to insert extraction code into the callback as shown in the synopsis.

=head2 leaks

almost the same as urls, but returns LEAK entries (if any) in the 'index.dat' file.

=head2 redrs

returns REDR entries (if any) in the 'index.dat' file. Each entry has a url accessor. As of 0.02, it can receive a callback function.

=head1 CALLBACK

Three methods shown above return all the entries found in the index by default, but this may eat lots of memory especially if you use IE as a main browser. As of 0.02, those methods may receive a callback function, which will take an entry for the first (and only, as of writing this) argument. If the callback returns true, the entry will be stored in the ::UrlCache object, and if the callback returns false, the entry will be discarded after the callback is executed.

=head1 SEE ALSO

L<http://www.latenighthacking.com/projects/2003/reIndexDat/>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
