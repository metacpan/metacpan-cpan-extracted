package Alien::libt2t;

use strict;
use warnings;
use 5.008001;
use File::ShareDir::Dist ();

# ABSTRACT: Alien::libt2t
our $VERSION = '0.05'; # VERSION


sub new
{
  my($class) = @_;
  bless {}, $class;
}


sub dist_dir
{
  my $dir = File::ShareDir::Dist::dist_share('Test2-Tools-FFI');
  $dir =~ s{\\}{/}g if $^O eq 'MSWin32';
  $dir;
}


sub cflags
{
  my($class) = @_;
  my $dist = $class->dist_dir;
  "-I$dist/include ";
}


sub libs
{
  my($class) = @_;
  my $dist = $class->dist_dir;
  "-Wl,-rpath,$dist/lib -L$dist/lib -lt2t ";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libt2t - Alien::libt2t

=head1 VERSION

version 0.05

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 my $alien = Alien::libt2t->new;

It is not necessary, but you can create an instance for compatibility
with L<Alien::Base>.

=head1 METHODS

=head2 dist_dir

 my $dir = Alien::libt2t->dist_dir;

Returns the directory where the libt2t library is installed.

=head2 cflags

 my $flags = Alien::libt2t->cflags;

Returns the compiler flags.

=head2 libs

 my $libs = Alien::libt2t->libs;

Returns the library flags.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
