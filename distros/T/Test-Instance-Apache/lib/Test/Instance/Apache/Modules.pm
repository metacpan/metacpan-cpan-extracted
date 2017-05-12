package Test::Instance::Apache::Modules;

use Moo;
use IO::All;

=head1 NAME

Test::Instance::Apache::Modules - Apache module management for T::I::A

=head1 SYNOPSIS

  use FindBin qw/ $Bin /;
  use Test::Instance::Apache::Modules;

  my $modules = Test::Instance::Apache::Modules->new(
    server_root => "$Bin/conf",
    modules => [ qw/ mpm_prefork authz_core mome / ],
  );

  # get include paths for config
  my $paths = $modules->include_modules;

=head1 DESCRIPTION

Test::Instance::Apache::Modules sets up the required modules for Apache
according to an array of module names. This functions similarly to C<a2enmod>
which comes as part of the Apache distribution, however is much more simplified
to only do what is necessary for T::I::A.

The module creates a C<mods-available> and C<mods-enabled> folder inside the
L</server_root> directory, and then copies the contents of
C</etc/apache2/mods-available> into the new C<mods-available> folder. Then,
symlinks are created across to the C<mods-enabled> folder, ready for Apache to
include from the L</include_modules> list.

=head2 Attributes

These are the available attributes on Test::Instance::Apache::Modules

=head3 modules

The arrayref of modules to symlink into C<mods-enabled> folder. This is
required. Note that any modules specified here will need to be installed on
your local machine, and you will have to specify ALL modules required - there
are no assumptions made for modules to include.

=cut

has modules => (
  is => 'ro',
  required => 1,
  isa => sub { die "modules must be an array!\n" unless ref $_[0] eq 'ARRAY' },
);

=head3 server_root

The root directory of the server config. This directory is where
C<mods-available> and C<mods-enabled> directories will be created. This
attribute is required.

=cut

has server_root => (
  is => 'ro',
  required => 1,
);

has _available_mods_folder => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->make_server_dir( 'mods-available' );
  },
);

has _enabled_mods_folder => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->make_server_dir( 'mods-enabled' );
  },
);

=head3 include_modules

This creates the include paths for the C<conf> and C<load> files as required by
Apache.

=cut

has include_modules => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    my @include;
    foreach ( qw/ load conf / ) {
      push @include, 'Include';
      push @include, sprintf( '%s/*.%s', $self->_enabled_mods_folder, $_ );
    }
    return \@include;
  },
);

=head2 Methods

These are the methods available on Test::Instance::Apache::Modules.

=head3 load_modules

This function performs the main part of this module. This copies all the
current mods from C</etc/apache2/mods-available> to the C<mods-available>
directory, and then symlinks all the required modules across to the
C<mods-enabled> folder.

=cut

sub load_modules {
  my $self = shift;

  io->dir( '/etc/apache2/mods-available' )->copy( $self->_available_mods_folder );

  for my $module ( @{ $self->modules } ) {
    for my $suffix ( qw/ conf load / ) {
      my $source_filename = File::Spec->catfile(
        $self->_available_mods_folder,
        sprintf( '%s.%s', $module, $suffix )
      );
      my $target_filename = File::Spec->catfile(
        $self->_enabled_mods_folder,
        sprintf( '%s.%s', $module, $suffix )
      );
      if ( -f $source_filename ) {
        # if the file does not exist, just ignore it as not all mods have config files
        symlink( $source_filename, $target_filename );
      } 
    }
  }
}

=head3 make_server_dir

Utility function to create a new directory in the L</server_root>.

=cut

sub make_server_dir {
  my ( $self, @dirnames ) = @_;
  my $dir = File::Spec->catdir( $self->server_root, @dirnames );
  mkdir $dir;
  return $dir;
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 COPYRIGHT

Copyright 2016 Tom Bloor

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Test::Instance::Apache>

=back

=cut

1;
