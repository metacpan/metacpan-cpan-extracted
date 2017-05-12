use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
}

use strict;

use lib '../lib';
use Text::Editor::Easy {
    #'trace' => {
    #    'all' => 'tmp/',
    #    'trace_print' => 'full',
    #}
};

my $editor = Text::Editor::Easy->new({
    #'sub' => 'main',
        #'trace' => {
        #    'all' => 'tmp/',
		#	'save_report' => 'keep',
        #},
});

#sub main {
#	my ( $editor ) = @_;
		
    use Test::More qw( no_plan );
	is ( ref($editor), 'Text::Editor::Easy', 'Object type');

    test_string ( $editor, "No return at end of test file" . "\n" x 16 . "end");
	$editor->empty;
	test_string ( $editor, "Returns at end of test file" . "\n" x 16);
	$editor->empty;
	test_string ( $editor, "\n");

	my $file_to_edit = "First line\n\nmiddle\n\nLast line";
	test_bloc_insertion( $file_to_edit );

    $file_to_edit = "First line\n\nmiddle\n\nPrevious of last line\n";
	test_bloc_insertion( $file_to_edit );
	
#    Text::Editor::Easy->exit(0);
#}


sub test_string {
		my ( $editor, $text ) = @_;

		$editor->insert_bloc($text);
		$editor->save('return_saved.txt');	
		if ( ! open ( FIL,  'return_saved.txt' ) ) {
		    is ( 1, 0, 'Save or re-open unsuccessful, skip other tests...' );
            Text::Editor::Easy->exit(0);
	    }
		is ( 1, 1, 'Text::Editor::Easy->save' );

		my $saved;
		my $number = read FIL, $saved, 100;
		if ( ! defined $number ) {
		    is ( 1, 0, 'Read unsuccessful, skip other tests...' );
            Text::Editor::Easy->exit(0);
	    }
        is ( 1, 1, 'Perl read' );

        is ( $saved, $text . "\n", 'Saving file' );
		
		use File::Copy;
		copy ( 'return_saved.txt', 'return_to_open.txt' );
		
		
		my $editor2 = Text::Editor::Easy->new({
            'file' => 'return_to_open.txt',
        });

		is ( $editor2->slurp, $text . "\n", 'Opening file');
		$editor2->close;
		
		my $editor3 = Text::Editor::Easy->new({
            'file' => 'return_to_open.txt',
        });
		
		$editor3->dump_file_manager;
		
		$editor3->key({ 'meta' => 'ctrl_', 'key' => 'End', 'meta_hash' => {} });
		
		$editor3->save('return_saved3.txt');	
		if ( ! open ( FIM,  'return_saved3.txt' ) ) {
		    is ( 1, 0, 'Second save or re-open unsuccessful, skip other tests...' );
            Text::Editor::Easy->exit(0);
	    }
		is ( 1, 1, 'Text::Editor::Easy->save' );

		$number = read FIM, $saved, 100;
		if ( ! defined $number ) {
		    is ( 1, 0, 'Second read unsuccessful, skip other tests...' );
            Text::Editor::Easy->exit(0);
	    }
        is ( 1, 1, 'Second perl read' );

        is ( $saved, $text . "\n", 'Second saving file' );
		is ( $editor3->slurp, $text . "\n", 'Opening file by bottom');
		
		$editor3->close;
}


sub test_bloc_insertion {
	my ( $initial_text ) = @_;
		
    open ( FIN, '>insert_bloc.txt' ) or die "Can't create 'insert_bloc.txt' : $!\n";
	print FIN $initial_text;
	close FIN;
	
	my $editor = Text::Editor::Easy->new({
		'file' => 'insert_bloc.txt',
    });
	
	my $text = "Added text, first line\nadded text...\nEnd of added text";
	
	# Insertion à la fin d'un fichier
	$editor->insert_bloc( $text, {
			'where' => $editor->last->ref,
			'how' => 'after'
		} );
	#$editor->save('insert_bloc_modified.txt');
	my $new_text = $initial_text . "\n" . $text;
    
    print STDERR "Avant bottom insertion, id = ", $editor->id, "\n";
    
	is ( $editor->slurp, $new_text, 'bottom insertion' );
	
	test_reverse( $editor, $new_text, 'bottom insertion' );
	
	# Insertion au début d'un fichier
	$editor->insert_bloc( $text, {
			'where' => $editor->first->ref,
			'how' => 'before'
		} );
	#$editor->save('insert_bloc_modified.txt');
	$new_text = $text . "\n" . $new_text;
	is ( $editor->slurp, $new_text, 'top insertion' );
	
	test_reverse( $editor, $new_text, 'top insertion' );
	
	# Insertion au milieu d'un fichier
	my @new_text = split ( /\n/, $new_text );
	my @temp = split ( /\n/, $text );
	my $line_number = scalar ( @temp ) + 2;
	my $ref = $editor->number($line_number)->ref;
	if ( ! $ref ) {
		is ( 1, 0, "Not enough lines created");
    }
	else {
		is ( 1, 1, "Enough lines created");
	    $editor->insert_bloc( $text, { 
				'where' => $editor->number($line_number)->ref,
				'how' => 'after'
			} );
    }
	#$editor->save('insert_bloc_modified.txt');

	splice @new_text, $line_number, 0, $text;
	$new_text = join ("\n", @new_text );
    is ( $editor->slurp, $new_text, 'middle insertion' );
	
	test_reverse( $editor, $new_text, 'middle insertion' );

	# Insertion dans un autre bloc...
	@new_text = split ( /\n/, $new_text );
	$line_number = 2;
	$editor->insert_bloc( $text, { 
			'where' => $editor->number($line_number)->ref,
			'how' => 'after'
		} );
	#$editor->save('insert_bloc_modified.txt');

	splice @new_text, $line_number, 0, $text;
	$new_text = join ("\n", @new_text );
    is ( $editor->slurp, $new_text , 'bloc insertion');
	
	test_reverse( $editor, $new_text, 'bloc insertion' );
}

sub test_reverse {
		# Lecture arrière
		my ( $editor, $text, $info ) = @_;
		
		my $line = $editor->last;
		my @text;
		while ( $line ) {
		    unshift @text, $line->text;
			$line = $line->previous;
	    }
		my $slurp = join ( "\n", @text );
		is ( $slurp, $text, "reverse read for $info" );
}
