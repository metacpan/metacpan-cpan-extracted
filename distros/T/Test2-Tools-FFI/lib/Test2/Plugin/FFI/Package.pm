package Test2::Plugin::FFI::Package;

use strict;
use warnings;
use 5.008001;
use FFI::CheckLib 0.11 qw( find_lib );
use Cwd qw( getcwd );
use File::Basename qw( basename );

# ABSTRACT: Plugin to test bundled FFI code without EUMM
our $VERSION = '0.05'; # VERSION


sub import
{
  require FFI::Platypus;

  my $old = \&FFI::Platypus::package;
  my $new = sub {
    my($ffi, $module, $modlibname) = @_;
    ($module, $modlibname) = caller() unless defined $modlibname;
    my $dist = $module;
    $dist =~ s/::/-/g;
    if(basename(getcwd()) eq $dist)
    {
      my @lib = find_lib(
        lib        => '*',
        libpath    => 'share/lib',
        systempath => [],
      );
      if(@lib)
      {
        $ffi->lib(@lib);
        return;
      }
    }
    $old->($ffi, $module, $modlibname);
  };

  no warnings 'redefine';
  *FFI::Platypus::package = $new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::FFI::Package - Plugin to test bundled FFI code without EUMM

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Test2::Plugin::FFI::Package;

=head1 DESCRIPTION

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
