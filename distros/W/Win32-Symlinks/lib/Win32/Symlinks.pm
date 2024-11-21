package Win32::Symlinks;

use 5.006;
use strict;
use warnings;

=encoding latin1

=head1 NAME

Win32::Symlinks - A maintained, working implementation of Perl symlink built in features for Windows.

=head1 VERSION

Version 0.12

=cut

sub _mklink_works {
  my $cmd = ($ENV{COMSPEC} =~ /^(.*?)$/) ? $1 : 'cmd.exe'; # Untaint
  my $r = `"$cmd" /c mklink /? 2>&1`;
  if ($r =~ m[/D]i and $r =~ m[/H]i and $r =~ m[/J]i) {
    return 1;
  }
    return 0;
}

BEGIN {
  our $VERSION = '0.12';
  if ($^O eq 'MSWin32') {
    require Parse::Lnk;
    require File::Spec;
    require File::Basename;
    my $mklink_works = _mklink_works();
    
    if ($] >= 5.016) {
      require XSLoader;
      XSLoader::load();
      _override_link_test();
    } else {
      unless ($ENV{WIN32_SYMLINKS_SUPRESS_VERSION_WARNING}) {
        print STDERR "Warning: ".__PACKAGE__." can't override the -l operator on Perl versions older than 5.016. You are running $].\n";
        print STDERR "You can supress this warning by setting the environment variable WIN32_SYMLINKS_SUPRESS_VERSION_WARNING to a true value.\n";
      }
    }
    
    unless ($mklink_works) {
      unless ($ENV{WIN32_SYMLINKS_SUPRESS_VERSION_WARNING}) {
        print STDERR "Warning: ".__PACKAGE__." cannot override the function 'symlink' because mklink doesn't seem to be available in this system.\n";
        print STDERR "You can supress this warning by setting the environment variable WIN32_SYMLINKS_SUPRESS_VERSION_WARNING to a true value.\n";
      }
    }
    
    *CORE::GLOBAL::readlink = sub ($) {
      my $path = shift;
      undef $Win32::Symlinks::Type;
      $path = File::Spec->catdir(File::Spec->splitdir($path));
      if ($path =~ /\.lnk$/i) {
        my $target = Parse::Lnk->from($path);
        if ($target) {
          $Win32::Symlinks::Type = 'SHORTCUT';
          return $target;
        }
      }
      my $cmd = $ENV{COMSPEC} || 'cmd.exe';
      my $directory = File::Basename::dirname($path);
      my $item = File::Basename::basename($path);
      my @r = `"$cmd" /c dir /A:l "$directory" 2>&1`;
      for my $i (@r) {
        if ($i =~ m[<(JUNCTION|SYMLINK|SYMLINKD)>\s+(.*?)\s+\Q[\E([^\]]+)\Q]\E]) {
          my ($type, $name, $target) = ($1, $2, $3);
          for my $i ($type, $name, $target) {
            $i =~ s[(^\s+|\s+$)][]g;
          }
          if ($name eq $item) {
            $Win32::Symlinks::Type = $type;
            return $target;
          }
        }
      }
      return;
    };
    
    if ($mklink_works) {
      *CORE::GLOBAL::symlink = sub ($$) {
        my ($old, $new) = (shift, shift);
        return unless defined $old;
        return unless defined $new;
        $old = File::Spec->catdir(File::Spec->splitdir($old));
        $new = File::Spec->catdir(File::Spec->splitdir($new));
        my $r;
        if (-d $old) {
          $r = `mklink /d "$new" "$old" 2>&1`;
        } else {
          $r = `mklink "$new" "$old" 2>&1`;
        }
        return 1 if $r =~ /\Q<<===>>\E/;
        return 0;
      };
    }
    
    *CORE::GLOBAL::unlink = sub (@) {
      my $retval = 0;
      my @args = @_;
      for my $path (@args) {
        next unless defined $path;
        $path = File::Spec->catdir(File::Spec->splitdir($path));
        my $cmd = $ENV{COMSPEC} || 'cmd.exe';
        if (_test_d($path) and l($path)) {
          my $r = `"$cmd" /c rmdir "$path" 2>&1`;
          $retval += $r ? 0 : 1;
        } elsif (l($path)) {
          my $r = `"$cmd" /c del /Q "$path" 2>&1`;
          $retval += $r ? 0 : 1;
        } else {
          $retval += CORE::unlink($path);
        }
      }
      $retval;
    };
  }
}

sub l ($) {
  return 1 if defined readlink($_[0]);
  return 0;
}

# We need this because some versions of Perl (seen in 5.18) return true for -f dir_symlink
# and false for -d dir_symlink. This breaks the unlink override.
sub _test_d {
  my $path = shift;
  my $cmd = $ENV{COMSPEC} || 'cmd.exe';
  my $r = `"$cmd" /c cd "$path" 2>&1`;
  $r =~ s/(^\s+|\s+$)//g;
  return $r ? 0 : 1;
}


=head1 SYNOPSIS

This module enables, on Windows, symlink related Perl features that don't work by default on Windows.

Specifically, it enables the functionality that you would see on *nix OSes, for C<-l $filename>, C<symlink>, C<readlink> and C<unlink>.

This features have never properly been ported to Windows by the Perl development team. They were initially unimplemented due to the
limitations that Windows used to have prior to NTFS (e.g. when Windows used Fat32 as main file system).

That situation has been different for at least two decades now. Yet, Perl continues to keep these functions unimplemented on Windows.

The aim of this module is to allow Perl code to use C<-l $filename>, C<symlink>, C<readlink> and C<unlink> seamlessly between *nix
and Windows. Just by using the module, it will do its best effort to make these functions work exactly the same and as they are
expected to work.

The module doesn't do anything if it is run on a *nix machine, it defaults to the built in functions. But, by being present in your
code, you'll ensure these functions don't break when being executed in a Windows based Perl distribution.

Perhaps a little code snippet.

  use Win32::Symlinks;

  # That's it. Now symlink, readlink, unlink and -l will work correctly when
  # executed under Windows.
  
  # Also, you don't need to call it everywhere. Calling it once is enough.
    
    

=head1 EXPORT

Only when running under Windows, the built in functions C<symlink>, C<readlink> and C<unlink>,
as well as the file test C<-l>, are overriden.

If at some point you really need to make sure you are calling the built in function,
you should explicitly use the CORE prefix (e.g. C<CORE::readlink($file)>).

When running on any OS that is *not* Windows, it will default to the built in
Perl functions. This module doesn't do anything on non Windows platforms, which
makes it perfect if you are working on a non Windows machine but want to make
sure your symlink related functions will not break under Windows.

=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>

=head1 BUGS

I'm sure there are many that I haven't been able to trigger. If you find a bug,
please don't hesitate to report it. I promise I will make an effort to have it
resolved ASAP.

Take into account that this implementation can only work on NTFS file systems.
Symlinks are not implemented in file systems like FAT32. Windows has been using
NTFS since Windows 2000, but it used FAT32 for Windows 95, 98, Millenium, etc.

Also, external devices like USB sticks, SD cards, etc., are generally formatted
with FAT32 or ExFAT. So, if you try to use these functions over such devices,
it will fail, unless you format them with the NTFS file system first.

Please report any bugs or feature requests to C<bug-win32-symlinks at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Symlinks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Win32::Symlinks


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Symlinks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Symlinks>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Win32-Symlinks>

=item * Search CPAN

L<https://metacpan.org/release/Win32-Symlinks>

=back


=head1 ACKNOWLEDGEMENTS

A small part of C code was taken from the Win32_Links project from Jlevens,
which has a GNU v2.0 license and can be found at
L<Github|https://github.com/Jlevens/Win32_Links>.


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021 by Francisco Zarabozo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1; # End of Win32::Symlinks
