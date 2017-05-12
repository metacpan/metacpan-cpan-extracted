package App::SmokeBrew::Plugin;
$App::SmokeBrew::Plugin::VERSION = '0.48';
#ABSTRACT: A Moose role for smokebrew plugins

use strict;
use warnings;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw[Dir File];
use MooseX::Types::Email qw[EmailAddress];
use App::SmokeBrew::Types qw[ArrayRefUri];

requires 'configure';

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

has 'perl_exe' => (
  is => 'ro',
  isa => File,
  required => 1,
  coerce => 1,
);

has 'mirrors' => (
  is => 'ro',
  isa => 'ArrayRefUri',
  auto_deref => 1,
  required => 1,
  coerce => 1,
);

has 'email' => (
  is => 'ro',
  isa => EmailAddress,
  required => 1,
);

has 'mx' => (
  is => 'ro',
  isa => 'Str',
);

has 'noclean' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has 'verbose' => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

no Moose::Role;

qq[Smokin'];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::Plugin - A Moose role for smokebrew plugins

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  package App::SmokeBrew::Plugin::Some::Plugin;

  use Moose;

  with 'App::SmokeBrew::Plugin';

=head1 DESCRIPTION

App::SmokeBrew::Plugin is a L<Moose> role that L<smokebrew> plugins must consume.

=head1 ATTRIBUTES

These are the attributes provided by the role and are expected by L<smokebrew>:

=over

=item C<email>

A required attribute, this must be a valid email address as constrained by L<MooseX::Types::Email>

=item C<builddir>

A required attribute, this is the working directory where builds can take place. It will be coerced
into a L<Path::Class::Dir> object by L<MooseX::Types::Path::Class>.

=item C<prefix>

A required attribute, this is the prefix of the location where perl installs will be made, it will be coerced
into a L<Path::Class::Dir> object by L<MooseX::Types::Path::Class>.

example:

  prefix = /home/cpan/pit/rel
  perls will be installed as /home/cpan/pit/perl-5.12.0, /home/cpan/pit/perl-5.10.1, etc.

=item C<perl_exe>

A required attribute, this is the path to the perl executable that the plugin will configure, it will be
coerced to a L<Path::Class::File> object by L<MooseX::Types::Path::Class>.

=item C<mirrors>

A required attribute, this is an arrayref of L<URI> objects representing CPAN Mirrors to use. It uses
type C<ArrayRefUri> from L<App::SmokeBrew::Types>, so will coerce L<URI> objects from ordinary strings and
from an arrayref of strings. It is set to C<auto_deref>.

=item C<mx>

Optional attribute, which has no default value, this is the address or IP address of a mail exchanger to use
for sending test reports.

=item C<verbose>

Optional boolean attribute, which defaults to 0, indicates whether the plugin should produce verbose output.

=item C<noclean>

Optional boolean attribute, which defaults to 0, indicates whether the plugin should cleanup files that it
produces under the C<builddir> or not.

=back

=head1 METHODS

Consumer classes as required to implement the following methods:

=over

=item C<configure>

Called by L<smokebrew> to configure the given perl for CPAN Testing.

=back

=head1 PLUGIN OPTIONS

L<App::SmokeBrew> will pass any options it finds in a named section of the configuration file for a
plugin when it a new plugin instance. See L<smokebrew> for details. You are expected to document any options
that may be passed to your plugin in this manner.

=head1 SEE ALSO

L<smokebrew>

L<Moose::Role>

L<MooseX::Types::Email>

L<MooseX::Types::Path::Class>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
