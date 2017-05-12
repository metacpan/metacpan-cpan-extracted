package Text::Editor::Easy::Screen;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Screen - Object oriented interface to screen data (managed by "Text::Editor::Easy::Abstract").

This module shoud disappear. Screen will be separated into "Window" and "Zone".

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

# Les fonctions de Abstract.pm réalisant toutes les méthodes de ce package commencent par "screen_" puis reprennent
# le nom de la méthode
use Text::Editor::Easy::Line;
use Scalar::Util qw(refaddr);

use Text::Editor::Easy::Comm;

use threads;
use threads::shared;

my %ref_Editor;    # Récupération des queue de comm (par ref + type)

sub new {
    my ( $classe, $ref_editor ) = @_;

    my $screen = bless \do { my $anonymous_scalar }, $classe;

    my $ref = refaddr $screen;
    $ref_Editor{$ref} = $ref_editor;

    return $screen;
}

sub first {
    my ($self) = @_;

    my $ref = refaddr $self;
    my $id  = $ref_Editor{$ref}->screen_first;
    return Text::Editor::Easy::Display->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

sub last {
    my ($self) = @_;

    my $ref = refaddr $self;
    my $id  = $ref_Editor{$ref}->screen_last;
    return Text::Editor::Easy::Display->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

sub number {
    my ( $self, $number ) = @_;

    my $ref = refaddr $self;
    my $id  = $ref_Editor{$ref}->screen_number($number);
    return $id if ( $id !~ /_/ );
    return Text::Editor::Easy::Display->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

my %method = (

    # Les 2 méthodes suivantes doivent être virées (liées à un objet texte)
    'font_height' => \&Text::Editor::Easy::Abstract::screen_font_height,
    'line_height' => \&Text::Editor::Easy::Abstract::screen_line_height,

    'height'       => \&Text::Editor::Easy::Abstract::screen_height,
    'y_offset'     => \&Text::Editor::Easy::Abstract::screen_y_offset,
    'x_offset'     => \&Text::Editor::Easy::Abstract::screen_x_offset,
    'margin'       => \&Text::Editor::Easy::Abstract::screen_margin,
    'width'        => \&Text::Editor::Easy::Abstract::screen_width,
    'set_width'    => \&Text::Editor::Easy::Abstract::screen_set_width,
    'set_height'   => \&Text::Editor::Easy::Abstract::screen_set_height,
    'set_x_corner' => \&Text::Editor::Easy::Abstract::screen_set_x_corner,
    'set_y_corner' => \&Text::Editor::Easy::Abstract::screen_set_y_corner,
    'move'         => \&Text::Editor::Easy::Abstract::screen_move,
    'wrap'         => \&Text::Editor::Easy::Abstract::screen_wrap,
    'set_wrap'     => \&Text::Editor::Easy::Abstract::screen_set_wrap,
    'unset_wrap'   => \&Text::Editor::Easy::Abstract::screen_unset_wrap,
    'check_borders'   => \&Text::Editor::Easy::Abstract::screen_check_borders,

    # Autres méthodes à développer
    # set_geometry        avec hachage de correspondance
    # get_geometry       ( hachage de correspondance )
    # get_title
    # set_title
);

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    $what =~ s/^Text::Editor::Easy::Screen:://;

    if ( !$method{$what} ) {
        print
"La méthode $what n'est pas connue de l'objet Text::Editor::Easy::Screen\n";
        return;
    }

    return $ref_Editor{ refaddr $self }->ask2( 'screen_' . $what, @param );
}

=head1 FUNCTIONS

=head2 first

=head2 last

=head2 new

=head2 number

=cut

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

