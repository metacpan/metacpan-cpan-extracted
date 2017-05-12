package App::SmokeBrew;
$App::SmokeBrew::VERSION = '0.48';
#ABSTRACT: The guts of smokebrew

use strict;
use warnings;
use Pod::Usage;
use Log::Message::Simple qw[msg error];
use Module::Load::Conditional qw[can_load];
use App::SmokeBrew::IniFile;
use App::SmokeBrew::Tools;
use App::SmokeBrew::BuildPerl;
use Module::Pluggable search_path => 'App::SmokeBrew::Plugin';
use File::Spec;
use Cwd;
use Getopt::Long;

my @mirrors = (
  'http://www.cpan.org/',
  'http://cpan.cpantesters.org/',
  'http://cpan.hexten.net/',
  'ftp://ftp.funet.fi/pub/CPAN/',
);

use Moose;

with 'MooseX::Getopt', 'MooseX::ConfigFromFile';

use App::SmokeBrew::Types qw[ArrayRefUri ArrayRefStr];

sub get_config_from_file {
  my ($class,$file) = @_;
  my $options_hashref = App::SmokeBrew::IniFile->read_file($file);
  my $opts = delete $options_hashref->{_};
  $opts->{_plugins}->{$_} = delete $options_hashref->{$_}
    for keys %{ $options_hashref };
  return $opts;
}

has 'configfile' => (
  is => 'ro',
  default => sub {
      my $file = File::Spec->catfile(
          App::SmokeBrew::Tools->smokebrew_dir(),
          '.smokebrew', 'smokebrew.cfg' );
      return unless -e $file;
      return $file;
  },
);

use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw[Dir File];
use MooseX::Types::Email qw[EmailAddress];

# Mandatory

has 'builddir' => (
  is => 'ro',
  isa => Dir,
  required => 1,
  coerce => 1,
);

has 'prefix' => (
  is => 'ro',
  isa => Dir,
  required => 1,
  coerce => 1,
);

has 'email' => (
  is => 'ro',
  isa => EmailAddress,
  required => 1,
);

has 'plugin' => (
  is => 'ro',
  isa => subtype(
          as 'Str',
          where {
                  my $plugin = $_;
                  return grep { $plugin eq $_ or /\Q$plugin\E$/ } __PACKAGE__->plugins;
          },
          message { "($_) is not a valid plugin" }
  ),
  required => 1,
  writer => '_set_plugin',
  trigger => sub {
    my ($self,$plugin,$old) = @_;
    return if $old;
    $self->_set_plugin( grep { $plugin eq $_ or /\Q$plugin\E$/ } __PACKAGE__->plugins );
  },
);

# Multiple

has 'mirrors' => (
  is => 'ro',
  isa => 'ArrayRefUri',
  default => sub { \@mirrors },
  coerce => 1,
);

has 'perlargs' => (
  is => 'ro',
  isa => 'ArrayRefStr',
  coerce => 1,
);

# Optional

has 'mx' => (
  is => 'ro',
  isa => 'Str',
);

has 'noclean' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'nozapman' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'verbose' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'skiptest' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'forcecfg' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'force' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'make' => (
  is => 'ro',
  isa => 'Str',
);

# What perl versions to install

has 'stable' => (
  is => 'ro',
  isa => 'Bool',
);

has 'devel' => (
  is => 'ro',
  isa => 'Bool',
);

has 'recent' => (
  is => 'ro',
  isa => 'Bool',
);

has 'modern' => (
  is => 'ro',
  isa => 'Bool',
);

has 'latest' => (
  is => 'ro',
  isa => 'Bool',
);

has 'install' => (
  is => 'ro',
  isa => 'Str',
);

# Internal

has '_perls' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  init_arg => undef,
  lazy_build => 1,
  auto_deref => 1,
);

has '_plugins' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { { } },
);

sub _build__perls {
  my $self = shift;
  my $arg;
  $arg = 'rel' if $self->stable;
  $arg = 'dev' if $self->devel;
  $arg = 'recent' if $self->recent;
  $arg = 'modern' if $self->modern;
  $arg = 'latest' if $self->latest;
  $arg = $self->install if $self->install;
  return [ grep { $_ ne '5.6.0' and $_  ne '5.8.0' } App::SmokeBrew::Tools->perls( $arg ) ];
}

sub run {
  my $self = shift;
  PERL: foreach my $perl ( $self->_perls ) {
    msg( "Building perl ($perl)", $self->verbose );
    my $perl_exe;
    unless ( -e $self->_perl_exe( $perl ) and !$self->force ) {
      my $build = App::SmokeBrew::BuildPerl->new(
        version   => $perl,
        map { ( $_ => $self->$_ ) }
          grep { defined $self->$_ }
            qw(builddir prefix verbose noclean nozapman skiptest perlargs mirrors make),
      );
      unless ( $build ) {
        error( "Could not create a build object for ($perl)", $self->verbose );
        next PERL;
      }
      my $location = $build->build_perl();
      unless ( $location ) {
        error( "Could not build perl ($perl)", $self->verbose );
        next PERL;
      }
      $perl_exe =
      File::Spec->catfile( $location, 'bin', ( App::SmokeBrew::Tools->devel_perl( $perl ) ? "perl$perl" : 'perl' ) );
      msg( "Successfully built ($perl_exe)", $self->verbose );
    }
    else {
      msg("The perl exe already exists skipping build", $self->verbose);
      next PERL unless $self->forcecfg;
      $perl_exe = $self->_perl_exe( $perl );
    }
    msg( "Configuring (" . $self->plugin .")", $self->verbose );
    unless ( can_load( modules => { $self->plugin, '0.0' } ) ) {
      error( "Could not load plugin (" . $self->plugin . ")", $self->verbose );
      next PERL;
    }
    my @plugopts;
    {
      my $plugopts;
      my $plugin = $self->plugin;
      ($plugopts) = grep { $plugin eq $_ or $plugin =~ /\Q$_\E$/ } keys %{ $self->_plugins };
      @plugopts = map { ( $_ => $self->_plugins->{ $plugopts }->{$_} ) }
        grep { defined $self->_plugins->{ $plugopts }->{$_} }
          keys %{ $self->_plugins->{ $plugopts } } if $plugopts;
    }
    my $plugin = $self->plugin->new(
      version   => $perl,
      perl_exe  => $perl_exe,
      ( map { ( $_ => $self->$_ ) }
        grep { defined $self->$_ }
          qw(builddir prefix verbose noclean mirrors email mx)
      ),
      @plugopts,
    );
    unless ( $plugin ) {
      error( "Could not make plugin (" . $self->plugin . ")", $self->verbose );
      next PERL;
    }
    unless ( $plugin->configure ) {
      error( "Could not configure plugin (" . $self->plugin . ")", $self->verbose );
      next PERL;
    }
    msg( "Finished build and configuration for perl ($perl)", $self->verbose );
  }
}

sub _perl_exe {
  my $self = shift;
  my $perl = shift || return;
  return
    File::Spec->catfile(
      $self->prefix->absolute,
      App::SmokeBrew::Tools->perl_version($perl),
      'bin',
      ( App::SmokeBrew::Tools->devel_perl( $perl ) ? "perl$perl" : 'perl' ) )
}

q[Smokebrew, look what's inside of you];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew - The guts of smokebrew

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  use strict;
  use warnings;
  use App::SmokeBrew;

  App::SmokeBrew->new_with_options()->run();

=head2 C<new_with_options>

Create a new App::SmokeBrew object

=head2 C<run>

This method is called by L<smokebrew> to do all the work.

=head2 C<get_config_from_file>

This method is required by L<MooseX::ConfigFromFile> to load the C<configfile>.

=head1 SEE ALSO

L<smokebrew>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
