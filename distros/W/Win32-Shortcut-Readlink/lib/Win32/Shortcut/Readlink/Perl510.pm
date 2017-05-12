package
  Win32::Shortcut::Readlink;

use strict;
use warnings;
use Carp qw( carp );
use constant _is_cygwin  => $^O eq 'cygwin';
use constant _is_mswin32 => $^O eq 'MSWin32';
use constant _is_windows => _is_cygwin || _is_mswin32;

sub _real_readlink (_);
# TODO: only warn in 5.14 or earlier if warnings on in caller
*_real_readlink = eval { require 5.016000 } ? \&CORE::readlink : sub (_) { CORE::readlink($_[0]) };

sub readlink (_)
{
  goto &_real_readlink unless _is_windows;
  
  if(defined $_[0] && $_[0] =~ /\.lnk$/ && -r $_[0])
  {
    my $target = _win32_resolve(_is_cygwin ? Cygwin::posix_to_win_path($_[0]) : $_[0]);
    return $target if defined $target;
  }

  goto &_real_readlink if _is_cygwin;

  # else is MSWin32
  # emulate unix failues
  if(!defined $_[0])
  {
    # TODO: only warn if warnings on in caller
    carp "Use of uninitialized value in readlink";
    $! = 22;
  }
  elsif(-e $_[0])
  {
    $! = 22; # Invalid argument
  }
  else
  {
    $! = 2; # No such file or directory
  }
  
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Shortcut::Readlink

=head1 VERSION

version 0.02

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
