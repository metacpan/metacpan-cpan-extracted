package Web::Components::Role::TT;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.8.%d', q$Rev: 1 $ =~ /\d+/gmx );

use File::DataClass::Constants qw( EXCEPTION_CLASS NUL TRUE );
use File::DataClass::Types     qw( Directory Object );
use Template;
use Unexpected::Functions      qw( PathNotFound throw );
use Moo::Role;

requires qw( config ); # layout skin tempdir vardir

# Attribute constructors
my $_build_templates = sub {
   my $self = shift; my $conf = $self->config; my $dir;

   $conf->can( 'vardir' ) and $dir = $conf->vardir->catdir( 'templates' );

   return ($dir && $dir->exists) ? $dir : $conf->root->catdir( 'templates' );
};

my $_build__templater = sub {
   my $self        =  shift;
   my $args        =  {
      COMPILE_DIR  => $self->config->tempdir->catdir( 'ttc' ),
      COMPILE_EXT  => 'c',
      ENCODING     => 'utf8',
      RELATIVE     => TRUE,
      INCLUDE_PATH => [ $self->templates->pathname ], };
   # uncoverable branch true
   my $template    =  Template->new( $args ) or throw $Template::ERROR;

   return $template;
};

# Public attributes
has 'templates'  => is => 'lazy', isa => Directory, coerce => TRUE,
   builder       => $_build_templates;

# Private attributes
has '_templater' => is => 'lazy', isa => Object, builder => $_build__templater;

# Private functions
my $_layout = sub {
   my ($conf, $stash) = @_;

   my $page   = $stash->{page} //= {};
   my $plate  = $stash->{template} //= {};
   my $layout = $plate->{layout} // $page->{layout} // $conf->layout;

   return $plate->{layout} = $page->{layout} = $layout;
};

my $_skin = sub {
   my ($conf, $stash) = @_;

   my $plate = $stash->{template} //= {};
   my $skin  = $plate->{skin} // $stash->{skin} // $conf->skin;

   return $plate->{skin} = $stash->{skin} = $skin;
};

my $_rel_template_path = sub {
   my ($self, $conf, $stash, $layout) = @_; my $templates = $self->templates;

   my $path = $templates->catfile( $_skin->( $conf, $stash ), "${layout}.tt" );

   $path->exists and return $path->abs2rel( $templates );

   my $alt  = $templates->catfile( $conf->skin, "${layout}.tt" );

   $alt->exists or throw PathNotFound, [ $path ];

   return $alt->abs2rel( $templates );
};

# Public methods
sub render_template {
   my ($self, $stash) = @_; $stash //= {};

   my $result = NUL;
   my $conf   = $stash->{config} //= $self->config;
   my $layout = $_layout->( $conf, $stash );

   if (ref $layout) {
      $self->_templater->process( $layout, $stash, \$result )
         or throw $self->_templater->error;
   }
   else {
      my $path = $self->$_rel_template_path( $conf, $stash, $layout );

      # uncoverable branch true
      $self->_templater->process( $path, $stash, \$result )
         or throw $self->_templater->error;
   }

   return $result;
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-web-components-role-tt"><img src="https://travis-ci.org/pjfl/p5-web-components-role-tt.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/web-components-role-tt/latest"><img src="https://roxsoft.co.uk/coverage/badge/web-components-role-tt/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/Web-Components-Role-TT"><img src="https://badge.fury.io/pl/Web-Components-Role-TT.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Web-Components-Role-TT"><img src="http://cpants.cpanauthors.org/dist/Web-Components-Role-TT.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Web::Components::Role::TT - Applies Template as a Moo::Role

=head1 Synopsis

   use Moo;

   with 'Web::Components::Role::TT';

   $rendered_template = $self->render_template( $stash );

=head1 Description

Uses L<Template> to render templates, typically producing a page of HTML.
It is meant to be used in conjunction with L<Web::Components> and
L<Web::ComposableRequest> as it's API assumes these are used

Templates are assumed to be encoded as C<utf8>

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<templates>

A lazily evaluated directory which defaults to F<templates> in the configuration
F<var> directory. This is where the templates are stored

The path to the template file is F<< templates/<skin>/<layout>.tt >>. The
C<skin> and C<layout> attributes default to the values of the configuration
object

=back

Requires the following attributes to be provided by the consuming class;

=over 3

=item C<config>

Requires the configuration attribute to provide the following attributes;

=over 3

=item C<layout>

The default template name if none is provided in the stash

=item C<skin>

The default skin if none is provided in the stash

=item C<tempdir>

Path to the directory where L<Template> will store the compiled templates

=item C<vardir>

Path to the directory where the templates are stored

=back

=back

=head1 Subroutines/Methods

=head2 C<render_template>

   $rendered_template = $self->render_template( $stash );

The C<$stash> hash reference may contain a C<config> attribute, otherwise the
invocant is expected to provide a C<config> object

The C<$stash> should contain either a C<template> attribute or C<skin> and
C<page> attributes. If a C<template> attribute is provided it should be a hash
reference containing C<skin> and C<layout> attributes. If the C<page> attribute
is provided it should be a hash reference that contains a C<layout> attribute

The layout attribute is either a path to the template or a scalar reference
that contains the template

=head1 Diagnostics

The compiled templates are stored in subdirectories below the configuration
temporary directory

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<Moo>

=item L<Template>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Role-TT.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
