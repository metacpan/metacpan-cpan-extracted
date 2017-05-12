package App::SmokeBrew::BuildPerl;
$App::SmokeBrew::BuildPerl::VERSION = '0.48';
#ABSTRACT: build and install a particular version of Perl

use strict;
use warnings;
use App::SmokeBrew::Tools;
use Log::Message::Simple qw[msg error];
use CPAN::Perl::Releases qw[perl_tarballs];
use Perl::Version;
use File::Spec;
use Devel::PatchPerl;
use Config      qw[];
use Cwd         qw[chdir cwd];
use IPC::Cmd    qw[run can_run];
use File::Path  qw[mkpath rmtree];
use File::pushd qw[pushd];

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw[Dir];
use App::SmokeBrew::Types qw[ArrayRefStr ArrayRefUri];

with 'App::SmokeBrew::PerlVersion';

my @mirrors = (
  'http://www.cpan.org/',
  'http://cpan.cpantesters.org/',
  'http://cpan.hexten.net/',
  'ftp://ftp.funet.fi/pub/CPAN/',
);

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

has 'perlargs' => (
  is => 'ro',
  isa => 'ArrayRefStr',
  default => sub { [] },
  auto_deref => 1,
);

has 'skiptest' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'verbose' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
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

has 'make' => (
  is => 'ro',
  isa => 'Str',
  default => sub { my $make = $Config::Config{make} || 'make'; can_run( $make ) },
);

has 'mirrors' => (
  is => 'ro',
  isa => 'ArrayRefUri',
  default => sub { \@mirrors },
  coerce => 1,
);

sub build_perl {
  my $self = shift;
  my $perl_version = $self->perl_version;
  msg(sprintf("Starting build for '%s'",$perl_version), $self->verbose);
  $self->builddir->mkpath();
  my $file = $self->_fetch();
  return unless $file;
  my $extract = $self->_extract( $file );
  return unless $extract;
  unlink( $file ) unless $self->noclean();
  $self->prefix->mkpath();
  my $prefix = File::Spec->catdir( $self->prefix->absolute, $perl_version );
  msg("Removing existing installation at ($prefix)", $self->verbose );
  rmtree( $prefix );
  msg('Applying any applicable patches to the source', $self->verbose );
  Devel::PatchPerl->patch_source( $self->version->stringify, $extract );
  {
    my $CWD = pushd( $extract );
    mkpath( File::Spec->catdir( $prefix, 'bin' ) );
    my @conf_opts = $self->perlargs;
    push @conf_opts, '-Dusedevel' if $self->is_dev_release();
    unshift @conf_opts, '-Dprefix=' . $prefix;
    local $ENV{MAKE} = $self->make;
    my $cmd = [ './Configure', '-des', @conf_opts ];
    return unless scalar run( command => $cmd,
                         verbose => 1, );
    return unless scalar run( command => [ $self->make ], verbose => $self->verbose );
    unless ( $self->skiptest ) {
      return unless scalar run( command => [ $self->make, 'test' ], verbose => $self->verbose );
    }
    return unless scalar run( command => [ $self->make, 'install' ], verbose => $self->verbose );
    rmtree ( File::Spec->catdir( $prefix, 'man' ) ) # remove the manpages
      unless $self->nozapman;
  }
  rmtree( $extract ) unless $self->noclean();
  return $prefix;
}

sub _fetch {
  my $self = shift;
  my $perldist;
  {
    ( my $version = $self->perl_version ) =~ s/perl-//g;
    my $tarballs = perl_tarballs( $version );
    $perldist = 'authors/id/' . $tarballs->{'tar.gz'};
  }
  msg("Fetching '" . $perldist . "'", $self->verbose);
  my $stat = App::SmokeBrew::Tools->fetch( $perldist, $self->builddir->absolute, $self->mirrors );
  return $stat if $stat;
  error("Failed to fetch '". $perldist . "'", $self->verbose);
  return $stat;
}

sub _extract {
  my $self = shift;
  my $tarball = shift || return;
  msg("Extracting '$tarball'", $self->verbose);
  return App::SmokeBrew::Tools->extract( $tarball, $self->builddir->absolute );
}

no Moose;

__PACKAGE__->meta->make_immutable;

qq[Building a perl];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::BuildPerl - build and install a particular version of Perl

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  use strict;
  use warnings;
  use App::SmokeBrew::BuildPerl;

  my $bp = App::SmokeBrew::BuildPerl->new(
    version     => '5.12.0',
    builddir   => 'build',
    prefix      => 'prefix',
    skiptest    => 1,
    verbose     => 1,
    perlargs    => [ '-Dusemallocwrap=y', '-Dusemymalloc=n' ],
  );

  my $prefix = $bp->build_perl();

  print $prefix, "\n";

=head1 DESCRIPTION

App::SmokeBrew::BuildPerl encapsulates the task of configuring, building, testing and installing
a perl executable ( and associated core modules ).

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new App::SmokeBrew::BuildPerl object. Takes a number of options.

=over

=item C<version>

A required attribute, this is the version of perl to install. Must be a valid perl version.

=item C<builddir>

A required attribute, this is the working directory where builds can take place. It will be coerced
into a L<Path::Class::Dir> object by L<MooseX::Types::Path::Class>.

=item C<prefix>

A required attribute, this is the prefix of the location where perl installs will be made, it will be coerced
into a L<Path::Class::Dir> object by L<MooseX::Types::Path::Class>.

example:

  prefix = /home/cpan/pit/rel
  perls will be installed as /home/cpan/pit/perl-5.12.0, /home/cpan/pit/perl-5.10.1, etc.

=item C<skiptest>

Optional boolean attribute, which defaults to 0, indicates whether the testing phase of the perl installation
( C<make test> ) should be skipped or not.

=item C<perlopts>

Optional attribute, takes an arrayref of perl configuration flags that will be passed to C<Configure>.
There is no need to specify C<-Dprefix> or C<-Dusedevel> as the module handles these for you.

  perlopts => [ '-Dusethreads', '-Duse64bitint' ],

=item C<verbose>

Optional boolean attribute, which defaults to 0, indicates whether we should produce verbose output.

=item C<noclean>

Optional boolean attribute, which defaults to 0, indicates whether we should cleanup files that we
produce under the C<builddir> or not.

=item C<nozapman>

This is an optional boolean attribute. Usually C<man> pages that are generated by the perl installation are removed.
Specify this option if you wish the C<man> pages to be retained.

=item C<make>

Optional attribute to specify the C<make> utility to use. Defaults to C<make> and you should only have to
mess with this on wacky platforms.

=item C<mirrors>

This is an optional argument. Specify the URL of a CPAN mirror that should be used for retrieving required files
during the build process. This may be a single URL or an arrayref of a number of URLs.

=back

=back

=head1 METHODS

=over

=item C<build_perl>

Fetches, extracts, configures, builds, tests (see C<skiptest>) and installs the C<perl> executable.

The C<builddir> is used for the first five processes. Installation is made into the given C<prefix>
directory.

=back

=head1 SEE ALSO

L<App::perlbrew>

L<Module::CoreList>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
