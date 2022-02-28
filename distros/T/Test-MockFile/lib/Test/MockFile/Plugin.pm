package Test::MockFile::Plugin;

use strict;
use warnings;

use Carp qw(croak);
require Test::MockFile;    # load Test::MockFile without setting the strict mode

our $VERSION = '0.032';

sub new {
    my ( $class, %opts ) = @_;

    my $self = bless {%opts}, $class;
    return $self;
}

sub register {
    my ($self) = @_;

    croak('Method "register" not implemented by plugin');
}

1;

=encoding utf8

=head1 NAME

Test::MockFile::Plugin - Plugin base class

=head1 SYNOPSIS

  package Test::MockFile::Plugin::YourCustomPlugin;

  use base 'Test::MockFile::Plugin';

  sub register {

    my ( $self ) = @_;

    # Code to setup your plugin here
    ...
  }

=head1 DESCRIPTION

L<Test::MockFile::Plugin> is an abstract base class for L<Test::MockFile> plugins.

=head1 METHODS

=head2 new( %opts )

Constructor provided to all Plugin packages so they have a location to store
their internal data.

=head2 register

  $plugin->register();

This method will be called by L<Test::MockFile::Plugins> on imports.

=head1 SEE ALSO

L<Test::MockFile>

=cut
