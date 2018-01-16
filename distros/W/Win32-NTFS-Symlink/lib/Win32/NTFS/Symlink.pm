package Win32::NTFS::Symlink;

use 5.006;
use strict;
use warnings;

################################################################################

use List::Util qw(uniq);


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
   ntfs_   => [ qw(ntfs_readlink ntfs_symlink ntfs_junction) ],
   package => [ qw(readlink symlink junction) ],
   global  => [ qw(readlink symlink) ]
);

our @EXPORT_OK = ( @{$EXPORT_TAGS{ntfs_}}, @{$EXPORT_TAGS{package}} );

################################################################################

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Win32::NTFS::Symlink', $VERSION);


sub readlink;
sub symlink;
sub junction;


sub import {
   my $class = shift;
   
   my @list = @_;
   my @imports = grep !m@^(?:\:global$|(?:\!|/\^?)?global_)@, @_;
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
   
   #*CORE::GLOBAL::ntfs_readlink = __PACKAGE__->can('ntfs_readlink');
}


*readlink = \&ntfs_readlink;
*symlink  = \&ntfs_symlink;
*junction = \&ntfs_junction;


# Preloaded methods go here.

1;
__END__

=head1 NAME

Win32::NTFS::Symlink - Support for NTFS junctions and symlinks on Windows

=head1 SYNOPSIS

  use Win32::NTFS::Symlink qw(:global junction);
  
  # Create NTFS symlinks.
  symlink 'D:\dir1'      => 'D:\symlink_to_dir1';      # To a directory.
  symlink 'D:\file1.txt' => 'D:\symlink_to_file1.txt'; # To a file.
  
  # Creates an NTFS directory junction.
  junction 'D:\dir1' => 'D:\junction_to_dir1';
  
  say readlink 'D:\symlink_to_dir1';      # 'D:\dir1'
  say readlink 'D:\symlink_to_file1.txt'; # 'D:\file1.txt'
  say readlink 'D:\junction_to_dir1';     # 'D:\dir1'

=head1 DESCRIPTION

This module implements C<symlink> and C<readlink> routines, as well as an
C<junction> function, for use with NTFS file systems on Microsoft Windows.

C<symlink> (or C<ntfs_symlink>) will create an NTFS symlink.

(For Windows XP, 2003 Server, or 2000, see section L<NTFS Symlinks in Windows
XP, 2003 Server, and 2000> below.)

C<junction> (or C<ntfs_junction>) will create an NTFS directory junction.

C<readlink> (or C<ntfs_readlink>) can read both NTFS symlinks and junctions.

Note: While NTFS symlink targets can be either relative or absolute, readlink
on a junction will always return an absolute path. This is simply how they are
stored in the file system (reparse point.)

=head1 Exports

By default, nothing is exported. There are multiple ways to import routines
from this module.

=head2 Global Overrides

=over

=item C<:global>

This overrides the global C<readlink> and C<symlink> built-in functions. This
can be useful to "fix" other modules that use these routines that would
normally not be able to function correctly on Windows.

You can also choose to override each one individually:

=item C<global_readlink>

=item C<global_symlink>

Note: There is currently no global override for C<junction>, as there doesn't
exist a built-in function, since junctions are NTFS and Windows/NT specific,
and so there aren't existing modules making use of it in the same way as those
using C<symlink> and C<readlink> already for other platforms such as Unix and
Linux.

=back

=head2 Convention Imports

=over

=item C<:package>

This will import C<readlink>, C<symlink>, and C<junction> into the current
namespace.

These can also be imported individually:

=item C<readlink>

=item C<symlink>

=item C<readlink>

=back

=head2 Alternative Imports

=over

=item C<:ntfs_>

This will import C<ntfs_readlink>, C<ntfs_symlink>, and C<ntfs_junction> into
the current namespace. This can be useful to prevent conflicts with existing
sub routines with the same names, or if when it is undesired to override the
built-in C<readlink> and C<symlink> functions.

These can also be imported individually:

=item C<ntfs_readlink>

=item C<ntfs_symlink>

=item C<ntfs_readlink>

=back

=head2 Mix and Match

=over

=item The above importations and global override options can be mixed and
matched.

For example:

 # Override the global built-in readlink() and symlink(), and
 # import ntfs_junction()
 
 use Win32::NTFS::Symlink qw(:global ntfs_junction);

Another example:

 # Override global built-in readlink() only, and import ntfs_symlink()
 # Since neither junction nor ntfs_junction are imported, it must be fully
 # qualified in order to be used, as either
 # Win32::NTFS::Symlink::junction() or Win32::NTFS::Symlink::ntfs_junction()
 
 use Win32::NTFS::Symlink qw(global_readlink ntfs_symlink);

=back

=head1 NTFS Symlinks in Windows XP, 2003 Server, and 2000

For proper NTFS symlink support in Windows XP, 2003 Server, and 2000 (NT 5.x), a
driver is needed to enable support, to expose the existing functionality to
the user-land level so it can be accessed by programs such as this one.

The driver and it's source code can be obtained from
L<http://schinagl.priv.at/nt/ln/ln.html> (at the bottom.)

Note that this is only required for full symlink support. Junctions, on the
other hand do not require this, since that part of the NTFS reparse mechanism
is already exposed to the user-land level.

This isn't needed if you are using Vista or Server 2008 R1 (NT 6.0), or later.

=head1 ACKNOWLEDGEMENTS

I originally set out to fix L<Win32::Symlink>, whose C<symlink()> and
C<readlink> implementations (ironically) only worked with NTFS junctions,
without any support for NTFS symlinks.

I ended up creating a fresh new module to properly implement C<symlink> as
well as C<junction>, and a C<readlink> that could read either one.

So even though I ended up not using much of anything from L<Win32::Symlink>,
I still want to acknowledge Audrey Tang <cpan@audreyt.org> for the
inspiration, as well as L<http://schinagl.priv.at/nt/ln/ln.html> whose source
code relating to the I<ln> utility that helped greatly in figuring out how to
properly work with NTFS reparse points.

=head1 AUTHOR

Bayan Maxim E<lt>baymax@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Bayan Maxim

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>


=cut
