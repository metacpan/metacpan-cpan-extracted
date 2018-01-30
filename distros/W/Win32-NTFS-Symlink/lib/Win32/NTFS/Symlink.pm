package Win32::NTFS::Symlink;

use 5.006;
use strict;
use warnings;

################################################################################

use List::Util qw(uniq);


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
   global  => [ qw(
      readlink
      symlink
   ) ], # Override built-ins.
   package => [ qw(
      readlink
      symlink
      junction
   ) ],
   ntfs_   => [ qw(
      ntfs_readlink
      ntfs_symlink
      ntfs_junction
      ntfs_reparse_tag
   ) ], # Alternative imports with ntfs_ prefix.
   is_     => [ qw(
      is_ntfs_symlink
      is_ntfs_junction
   ) ],
   const   => [ qw(
      IO_REPARSE_TAG_MOUNT_POINT
      IO_REPARSE_TAG_SYMLINK
   ) ]
);

our @EXPORT_OK = ( map @{$EXPORT_TAGS{$_}}, qw(package ntfs_ is_ const) );

################################################################################

our $VERSION = '0.10';

require XSLoader;
XSLoader::load('Win32::NTFS::Symlink', $VERSION);


sub readlink (_);
sub symlink  ($$);
sub junction ($$);


sub import {
   my $class = shift;
   
   my @list = @_;
   my @imports = grep !m{ ^ \!? (?: \:global$ | (?:/\^?)? global_ ) }x, @_;
   my @globals;
   
   for my $spec (@list) {
      my $remove = $spec =~ s/^!//;
      my @names;
      
      push @names, $spec =~ /^\:global$/
         ? @{$EXPORT_TAGS{global}}
         : $spec =~ m@^/\^?global_(.*)/$@
            ? grep( /$1/, @{$EXPORT_TAGS{global}} )
            : grep( $spec eq "global_$_", @{$EXPORT_TAGS{global}} );
      
      if ($remove) {
         for my $name (@names) { @globals = grep $_ ne $name, @globals };
      }
      else {
         push @globals, @names;
      }
   }
   
   if (@globals) {
      no strict qw(refs);
      *{"CORE::GLOBAL::$_"} = __PACKAGE__->can("ntfs_$_") for uniq @globals;
   }
   
   Win32::NTFS::Symlink->export_to_level(1, $class, @imports);
}


*readlink = \&ntfs_readlink;
*symlink  = \&ntfs_symlink;
*junction = \&ntfs_junction;


1;
__END__

=head1 NAME

Win32::NTFS::Symlink - Support for NTFS symlinks and junctions on Microsoft
Windows

=head1 SYNOPSIS

  use Win32::NTFS::Symlink qw(:global junction ntfs_reparse_tag :is_ :const);
  
  # Create NTFS symlinks.
  symlink 'D:\dir1'      => 'D:\symlink_to_dir1';      # To a directory.
  symlink 'D:\file1.txt' => 'D:\symlink_to_file1.txt'; # To a file.
  
  # Creates an NTFS directory junction.
  junction 'D:\dir1' => 'D:\junction_to_dir1';
  
  say readlink 'D:\symlink_to_dir1';      # 'D:\dir1'
  say readlink 'D:\symlink_to_file1.txt'; # 'D:\file1.txt'
  say readlink 'D:\junction_to_dir1';     # 'D:\dir1'
  
  # true
  say is_ntfs_symlink('D:\symlink_to_dir1');
  say is_ntfs_symlink('D:\symlink_to_file1.txt');
  say is_ntfs_junction('D:\junction_to_dir1');
  
  say ntfs_reparse_tag('D:\symlink_to_dir1')      == IO_REPARSE_TAG_SYMLINK;
  say ntfs_reparse_tag('D:\symlink_to_file1.txt') == IO_REPARSE_TAG_SYMLINK;
  say ntfs_reparse_tag('D:\junction_to_dir1')     == IO_REPARSE_TAG_MOUNT_POINT;
  
  # false
  say is_ntfs_symlink('D:\junction_to_dir1');
  say is_ntfs_junction('D:\symlink_to_dir1');
  say is_ntfs_junction('D:\symlink_to_file1.txt');
  
  say ntfs_reparse_tag('D:\junction_to_dir1')     == IO_REPARSE_TAG_SYMLINK;
  say ntfs_reparse_tag('D:\symlink_to_dir1')      == IO_REPARSE_TAG_MOUNT_POINT;
  say ntfs_reparse_tag('D:\symlink_to_file1.txt') == IO_REPARSE_TAG_MOUNT_POINT;

Or

  use if ($^O eq 'MSWin32'), qw(Win32::NTFS::Symlink :global);
  
  # Now symlink() and readlink() can be used in a program that will
  # behave the same way (in regards to symbolic links) on Windows as
  # it would on most unix-like systems, to make for more
  # platform-agnostic symbolic link handling.

=head1 DESCRIPTION

This module implements C<symlink> and C<readlink> routines, as well as a
C<junction> function, for use with NTFS file-systems on Microsoft Windows.

=head1 FUNCTIONS

=head2 Main Functions

=over

=item C<symlink( $path )> , C<ntfs_symlink( $path )>

Create an NTFS symlink. Can be either relative or absolute.

Has the same prototype as the built-in C<symlink> function.

(I<For Windows XP, 2003 Server, or 2000, see section>
L</"NTFS Symlinks in Windows XP, 2003 Server, and 2000"> I<below.>)

=item C<junction( $path )> , C<ntfs_junction( $path )>

Create an NTFS directory junction. Unlike symlinks, junctions are only able
to link to absolute paths, even if a relative one is specified, and only to a
local volume. This is is a limitation of how junctions themselves work.

Also has the same prototype as the built-in C<symlink> function.

=item C<readlink( $path )> , C<ntfs_readlink( $path )>

Read NTFS symlinks and junctions. Junctions are always returned as absolute.

Has the same prototype as the built-in C<readlink> function.

=back

The above can be imported by name.

=head2 Test Functions

=over

=item C<is_ntfs_symlink( $path )>

Returns true if $path is an NTFS symlink, false otherwise.

Has the same prototype as the built-in C<readlink> function.

=item C<is_ntfs_junction( $path )>

Returns true if $path is an NTFS junction, false otherwise.

Has the same prototype as the built-in C<readlink> function.

=item C<ntfs_reparse_tag( $path )>

Returns the NTFS reparse tag, which will be a specific value depending on
if $path is a symlink, junction, or C<0> if it is neither.

This routine is most useful as an alternative to C<is_ntfs_symlink> and
C<is_ntfs_junction> above.

Has the same prototype as the built-in C<readlink> function.

(I<See section> L</"CONSTANTS"> I<below.>)

=back

The above can be imported by name.

=head1 CONSTANTS

The following can be used to test the return value of C<ntfs_reparse_tag>.

=over

=item C<IO_REPARSE_TAG_SYMLINK>

This value for the tag portion of the reparse data for an NTFS symlink.

=item C<IO_REPARSE_TAG_MOUNT_POINT>

This value for the tag portion of the reparse data for an NTFS junction.

=back

The above can be imported by name.

=head1 EXPORTS

By default, nothing is exported or overridden.

=head2 Override Built-In Functions

=over

=item C<:global>

This overrides the global C<readlink> and C<symlink> built-in functions. This
can be useful to allow other modules that use C<readlink> or C<symlink> to be
able to function correctly on Windows.

=back

This can also be done on an individual basis with:

=over

=item C<global_readlink>

=item C<global_symlink>

=back

Note: C<global_junction> does not exist since there is no built-in function
with this name, as it is specific only to the NTFS file-system on the Win32
platform.

=head2 General Imports

=over

=item C<:package>

Imports the following into the current namespace:

=item C<readlink>

=item C<symlink>

=item C<junction>

=back

=head2 General Imports with ntfs_ prefix

This can be useful to prevent conflicts with existing sub routines the names
above.

=over

=item C<:ntfs_>

Imports the following into the current namespace:

=item C<ntfs_readlink>

=item C<ntfs_symlink>

=item C<ntfs_junction>

=item C<ntfs_reparse_tag>

=back

=head2 Test Imports

=over

=item C<:is_> 

Imports the following into the current namespace:

=item C<is_ntfs_symlink>

=item C<is_ntfs_junction>

=back

=head2 Importable Constants

=over

=item C<:const>

Imports the following into the current namespace:

=item C<IO_REPARSE_TAG_SYMLINK>

=item C<IO_REPARSE_TAG_MOUNT_POINT>

(I<See section> L</"CONSTANTS"> I<above.>)

=back

=head1 NTFS Symlinks in Windows XP, 2003 Server, and 2000

For proper NTFS symlink support in Windows XP, 2003 Server, and 2000 (NT 5.x),
a driver is needed to enable support, to expose the existing underlying
functionality to the user-land level so it can be accessed and manipulated
by programs and libraries.

The driver and it's source code can be obtained from
L<http://schinagl.priv.at/nt/ln/ln.html> (at the bottom.)

Note that this is only required for full symlink support. Junctions, on the
other hand do not require this, since that part of the NTFS reparse mechanism
is already exposed to the user-land level. However, C<symlink> will not work
correctly without it, nor will C<readlink> be able to properly read symlinks.

This isn't needed if you are using Vista or Server 2008 R1 (NT 6.0), or later.

=head1 TODO

=item Implement C<-l>

I plan to do this for the next release!

=head1 ACKNOWLEDGEMENTS

I originally set out to fix L<Win32::Symlink>, whose C<symlink> and
C<readlink> implementations (ironically) only worked with NTFS junctions,
without any support for NTFS symlinks.

I ended up creating a fresh new module to properly implement C<symlink> as
well as C<junction>, and a C<readlink> that could read either one.

So even though I ended up not using much of anything from L<Win32::Symlink>,
I still want to acknowledge Audrey Tang <cpan@audreyt.org> for the
inspiration, as well as L<http://schinagl.priv.at/nt/ln/ln.html> whose source
code relating to the I<ln> utility that helped greatly in figuring out how to
properly work with NTFS reparse points.

I also want to greatly thank all of the wonderful folks in the perl IRC
channels for their wisdom and advise.

=head1 AUTHOR

Bayan Maxim E<lt>baymax@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Bayan Maxim

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>


=cut
