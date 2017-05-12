package Win32::Shortcut::Readlink;

require 5.008000;
use strict;
use warnings;
use base qw( Exporter );

BEGIN {

# ABSTRACT: Make readlink work with shortcuts
our $VERSION = '0.02'; # VERSION

  if($^O =~ /^(cygwin|MSWin32)$/)
  {
    require XSLoader;
    XSLoader::load('Win32::Shortcut::Readlink', $Win32::Shortcut::Readlink::VERSION);
  }

}


our @EXPORT_OK = qw( readlink );
our @EXPORT    = @EXPORT_OK;


if(eval { require 5.010000 })
{
  require Win32::Shortcut::Readlink::Perl510;
}
elsif(eval { require 5.008000 })
{
  require Win32::Shortcut::Readlink::Perl58;
}
else
{
  # TODO: doesn't currently work.  Figure out
  # if this is a limitation of Perl 5.6 or if
  # I am just doing it wrong.  Fix or remove
  # if appropriate.  BTW- dist requires 5.8
  # so shouldn't even get in here if installed
  # without hacking.
  require Win32::Shortcut::Readlink::Perl56;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Shortcut::Readlink - Make readlink work with shortcuts

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Win32::Shortcut::Readlink;
 
 my $target = readlink "c:\\users\\foo\\Desktop\\Application.lnk";

=head1 DESCRIPTION

This module overloads the perl built-in function L<readlink|perlfunc#readlink>
so that it will treat shortcuts like pseudo symlinks on C<cygwin> and C<MSWin32>.
This module doesn't do anything on any other platform, so you are free to make
this a dependency, even if your module or script is going to run on non-Windows
platforms.

This module adjusts the behavior of readlink ONLY in the calling module, so
you shouldn't have to worry about breaking other modules that depend on the
more traditional behavior.

=head1 FUNCTION

=head2 readlink

 my $target = readlink EXPR
 my $target = readlink

Returns the value of a symbolic link or the target of the shortcut on Windows,
if either symbolic links are implemented or if shortcuts are.  If not, raises an 
exception.  If there is a system error, returns the undefined value and sets 
C<$!> (errno). If C<EXPR> is omitted, uses C<$_>.

=head1 CAVEATS

Does not handle Unicode.  Patches welcome.

Before Perl 5.16, C<CORE> functions could not be aliased, and you will see warnings
on Perl 5.14 and earlier if you pass undef in as the argument to readlink, even if
you have warnings turned off.  The work around is to make sure that you never pass
undef to readlink on Perl 5.14 or earlier.

Perl 5.8.x is somewhat supported.  The use of implicit C<$_> with readlink in
Perl 5.8.x is not supported and will throw an exception.  It is recommended that
you either upgrade to at least Perl 5.10 or pass an explicit argument of readlink
when using this module.

=head1 SEE ALSO

=over 4

=item L<Win32::Shortcut>

=item L<Win32::Unicode::Shortcut>

=item L<Win32::Symlink>

=item L<Win32::Hardlink>

=back

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
