package Text::Editor::Easy::Cursor;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Cursor - Object oriented interface to cursor data (managed by "Text::Editor::Easy::Abstract")

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

# Les fonctions de Abstract.pm réalisant toutes les méthodes de ce package commencent par "cursor_" puis reprennent
# le nom de la méthode

use Scalar::Util qw(refaddr);

use Text::Editor::Easy::Comm;
use Text::Editor::Easy::Line;

my %ref_Editor;    # Récupération des queue de comm (par ref + type)

sub new {
    my ( $classe, $ref_editor ) = @_;

    my $cursor = bless \do { my $anonymous_scalar }, $classe;

    my $ref = refaddr $cursor;
    $ref_Editor{$ref} = $ref_editor;

    return $cursor;
}

sub set {
    my ( $self, $position, $line1, $line2 ) = @_;

    #print "Dans cursor set : $position, $line1, $line2\n";
    my $line;
    if ( defined $line1 ) {
        if (   ref $line1 eq 'Text::Editor::Easy::Line'
            or ref $line1 eq 'Text::Editor::Easy::Display' )
        {
            $line = $line1->ref;
        }
        elsif (
            defined $line2
            and (  ref $line2 eq 'Text::Editor::Easy::Line'
                or ref $line2 eq 'Text::Editor::Easy::Display' )
          )
        {
            $line = $line2->ref;
        }
    }

# Ecrasement des valeurs objet "line" et display" éventuelles de l'éventuel hachage $position
    if ( ref $position eq 'HASH' ) {
        if ( $position->{'line'} ) {
            $position->{'line'} = $position->{'line'}->ref;
        }
        if ( $position->{'display'} ) {
            $position->{'display'} = $position->{'display'}->ref;
        }
    }
    my $ref = refaddr $self;
    $ref_Editor{$ref}->cursor_set( $position, $line );
	if ( ! wantarray ) {
        return $ref_Editor{$ref}->cursor_set( $position, $line );
    }
    my ( $ref_line, $line_pos, $ref_display, $display_pos, $abs, $virtual_abs, $text_position, $ord ) =
		    $ref_Editor{$ref}->cursor_get( $position, $line );
	$line = Text::Editor::Easy::Line->new(
            $ref_Editor{$ref},
            $ref_line,
	    );
	my $display = Text::Editor::Easy::Display->new(
            $ref_Editor{$ref},
            $ref_display,
	    );
	return ( $line, $line_pos, $display, $display_pos, $abs, $virtual_abs, $text_position, $ord );
}

sub get {
    my ( $self ) = @_;

    my $ref = refaddr $self;
	if ( ! wantarray ) {
        return $ref_Editor{$ref}->cursor_get();
    }
    my ( $ref_line, $line_pos, $ref_display, $display_pos, $abs, $virtual_abs, $text_position, $ord ) =
		    $ref_Editor{$ref}->cursor_get();
	my $line = Text::Editor::Easy::Line->new(
            $ref_Editor{$ref},
            $ref_line,
	    );
	my $display = Text::Editor::Easy::Display->new(
            $ref_Editor{$ref},
            $ref_display,
	    );
	return ( $line, $line_pos, $display, $display_pos, $abs, $virtual_abs, $text_position, $ord );
}

my %method = (
    'position_in_display' => 1,
    'position_in_text'    => 1,
    'abs'                 => 1,
    'virtual_abs'         => 1,
    'line'                => 1,
    'get'                 => 1,
    'make_visible'        => 1,
    'set_shape'           => 1,
);

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    $what =~ s/^Text::Editor::Easy::Cursor:://;

    if ( !$method{$what} ) {
        warn
"La méthode '$what' n'est pas connue de l'objet Text::Editor::Easy::Cursor $self\n";
        return;
    }


    my $ref = refaddr $self;
    return $ref_Editor{$ref}->ask2( 'cursor_' . $what, @param );
}

sub line {
    my ($self) = @_;

    my $ref = refaddr $self;
    my $id  = $ref_Editor{$ref}->cursor_line();
    return Text::Editor::Easy::Line->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

sub display {
    my ($self) = @_;

    my $ref = refaddr $self;
    my $id  = $ref_Editor{$ref}->cursor_display();

    return Text::Editor::Easy::Display->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

=head1 FUNCTIONS

=head2 display

=head2 get

Gives the line object and position in this line of the current cursor position.

=head2 line

=head2 new

=head2 set

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;

