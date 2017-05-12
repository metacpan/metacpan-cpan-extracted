package Win32::UrlCache::Title;

use strict;
use warnings;
use Carp;
use Win32::TieRegistry ( Delimiter => '/' );
use File::Spec;
use Encode;

my @CacheDirs;

sub import {
  my $class = shift;

  my $cachedir = $Registry->{'CUser/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders//Cache'};
  my $ie5_dir  = File::Spec->catdir( $cachedir, 'Content.IE5' );
     $cachedir = $ie5_dir if -d $ie5_dir;

  opendir my $dh, $cachedir or croak $!;
  while( my $entry = readdir $dh ) {
    next if $entry =~ /^\./;
    next if -f $entry;
    push @CacheDirs, File::Spec->catdir( $cachedir, $entry );
  }
}

sub extract {
  my ($class, $file) = @_;

  foreach my $dir ( @CacheDirs ) {
    opendir( my $dh, $dir );
    while( my $entry = readdir $dh ) {
      if ( $entry eq $file ) {
        return _extract( File::Spec->catfile( $dir, $entry ) );
      }
    }
    closedir $dh;
  }
  return;
}

sub _extract {
  my $file = shift;

  open my $fh, '<', $file or return;
  binmode $fh;
  read $fh, my $chunk, 1024;
  close $fh;

  return unless $chunk;

  my ($title) = $chunk =~ m{<title>(.+?)</title>}is;
  return unless $title;

  my ($charset) = $chunk =~ m{<meta[^>]+?;\s*charset=['"]?(['">]+?)}is;
  $charset ||= 'utf8';

  eval { $title = Encode::decode( $charset => $title ) };

  return $title;
}

1;

__END__

=head1 NAME

Win32::UrlCache::Title - looks for an html cache and extract its title

=head1 SYNOPSIS

  use Win32::UrlCache::Title;
  Win32::UrlCache::Title->extract( $cache->filename );

=head1 DESCRIPTION

This is used internally to look for an html cache and extract its title (this is for Win32 only).

=head1 METHOD

=head2 extract

receives a temporary file name, walks down in the cache diretories to find a cache of the name, tries to extract its title, and returns the (hopefully) properly-encoded title.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
