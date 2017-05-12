package Text::Editor::Easy::Display;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Display - Object oriented interface to displays (managed by "Text::Editor::Easy::Abstract"). A display is a screen line. With
wrap mode, you can have several displays for a single line on a file.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

# Ce package n'est qu'une interface orientée objet à des fonctions de File_manager.pm rendues inaccessibles (ne se trouvent
# pas dans les hachages gérés par AUTOLOAD de Text::Editor::Easy) car susceptibles de changer

# Les fonctions de File_manager.pm réalisant toutes les méthodes de ce package commencent par "line_" puis reprennent
# le nom de la méthode

use Scalar::Util qw(refaddr weaken);

use Text::Editor::Easy::Comm;

# 2 attributs pour un objet "Line"
my %ref_Editor;    # Une ligne appartient à un éditeur unique
my %ref_id;        # A une ligne, correspond un identifiant

# Recherche d'un identifiant pour un éditeur donné
my %ref_line
  ; # Il y aura autant de hachage de références que de threads demandeurs de lignes

sub new {
    my ( $classe, $editor, $line_id ) = @_;

    return if ( !$line_id );
    
    # Attention, la clé du hachage %ref_line ne peut pas être un objet $editor => stringinfication implicite
    # Marche car l'adresse scalaire est unique et donc la chaîne générée est unique par éditeur
    my $line = $ref_line{$editor}{$line_id};
    if ($line) {
        return $line;
    }

    $line = bless \do { my $anonymous_scalar }, $classe;

    my $ref = refaddr $line;
    $ref_Editor{$ref}               = $editor;
    $ref_id{$ref}                   = $line_id;
    $ref_line{$editor}{$line_id}    = $line;
    weaken $ref_line{$editor}{$line_id};

    return $line;
}

sub next {
    my ($self) = @_;

    my $ref        = refaddr $self;
    my $ref_editor = $ref_Editor{$ref};
    my $next_id    = $ref_editor->display_next( $ref_id{$ref} );
    return Text::Editor::Easy::Display->new(
        $ref_editor
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $next_id,
    );
}

sub previous {
    my ($self) = @_;

    my $ref         = refaddr $self;
    my $ref_editor  = $ref_Editor{$ref};
    my $previous_id = $ref_editor->display_previous( $ref_id{$ref} );
    return Text::Editor::Easy::Display->new(
        $ref_editor
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $previous_id,
    );
}

sub next_in_file {
    my ($self) = @_;

    my $ref = refaddr $self;
    my ( $id, $num ) = split( /_/, $ref_id{$ref} );
    my $ref_editor = $ref_Editor{$ref};
    my ($next_id) = $ref_editor->next_line($id);
    return Text::Editor::Easy::Line->new(
        $ref_editor
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $next_id,
    );
}

sub previous_in_file {
    my ($self) = @_;

    my $ref = refaddr $self;
    my ($id) = split( /_/, $ref_id{$ref} );
    my $ref_editor = $ref_Editor{$ref};
    my ($previous_id) = $ref_editor->previous_line($id);

    return Text::Editor::Easy::Line->new(
        $ref_editor
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $previous_id,
    );
}

sub line {
    my ($self) = @_;

    my $ref = refaddr $self;
    my ( $id, $num ) = split( /_/, $ref_id{$ref} );
    my $ref_editor = $ref_Editor{$ref};

    return Text::Editor::Easy::Line->new(
        $ref_Editor{$ref}
        , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
        $id,
    );
}

sub ref {
    my ($self) = @_;

    return $ref_id{ refaddr $self };
}

sub DESTROY {
    my ($self) = @_;

    my $ref = refaddr $self;

    #print "Destructions de ", $ref_id{ $ref }, ", ", threads->tid, "\n";

    # A revoir : pas rigoureux
    return if ( !$ref );
    if ( defined $ref_Editor{$ref} ) {
        if ( defined $ref_line{ $ref_Editor{$ref} } ) {
            if ( defined $ref_line{ $ref_Editor{$ref} }{ $ref_id{$ref} } ) {
                delete $ref_line{ $ref_Editor{$ref} }{ $ref_id{$ref} };
            }
            delete $ref_line{ $ref_Editor{$ref} };
        }
        delete $ref_Editor{$ref};
    }
    delete $ref_id{$ref};
}

my %sub = (
    'text' => 1,
    'next_is_same' => 1,
    'previous_is_same' => 1,
    'ord'    => 1,
    'height' => 1,
    'middle_ord' => 1,
    'number' => 1,
    'abs'    => 1,
    'select' => 1,
);

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    $what =~ s/^Text::Editor::Easy::Display:://;

    if ( !$sub{$what} ) {
        print
"La méthode $what n'est pas connue de l'objet Text::Editor::Easy::Display\n";
        return;
    }

    my $ref        = refaddr $self;
    my $ref_editor = $ref_Editor{$ref};

    return $ref_editor->ask2( 'display_' . $what, $ref_id{$ref}, @param );
}

# Méthode de paquetage : compte le nombre d'objets "Line" en mémoire pour ce thread
sub count {
    my $total = 0;

    for my $edit ( keys %ref_line ) {
        $total += scalar( keys %{ $ref_line{$edit} } );
    }
    return $total;
}

=head1 FUNCTIONS

=head2 count

=head2 line

=head2 new

=head2 next

=head2 next_in_file

=head2 previous

=head2 previous_in_file

=head2 ref

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
