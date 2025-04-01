package all::mandatory;

use 5.006;
use strict;
use warnings;

use File::Spec ();
use File::Find ();

our $VERSION = 0.02;

sub import {
  my $class = shift;
  my $of    = shift;
  my $args  = [ @_ ];
  if ($of ne 'of') {
    unshift @$args, $of;
  }
  foreach my $arg (@$args) {
    my $modules = _find_modules( $arg );

    @$modules
      or die "all::mandatory - No modules under $arg namespace exist";

    foreach my $module (@$modules) {
      my $package = $module->{ module };
      eval {
        require $module->{ path };
        $package->import;
        1;
      } or die "all::mandatory - Could not load module $module->{path}:\n$@\n";
    }
  }
  1;
}

sub _find_modules {
  my $module = shift;
  my $moduledir = _module_to_file( $module );
  my $list = [];

  foreach my $incdir (@INC) {
    next if ref $incdir;

    my $dir = File::Spec->catfile($incdir, $moduledir);
    next unless -d $dir;

    my @files = ();
    File::Find::find({
        wanted => sub {
            return unless $File::Find::name =~ /\.pm$/;
            push @files, $File::Find::name;
        },
        no_chdir => 1,
    }, $dir);

    foreach my $absfile (@files) {
      my $relfile = File::Spec->abs2rel( $absfile, $incdir );
      push @$list, {
		    path   => $relfile,
		    module => _file_to_module( $relfile )
		   };
    }
  }
  return $list;
}

sub _file_to_module {
  my $file = shift;
  $file    =~ s/\.pm$//;
  my @list = File::Spec->splitpath( $file );
  shift @list;
  return join('::',  @list)
}

sub _module_to_file {
  my $module = shift;
  $module =~ s{::\*?$}{};
  $module =~ s{::}{/}g;
  return $module;
}

1;

__END__

=head1 NAME

all::mandatory - Load all packages under a namespace, but
die instead of warn if a module fails to load.

=head1 SYNOPSIS

  # use everything in the IO:: namespace
  use all::mandatory of => 'IO::*';
  use all::mandatory 'IO::*';

  # use everything in the IO:: and Sys:: namespaces
  use all::mandatory 'IO::*', 'Sys::*';
  use all::mandatory of => qw{IO::* Sys::*};

=head1 DESCRIPTION

Duplicate of the 'all' CPAN module, but will die if a module
cannot be loaded, or if no modules under a namespace can be found.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

Piotr Roszatycki <dexter@cpan.org>

Dondi Michael Stroma <dstroma@gmail.com>

=head1 LICENSE

Copyright 2003 Fotango Ltd. All Rights Reserved.

Copyright 2008 Piotr Roszatycki <dexter@cpan.org>.

Copyright 2025 Dondi Michael Stroma <dstroma@gmail.com>.

This module is released under the same terms as Perl itself.

=cut
