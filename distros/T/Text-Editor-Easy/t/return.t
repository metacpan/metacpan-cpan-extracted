use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
    else {
        plan no_plan;
    }
}

use strict;

use lib '../lib';
use Text::Editor::Easy;

my $editor = Text::Editor::Easy->new;

is ( ref($editor), 'Text::Editor::Easy', 'Object type');

test_string ( $editor, "No return at end of test file" . "\n" x 16 . "end");

$editor->empty;

test_string ( $editor, "Returns at end of test file" . "\n" x 16);


sub test_string {
		my ( $editor, $text ) = @_;

		$editor->insert($text);
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

        is ( $saved, $text, 'Saving file' );
		
		use File::Copy;
		copy ( 'return_saved.txt', 'return_to_open.txt' );
		my $editor2 = Text::Editor::Easy->new({
            'file' => 'return_to_open.txt',
        });

		is ( $editor2->slurp, $text, 'Opening file');
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

        is ( $saved, $text, 'Second saving file' );
		is ( $editor3->slurp, $text, 'Opening file by bottom');
		
		$editor3->close;
}
