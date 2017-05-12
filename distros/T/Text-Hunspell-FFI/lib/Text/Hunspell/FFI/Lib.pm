package Text::Hunspell::FFI::Lib;

use strict;
use warnings;

our $VERSION = '0.02'; # VERSION

sub _libs
{
  my @libs = eval {
    require Alien::Hunspell;
    Alien::Hunspell->dynamic_libs;
  };

  @libs = eval {
    require FFI::CheckLib;
    FFI::CheckLib::find_lib(
      lib => "*", 
      verify => sub { $_[0] =~ /hunspell/ }, 
      symbol => "Hunspell_create"
    );
  } unless(@libs);

  @libs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Hunspell::FFI::Lib

=head1 VERSION

version 0.02

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
