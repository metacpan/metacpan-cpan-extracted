package Text::Template::Simple::IO;
$Text::Template::Simple::IO::VERSION = '0.91';
use strict;
use warnings;
use constant MY_IO_LAYER      => 0;
use constant MY_INCLUDE_PATHS => 1;
use constant MY_TAINT_MODE    => 2;

use File::Spec;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util qw(
   binary_mode
   fatal
   DEBUG
   LOG
);

sub new {
   my $class = shift;
   my $layer = shift;
   my $paths = shift;
   my $tmode = shift;
   my $self  = [ undef, undef, undef ];
   bless $self, $class;
   $self->[MY_IO_LAYER]      = $layer if defined $layer;
   $self->[MY_INCLUDE_PATHS] = [ @{ $paths } ] if $paths; # copy
   $self->[MY_TAINT_MODE]    = $tmode;
   return $self;
}

sub validate {
   my $self = shift;
   my $type = shift || fatal('tts.io.validate.type');
   my $path = shift || fatal('tts.io.validate.path');

   if ( $type eq 'dir' ) {
      require File::Spec;
      $path = File::Spec->canonpath( $path );
      my $wdir;

      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $path );
         if( Win32::GetLastError() ) {
            LOG( FAIL => "Win32::GetFullPathName( $path ): $^E" ) if DEBUG;
            $wdir = EMPTY_STRING; # die "Win32::GetFullPathName: $^E";
         }
         else {
            my $ok = -e $wdir && -d _;
            $wdir  = EMPTY_STRING if not $ok;
         }
      }

      $path = $wdir if $wdir;
      my $ok = -e $path && -d _;
      return if not $ok;
      return $path;
   }

   return fatal('tts.io.validate.file');
}

sub layer {
   return if ! UNICODE_PERL;
   my $self   = shift;
   my $fh     = shift || fatal('tts.io.layer.fh');
   my $layer  = $self->[MY_IO_LAYER];
   binary_mode( $fh, $layer ) if $layer;
   return;
}

sub slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my($fh, $seek);

   LOG(IO_SLURP => $file) if DEBUG;

   if ( ref $file && fileno $file ) {
      $fh   = $file;
      $seek = 1;
   }
   else {
      $fh = IO::File->new;
      $fh->open($file, 'r') or fatal('tts.io.slurp.open', $file, $!);
   }

   flock $fh,    Fcntl::LOCK_SH();
   seek  $fh, 0, Fcntl::SEEK_SET() if $seek;
   $self->layer( $fh ) if ! $seek; # apply the layer only if we opened this

   if ( $self->_handle_looks_safe( $fh ) ) {
      require IO::Handle;
      my $rv = IO::Handle::untaint( $fh );
      fatal('tts.io.slurp.taint') if $rv != 0;
   }

   my $tmp = do { local $/; my $rv = <$fh>; $rv };
   flock $fh, Fcntl::LOCK_UN();
   if ( ! $seek ) {
      # close only if we opened this
      close $fh or die "Unable to close filehandle: $!\n";
   }
   return $tmp;
}

sub _handle_looks_safe {
   # Cargo Culting: original taint checking code was taken from "The Camel"
   my $self = shift;
   my $fh   = shift;
   fatal('tts.io.hls.invalid') if ! $fh || ! fileno $fh;

   require File::stat;
   my $i = File::stat::stat( $fh );
   return if ! $i;

   my $tmode = $self->[MY_TAINT_MODE];

   # ignore this check if the user is root
   # can happen with cpan clients
   if ( $< != 0 ) {
      # owner neither superuser nor "me", whose
      # real uid is in the $< variable
      return if $i->uid != 0 && $i->uid != $<;
   }

   # Check whether group or other can write file.
   # Read check is disabled by default
   # Mode is always 0666 on Windows, so all tests below are disabled on Windows
   # unless you force them to run
   LOG( FILE_MODE => sprintf '%04o', $i->mode & FTYPE_MASK) if DEBUG;

   my $bypass   = IS_WINDOWS && ! ( $tmode & TAINT_CHECK_WINDOWS ) ? 1 : 0;
   my $go_write = $bypass ? 0 : $i->mode & FMODE_GO_WRITABLE;
   my $go_read  = ! $bypass && ( $tmode & TAINT_CHECK_FH_READ )
                ? $i->mode & FMODE_GO_READABLE
                : 0;

   LOG( TAINT => "tmode:$tmode; bypass:$bypass; "
                ."go_write:$go_write; go_read:$go_read") if DEBUG;

   return if $go_write || $go_read;
   return 1;
}

sub is_file {
   # safer than a simple "-e"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && ! -d $file;
}

sub is_dir {
   # safer than a simple "-d"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && -d $file;
}

sub file_exists {
   my $self = shift;
   my $file = shift;

   return $file if $self->is_file( $file );

   foreach my $path ( @{ $self->[MY_INCLUDE_PATHS] } ) {
      my $test = File::Spec->catfile( $path, $file );
      return $test if $self->is_file( $test );
   }

   return; # fail!
}

sub _looks_like_file {
   my $self = shift;
   my $file = shift || return;
   return     ref $file                    ? 0
         :        $file =~ RE_NONFILE      ? 0
         : length $file >= MAX_PATH_LENGTH ? 0
         :     -e $file                    ? 1
         :                                   0
         ;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::IO

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

   TODO

=head1 NAME

Text::Template::Simple::IO - I/O methods

=head1 METHODS

=head2 new IO_LAYER

Constructor. Accepts an I/O layer name as the parameter.

=head2 layer FILE_HANDLE

Sets the I/O layer of the supplied file handle if there is a layer and C<perl>
version is greater or equal to C<5.8>.

=head2 slurp FILE_PATH

Returns the contents of the supplied file as a string.

=head2 validate TYPE, PATH

C<TYPE> can either be C<dir> or C<file>. Returns the corrected path if
it is valid, C<undef> otherwise.

=head2 is_dir THING

Test if C<THING> is a directory.

=head2 is_file THING

Test if C<THING> is a file.

=head2 file_exists THING

Test if C<THING> is a file. This method also searches all the C<include paths>
and returns the full path to the file if it exists.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
