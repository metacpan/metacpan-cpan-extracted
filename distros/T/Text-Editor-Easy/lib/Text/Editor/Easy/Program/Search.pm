package Text::Editor::Easy::Program::Search;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Search - Bad named module (initially searching text) : used to answer to
user modification in the Eval tab of the Editor.pl program.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Text::Editor::Easy::Comm;

my $out;
my $eval_thread;
my $eval_print;

sub init_eval {
    my ( $self, $reference, $id ) = @_;
    
    print "Dans init_eval de Search.pm .. $self, $id\n";
    
    $out = Text::Editor::Easy->get_from_id( $id );

    #$out->insert('Bonjour');
    #$self, $package, $tab_methods_ref, $self_server
    my $eval_thread = Text::Editor::Easy->create_new_server(
        {
            'use'     => "Text::Editor::Easy::Program::Eval::Exec",
            'package' => "Text::Editor::Easy::Program::Eval::Exec",
            'methods' => [ 'exec_eval', 'idle_eval_exec' ],
            'object'  => []
        }
    );

    print "EVAL _TJREAD = $eval_thread\n";
    #print "Appel idle_eval_exec en asynchrone...\n";
    #Text::Editor::Easy::Async->idle_eval_exec("toto");
    #print "Appel exec_eval en synchrone ...\n";
    #Text::Editor::Easy->exec_eval('Bonjour');

    $eval_print = Text::Editor::Easy->create_new_server(
        {
            'use'     => "Text::Editor::Easy::Program::Eval::Print",
            'package' => "Text::Editor::Easy::Program::Eval::Print",
            'methods' => [ 'print_eval', 'idle_eval_print' ],
            'object'  => [],
            'init'    => [
                'Text::Editor::Easy::Program::Eval::Print::init_print_eval',
                $id
            ],
        }
    );
    #print "FIN DE INIT EVAL = $eval_thread\n";

    # Référencer dans Data le thread $eval_thread en arborescence...
    my $redirect_id = Text::Editor::Easy->reference_print_redirection(
        {
            'thread'  => $eval_thread,
            'type'    => 'tree',
            'method'  => 'print_eval',
            'exclude' => $eval_print,
        }
    );
}

sub modify_pattern {
    my ( $editor ) = @_;

    #print "Dans modify_pattern de Search.pm\n";

    #return;
    Text::Editor::Easy::Async->idle_eval_exec($eval_print);
    return if ( anything_for_me() );
    my $line = $editor->first;
    return if ( !$line );
    my $program = $line->text;
    return if ( anything_for_me() );
    while ( $line = $line->next ) {
        $program .= "\n" . $line->text;
        return if ( anything_for_me() );
    }
    return if ( anything_for_me() );
    my @array;

# Avant de faire le ménage il faut :
# ----------------------------------
# 1 - être sûr que le thread 10 ne tourne plus et ne génère pas de nouveaux print pour eval_print
    Text::Editor::Easy->idle_eval_exec($eval_print);
    return if ( anything_for_me() );

# 2 - être sûr qu'il ne reste plus aucun print asynchrones à afficher (on vide tout ceux qui sont en attente)
    Text::Editor::Easy->empty_queue($eval_print)
      ;    # Attention, ne faire des empty_queue que sur des threads ne faisant
           # pas l'objet de requêtes synchrones (sinon threads bloqués)
    return if ( anything_for_me() );

   # 3 - être sur que eval_print n'est pas en train d'éditer à nouveau une ligne
    Text::Editor::Easy->idle_eval_print;
    return if ( anything_for_me() );

    $out->empty;
    return if ( anything_for_me() );

    #$out->async->at_top;
    $out->async->make_visible;
    Text::Editor::Easy::Async->exec_eval($program);
    return;
}

sub insert_out {
    my ( $self, $sentence ) = @_;

    $out->insert($sentence);
}

sub print_b {
    my ($self) = @_;

    print " Dans print_b\n";
    $self->insert('b');
}

sub print_toto {
    my ($self) = @_;

    print " Dans print_toto\n";
    $self->insert('toto');
}

sub search {
    my ( $ind, $exp ) = @_;

    print "IND $ind, EXP $exp\n";
    my @search = Text::Editor::Easy->list_in_zone('zone1');
    my $search = Text::Editor::Easy->get_from_id( $search[$ind] );

    # Recherche dans l'écran
    return if ( anything_for_me() );
    $search->deselect;
    return if ( anything_for_me() );
    my $start = $search->screen->first->line;
    return if ( anything_for_me() );
    my $stop = $search->screen->last->line;
    return if ( anything_for_me() );
    my $next = $stop->next;
    $stop = $next if ( defined $next );
    my $pos_start = 0;
    my $line      = $start;
  MATCH: while (1) {
        print "line start : ", $line->text, "\n";
        last MATCH if ( !defined $line );
        return     if ( anything_for_me() );
        my ( $found, $start_pos, $end_pos ) = $search->regexp(
            $exp,
            {
                'line_start' => $line,
                'pos_start'  => $pos_start,
                'line_stop'  => $stop,
            }
        );
        return     if ( anything_for_me() );
        last MATCH if ( !defined $found );

        #print "FOUND $found\n";

        my ($dis) = $found->displayed;
        return     if ( anything_for_me() );
        last MATCH if ( !defined $dis );       # Normalement pas possible...
        $dis->select( $start_pos, $end_pos );
        return if ( anything_for_me() );
        $line      = $found;
        $pos_start = $end_pos;
    }

  # Recherche dans le reste du fichier sans surlignage (pour gagner du temps...)
    my ( $found, $start_pos, $end_pos ) = $search->regexp(
        $exp,
        {
            'line_start' => $stop,
            'pos_start'  => 0,
            'line_stop'  => $start,
        }
    );
    return if ( anything_for_me() );
    if ($found) {
        print "Trouvé : ", $found->text, "\n";
    }
}

=head1 FUNCTIONS

=head2 init_eval

=head2 insert_out

=head2 modify_pattern

=head2 print_b

=head2 print_toto

=head2 search

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
