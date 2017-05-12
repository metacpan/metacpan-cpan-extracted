package Test::LatestPrereqs::ModuleInstall;

use strict;
use warnings;
use Carp;
use File::Spec;
use Config;
use File::Find::Rule;
use Class::Inspector;

my %ignorable_mi_methods = map { $_ => 1 } qw(
  autoload call import new load load_extensions
  preload find_extensions AUTOLOAD DESTROY
);

sub parse {
  my ($class, $file) = @_;

  my @requires;
  no warnings 'redefine';
  local $INC{'inc/Module/Install.pm'} = 1;
  local $INC{'Module/Install/Base.pm'} = 1;
  local $inc::Module::Install::VERSION = '666'; # cheat version check
  local *inc::Module::Install::AUTOLOAD = sub { 1 };
  local @inc::Module::Install::EXPORT = _get_methods();
  local @inc::Module::Install::ISA = 'Exporter';
  local *inc::Module::Install::requires = sub {
    my %deps = (@_ == 1 ? ( $_[0] => 0 ) : @_);
    push @requires, [ $_, $deps{$_} || 0 ] for keys %deps;
  };
  local *inc::Module::Install::build_requires = sub {
    my %deps = (@_ == 1 ? ( $_[0] => 0 ) : @_);
    push @requires, [ $_, $deps{$_} || 0 ] for keys %deps;
  };
  local *inc::Module::Install::test_requires = sub {
    my %deps = (@_ == 1 ? ( $_[0] => 0 ) : @_);
    push @requires, [ $_, $deps{$_} || 0 ] for keys %deps;
  };
  local *inc::Module::Install::recommends = sub {
    my %deps = (@_ == 1 ? ( $_[0] => 0 ) : @_);
    push @requires, [ $_, $deps{$_} || 0 ] for keys %deps;
  };
  local *inc::Module::Install::feature = sub {
    my $name = shift;
    while ( @_ ) {
      my $key = shift;
      if ( $key =~ /^\-/ ) { shift; next }  # option
      if ( $key && !ref $key ) {
        push @requires, [ $key, shift || 0 ];
      }
    }
  };
  local *inc::Module::Install::features = sub {
    my %features = @_;
    while ( my ($name, $arrayref) = each %features ) {
      inc::Module::Install::feature( $name, @$arrayref );
    }
  };
  local *inc::Module::Install::include_deps = *inc::Module::Install::requires;
  local *inc::Module::Install::Makefile = sub { 'Test::LatestPrereqs::ModuleInstall::Fake' };
  local *inc::Module::Install::Meta     = sub { 'Test::LatestPrereqs::ModuleInstall::Fake' };

  eval {
    package main;
    no strict;
    no warnings;

    local *CORE::GLOBAL::exit = sub {};

    require "$file";
  };
  delete $INC{$file};

  if ($@ && $@ !~ /did not return a true value/) {
    croak "Makefile.PL error: $@";
  }

  return @requires;
}

sub _get_methods {
  my $dir = 'inc/Module/Install';
  unless (-d $dir) {
    $dir = File::Spec->catdir( $Config{sitelib}, 'Module/Install' );
    $dir =~ s{\\}{/}g;
  }

  my @methods;
  foreach my $file ( File::Find::Rule->file->name('*.pm')->in($dir) ) {
    eval {
      require File::Spec->rel2abs($file);
      my %seen;
      @methods = grep { !$seen{$_}++ && !$ignorable_mi_methods{$_} }
        @methods,
        @{ Class::Inspector->methods( _file_to_mod( $file ), 'public' ) };
      delete $INC{$file};
    };
    warn "inspecting error: $@" if $@;
  }

  return @methods;
}

sub _file_to_mod {
  my $file = shift;
  $file =~ s{\\}{/}g;
  $file =~ s{^.+/Module/Install}{Module/Install};
  $file =~ s{/}{::}g;
  $file =~ s{\.pm}{};
  $file;
}

package #
  Test::LatestPrereqs::ModuleInstall::Fake;
sub write {}

1;

__END__

=head1 NAME

Test::LatestPrereqs::ModuleInstall

=head1 SYNOPSIS

  my @requires = Test::LatestPrereqs::ModuleInstall->parse($makefile_pl);

=head1 DESCRIPTION

This is used internally to parse Makefile.PL (with L<Module::Install>) to get requirements.

=head1 METHODS

=head2 parse

parses Makefile.PL and returns a list of requirements.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
