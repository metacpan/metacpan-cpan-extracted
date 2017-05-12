package Text::Editor::Easy::Program::Eval::Print;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Eval::Print - Redirection of prints coming from the macro panel of the "Editor.pl" program (insertion in a "Text::Editor::Easy" object).

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use threads;    # Pour debug

use Devel::Size qw(size total_size);

Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG );

# Length of the slash n on a file
my $length_s_n;

sub init_print_eval {
    my ( $self, $reference, $id ) = @_;

    print DBG "Dans init_print_eval de 0.1 : $self|$reference|$id|",
      threads->tid, "|\n";
    $self->[0] = Text::Editor::Easy->get_from_id( $id );
    
    print DBG "Editor_id = |$id|", $self->[0]->id, "|,... editor = ", $self->[0], "\n";

    #$self->[0]->insert("Fin de print eval\n");
    $self->[1] = $self->[0]->async;
    $length_s_n = Text::Editor::Easy->tell_length_slash_n;
}

sub print_eval {
    my ( $self, $seek_start, $data ) = @_;

    #return;
    print DBG "Dans print_eval : $self|$seek_start|$length_s_n|$data\n";
    print DBG "Editor_id = |", $self->[0]->id, "|,... editor = ", $self->[0], "\n";
    my @lines = $self->[0]->insert($data);

    print DBG "==================\nReçu les références suivantes :";
    for my $line ( @lines ) {
        print DBG "\nREF : ", $line->ref, "|" , $line->text;
    }
    print DBG "\n==================\n";

    my $seek_current = $seek_start;
    my $indice = 0;
    my @data = split ( /\n/, $data, -1 );
    print DBG "\tTaille du tableau \@data = ", scalar(@data), "\n";
    print DBG "\tLongueur de la chaîne \$data = ", length( $data ), "\n";
    my $total_length = length($data) + ($length_s_n - 1 )*( scalar(@data) - 1 );
    print DBG "\tTaille réelle trouvée = $total_length\n";
    for my $line ( @lines ) {
        
        # Le texte doit être celui contenu dans $data, pas celui de la ligne !
        my $text = $line->text;
        my $info = $line->get_info;
        if ( ! defined $info ) {
                $info = '';
        }
        else {
                $info .= ';';
        }
        print DBG "Avant |$text| info = $info\n";
        
        my $length;
        if ( $indice == 0 ) {
            $length = length ( $data[0] );
        }
        else {
            $length = length ( $text );
        }
        $indice += 1;
        #print DBG "Ligne |$text|\n\tseek_start 1 = ", $line->seek_start, "\n";
        #if ( length($text) != 0 ) {
        $line->set_info( "$info$seek_start,$seek_current,$total_length" );
        #print "tutu";
        $seek_current += $length + $length_s_n;
        print DBG "Ligne |$text| seek_start 2 = ", $line->get_info, "\n";
        #}
        
    }
    print DBG "Fin de print_eval $data\n";
}

sub idle_eval_print {
    return;
}

=head1 FUNCTIONS

=head2 idle_eval_print

=head2 init_print_eval

=head2 print_eval

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;