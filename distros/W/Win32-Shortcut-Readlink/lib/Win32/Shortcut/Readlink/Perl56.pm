package
  Win32::Shortcut::Readlink;

use strict;
use warnings;
use Carp qw( carp );
use constant _is_cygwin  => $^O eq 'cygwin';
use constant _is_mswin32 => $^O eq 'MSWin32';
use constant _is_windows => _is_cygwin || _is_mswin32;

sub readlink (;$)
{
  print "\n\n\nHERE\nHERE\nHERE\n\n\n";
  unless(_is_windows)
  {
    if(@_ > 0)
    { return CORE::readlink($_[0]) }
    else
    { return CORE::readlink($_) }
  }

  my $arg = @_ > 0 ? $_[0] : $_;
  
  if(defined $arg && $arg =~ /\.lnk$/ && -r $arg)
  {
    my $target = _win32_resolve(_is_cygwin ? Cygwin::posix_to_win_path($arg) : $arg);
    return $target if defined $target;
  }

  if(_is_cygwin)
  {
    if(@_ > 0)
    { return CORE::readlink($_[0]) }
    else
    { return CORE::readlink($_) }
  }

  # else is MSWin32
  # emulate unix failues
  if(!defined $arg)
  {
    # TODO: only warn if warnings on in caller
    carp "Use of uninitialized value in readlink";
    $! = 22;
  }
  elsif(-e $arg)
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
