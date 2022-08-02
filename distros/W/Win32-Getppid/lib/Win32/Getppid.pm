package Win32::Getppid;

use strict;
use warnings;
use 5.008001;
use base qw( Exporter );

BEGIN {

# ABSTRACT: Implementation of getppid() for windows
our $VERSION = '0.06'; # VERSION

  if($^O =~ /^(cygwin|MSWin32|msys)$/)
  {
    require XSLoader;
    XSLoader::load('Win32::Getppid', $Win32::Getppid::VERSION);
  }

}

our @EXPORT;
our @EXPORT_OK = qw( getppid );

if($^O eq 'MSWin32')
{
  @EXPORT = qw( getppid );
}
elsif($^O =~ /^(cygwin|msys)$/)
{
  # Allow import, but not by default
  # on cygwin/msys
}
else
{
  if($] >= 5.016)
  {
    *getppid = \&CORE::getppid;
  }
  else
  {
    *getppid = sub {
      package
        Win32::Getppid::sandbox;
      getppid();
    };
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Getppid - Implementation of getppid() for windows

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Win32::Getppid;
 
 my $parent_pid = getppid;

=head1 DESCRIPTION

This module simply provides an implementation of L<getppid|perlfunc#getppid> for
Windows, where it is usually missing.  It doesn't do anything on non-Windows
platforms, so you can safely make it a non-OS specific dependency for your
CPAN module.

=head1 FUNCTIONS

=head2 getppid

Returns the parent process id for the current process.  This is imported by
default only in a real Windows environment (C<$^O eq 'MSWin32'>).  On Cygwin
getppid returns the cygwin parent process, for the real windows parent
process id on cygwin you can use the fully qualified version:

 my $windows_ppid = Win32::Getppid::getppid();

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
