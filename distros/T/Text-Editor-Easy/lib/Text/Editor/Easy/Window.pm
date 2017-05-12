package Text::Editor::Easy::Window;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Window - Object oriented interface to window data (managed by "Text::Editor::Easy::Abstract").
This module will replace "common parts" of the old "Screen.pm".

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

# Les fonctions de Abstract.pm réalisant toutes les méthodes de ce package commencent par "window_" puis reprennent
# le nom de la méthode
use Scalar::Util qw(refaddr);

use Text::Editor::Easy::Comm;

use threads;
use threads::shared;

my %ref_Editor;    # Récupération des queue de comm (par ref + type)

sub new {
    my ( $classe, $ref_editor ) = @_;

    my $window = bless \do { my $anonymous_scalar }, $classe;

    my $ref = refaddr $window;
    $ref_Editor{$ref} = $ref_editor;

    return $window;
}

my %method = (
    'set'          => \&Text::Editor::Easy::Abstract::window_set,
    'get'          => \&Text::Editor::Easy::Abstract::window_set,

    # Autres méthodes à développer
#    'height'       => \&Text::Editor::Easy::Abstract::window_height,
#    'y_offset'     => \&Text::Editor::Easy::Abstract::window_y_offset,
#    'x_offset'     => \&Text::Editor::Easy::Abstract::window_x_offset,
#    'width'        => \&Text::Editor::Easy::Abstract::window_width,
#    'set_width'    => \&Text::Editor::Easy::Abstract::window_set_width,
#    'set_height'   => \&Text::Editor::Easy::Abstract::window_set_height,
#    'set_x_corner' => \&Text::Editor::Easy::Abstract::window_set_x_corner,
#    'set_y_corner' => \&Text::Editor::Easy::Abstract::window_set_y_corner,
#    'move'         => \&Text::Editor::Easy::Abstract::window_move,
);

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    $what =~ s/^Text::Editor::Easy::Window:://;

    if ( !$method{$what} ) {
        print
"Method $what is unknown from object ", __PACKAGE__ , "\n";
        return;
    }

    return $ref_Editor{ refaddr $self }->ask2( 'window_' . $what, @param );
}

=head1 FUNCTIONS

=head2 new

=cut

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

