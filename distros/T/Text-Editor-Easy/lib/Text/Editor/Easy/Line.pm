package Text::Editor::Easy::Line;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Line - Object oriented interface to a file line (managed in the background by "Text::Editor::Easy::Abstract" 
and "Text::Editor::Easy::File_manager").

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 SYNOPSIS

    my $line = $editor->number(4);
    print "Initial text of line number 4 : ", $line->text, "\n";
    $line->set('This will be the new content');
    if ( ! $line->displayed ) {
        $line->display( {'at' => 'middle'} );
    }
    $line->select;
    

If we except the print, you could have done the same thing writing this horrible line :

    $editor->number(4)->set('This will be the new content')->select({'force' => 'middle'});

=head1 WARNING

"Editor" object will stand for "Text::Editor::Easy" object and "line" object will stand for "Text::Editor::Easy::Line" object.

Some of the methods of the "editor" object need a "line" object as parameter or return "line" object(s).
You should never call yourself the "new" method of the "line" package to create "line" objects.
First, you use an "editor" method that returns "line" object(s), and you provide the second "editor" method that need a "line" object with what you
have received from the first call.

Note that 'line' instances are scalar references : you can't do anything with them except calling methods of the interface.
Each 'line' knows which 'editor' it belongs to.

=head1 METHODS

=head2 bottom_ord

This method does not accept any parameter.

It returns undef if the line is not displayed. When displayed, it returns the ordinate of the bottom of the line. See also L</top_ord>. The ordinate
is the pixel number from the top with a graphical user interface but will be the line number in console mode.

=head2 display

    $line->display( { 'at' => 32, 'from' => 'bottom', 'no_check' => 1 } );
    print "Bottom ordinate of line $line is : ", $line->bottom_ord, "\n"; # Should return 32...

This method accepts only one optional parameter which is a hash reference. The options that this hash may contain are described 
in L<'editor display method'|Text::Editor::Easy/DISPLAY> as the second parameter.

To display an editor, you have to take a reference which is a line of this editor. When you call display method with a line instance, this
reference is contained in the caller. When you call display method with an editor instance, you have to set the line in a mandatory parameter.

=head2 displayed

This method does not accept any parameter.

In list context, it returns 'display' instances (that is L<Text::Editor::Easy::Display> object(s)) or an empty list if the line is not visible.
If wrap mode is not used, there can't be more than one 'display' instance associated to one 'line' instance. With wrap mode, it depends
on the line size and on the screen width.

Called in scalar context, you just get the number of 'display' instances associated with that line : 0 if the 'line' is not visible, 1 or more if the
line is visible.

Note that if wrap mode is used and the 'line' is partially visible (some 'displays' are visible, other are not) the result you get
is identical as if the line was entirely visible. Lines are always displayed as a whole.

=head2 next

This method does not accept any parameter.

Returns the next 'line' instance or undef if it's the last.

    # A very slow slurp implementation (at present, 'editor' slurp method is written like that !)
    my $line   = $editor->first; # shortcut for $editor->number(1)
    my $slurp = $line->text;
    $line = $line->next;
    while ( $line ) {
        $slurp .= "\n" . $line->text;
        $line = $line->next;
    }

=head2 number

This method does not accept any parameter.

Returns the order of the line (it's number). Note that for a given 'line' instance, this number will change according to updates ('line' creations or
suppressions).

=head2 previous

This method does not accept any parameter.

Returns the previous 'line' instance or undef if it's the first.

=head2 select

The interface of this method will change. At present, it's not possible to select lines that are not visible unless you force them to be visible.

=head2 set

This method accepts one parameter : a string that will update the 'line' content.

It returns the 'line' instance that was used to call the set.

=head2 text

This method does not accept any parameter.

It returns the text of the line.

=head2 top_ord

This method does not accept any parameter.

It returns undef if the line is not displayed. When displayed, it returns the ordinate of the top of the line. See also L</bottom_ord>.

=cut

use Scalar::Util qw(refaddr weaken);
use Devel::Size qw(size total_size);

use Text::Editor::Easy::Comm;
use Text::Editor::Easy::Display;

# 2 attributs pour un objet "Line"
my %ref_Editor;    # Une ligne appartient à un éditeur unique
my %ref_id;        # A une ligne, correspond un identifiant

# Recherche d'un identifiant pour un éditeur donné
my %ref_line
  ; # Il y aura autant de hachage de références que de threads demandeurs de lignes

# Remarque : les hachages précédents ne sont pas 'shared' : il y en a autant que de threads

sub new {
    my ( $classe, $editor, $ref_id ) = @_;

    return if ( !$ref_id );

    my $ref_Editor = $editor->id;
    my $line       = $ref_line{$ref_Editor}{$ref_id};
    if ($line) {
        return $line;
    }
    $line = bless \do { my $anonymous_scalar }, $classe;

    my $ref = refaddr $line;

    #print "REf EDITOR de $ref = $editor\n";
    $ref_Editor{$ref}               = $editor;
    $ref_id{$ref}                   = $ref_id;
    $ref_line{$ref_Editor}{$ref_id} = $line;
    weaken $ref_line{$ref_Editor}{$ref_id};

    return $line;
}

sub editor {
    my ($self) = @_;

    my $ref       = refaddr $self;
    return $ref_Editor{$ref};
}


sub next {
    my ($self) = @_;

    my $ref       = refaddr $self;
    my $editor    = $ref_Editor{$ref};
    my ($next_id) = $editor->next_line( $ref_id{$ref} );
    return Text::Editor::Easy::Line->new(
        $editor,
        $next_id,
    );
}

sub previous {
    my ($self) = @_;

    my $ref           = refaddr $self;
    my $editor        = $ref_Editor{$ref};
    my ($previous_id) = $editor->previous_line( $ref_id{$ref} );
    return Text::Editor::Easy::Line->new(
        $editor,
        $previous_id,
    );
}

sub number {
    my ($self) = @_;

    my $ref           = refaddr $self;
    my $editor        = $ref_Editor{$ref};
    return $editor->get_line_number_from_ref( $ref_id{$ref} );
}

sub set {
    my ( $self, @param ) = @_;

    my $ref           = refaddr $self;
    my $editor        = $ref_Editor{$ref};
    my $id = $editor->line_set( $ref_id{$ref}, @param );
    #print "Dans line_set reçu id $id de line_set\n";
    return Text::Editor::Easy::Line->new(
        $editor,
        $id,
   );
}

sub seek_start {
    my ($self) = @_;

    my $ref    = refaddr $self;
    my $editor = $ref_Editor{$ref};
    return $editor->line_seek_start( $ref_id{$ref} );
}

sub ref {
    my ($self) = @_;

    return $ref_id{ refaddr $self };
}

sub id {
    my ($self) = @_;

    return $ref_id{ refaddr $self };
}

sub DESTROY {
    my ($self) = @_;

    my $ref = refaddr $self;
    if ( defined $ref ) {
        if ( defined $ref_id{$ref} ) {
            if ( defined $ref_Editor{$ref} ) {
                delete $ref_line{ $ref_Editor{$ref} }{ $ref_id{$ref} };
            }
            delete $ref_id{$ref};
        }
        if ( defined $ref_Editor{$ref} ) {
            delete $ref_Editor{$ref};
        }
    }
}

sub displayed {
    my ( $self, @param ) = @_;

    my $ref        = refaddr $self;
    my $ref_editor = $ref_Editor{$ref};

    #print "ref_editor = $ref_editor, $ref\n";
    my @ref = $ref_editor->line_displayed( $ref_id{$ref} );

    if (wantarray) {
        # Création des "lignes d'écran"
        my @display;
        for (@ref) {
            push @display, Text::Editor::Easy::Display->new(
                $ref_editor
                , # Cette référence n'est renseignée que pour l'objet editeur du thread principal (tid == 0)
                $_,
            );
        }
        return @display;
    }
    else {
        return scalar @ref;
    }
}

sub display {
    my ( $self, @param ) = @_;

    my $ref        = refaddr $self;
    my $editor = $ref_Editor{$ref};

    $editor->ask2( 'display', $ref_id{$ref}, @param );
}


my %sub = (
    'select' => 1,
    'deselect' => 1,
    'top_ord' => 1,
    'bottom_ord' => 1,
    'set' => 1,
    'add_seek_start' => 1,
    'get_info' => 1,
    'set_info' => 1,
    'text' => 1,
);


sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    $what =~ s/^Text::Editor::Easy::Line:://;

    if ( !$sub{$what} ) {
        print STDERR
"La méthode $what n'est pas connue de l'objet Text::Editor::Easy::Line\n";
        return;
    }

    my $ref        = refaddr $self;
    my $ref_editor = $ref_Editor{$ref};

    return $ref_editor->ask2( 'line_' . $what, $ref_id{$ref}, @param );
}

# Méthode de paquetage : compte le nombre d'objets "Line" en mémoire pour ce thread
sub count {
    my $total = 0;

    for my $edit ( keys %ref_line ) {
        $total += scalar( keys %{ $ref_line{$edit} } );
    }
    return $total;
}

sub linesize {
    print "TAILLE ref_Editor : ", total_size( \%ref_Editor ), "\n";
    print "TAILLE ref_id     : ", total_size( \%ref_id ),     "\n";
    print "TAILLE ref_line   : ", total_size( \%ref_line ),   "\n";
}


=head1 OTHER METHODS

These methods shouldn't be used.

=head2 count (class method)

Number of "line" objects created for the thread, for all "editor" objects defined. As threre are more threads, there can be other
"line" objects declared in other threads (and, why not, pointing at same the lines).

=head2 linesize (class method)

For debugging memory leaks which are numerous...

=head2 new

=head2 ref

This is the only common value (it's an auto-incrementing integer chosen by 'File_manager' thread) between all threads : for a given 'editor' instance,
if 2 lines (belonging to the same editor) have the same 'ref' in 2 different threads, they are pointing at the same line. But of course, as each thread
has its own memory, scalar references and, then, line instances are different.

=head2 editor

Returns the 'editor' instance the line belongs to. Should be useless (?).

=head2 seek_start

Give the start position of the line in the file, 0 if there's no file associated. This position is true only at the beginning or just after a save. Positions
are not updated at each change.

=head2 set_info

To save data in association to a particular line. This data is saved in the 'File_manager' thread, so it can be seen and shared by all threads thanks to
'get_info' method.

=head2 get_info

Retrieve 'info' associated to the 'line' object thanks to 'set_info' method.

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;



