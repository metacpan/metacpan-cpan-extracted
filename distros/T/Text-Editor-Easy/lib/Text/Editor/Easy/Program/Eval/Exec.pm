package Text::Editor::Easy::Program::Eval::Exec;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Program::Eval::Exec - Execution of macro panel instructions in the "Editor.pl" program.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Text::Editor::Easy::Comm;
use threads;    # Pour debug
use Data::Dump qw(dump);

Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG );

sub exec_eval {
    my ( $self, $program ) = @_;

# Ajout d'une instruction "return if anything_for_me;" entre chaque ligne pour réactivité maximum

    #$program =~ s/;\n/;return if ( anything_for_me() );\n/g;
    print DBG "Dans exec_eval(", threads->tid, ") : \n$program\n\n";

    #print substr ( $program, 0, 150 ), "\n\n";
    my $call_id = Text::Editor::Easy->trace_eval ( $program, threads->tid, __FILE__, __PACKAGE__, __LINE__ + 1 );
    eval $program;
    my $message = $@;
    return if ( ! $message );
    my $line = __LINE__ - 3;
    print DBG "Le message $message va être envoyé à trace_print en un seul bloc pour analyse\n";
    my @calls;
    my $indice = 0;
    while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
        push @calls, [ $pack, $file, $line ];
    }
    my $array_dump = dump @calls;
    my $hash_dump  = dump(
        'who'   => threads->tid,
        'on'    => '$@',
        'calls' => $array_dump,
        #'time'  => scalar(gettimeofday),
        'line' => $line,
        'file' => __FILE__,
        'package' => __PACKAGE__,
        'call_id' => $call_id,
    );
    Text::Editor::Easy->whose_name('Eval')->at_top;
    Text::Editor::Easy->trace_print( $hash_dump, $message );
    #print STDERR $message;
}

sub idle_eval_exec {
    my ( $self, $eval_print ) = @_;

    if ( defined $eval_print ) {
        Text::Editor::Easy->empty_queue($eval_print);
    }
}

sub ed {
    my ( $name ) = @_;
    
    return Text::Editor::Easy->whose_name( $name );
}

=head1 FUNCTIONS

=head2 exec_eval

=head2 idle_eval_exec

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;