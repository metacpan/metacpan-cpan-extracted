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

is ( ref($editor), "Text::Editor::Easy", "Object type");

my $text = "0123456789AZERTYUIOP";
my $cursor = $editor->cursor;    
my $first_line = $editor->first;

# First insertion
my $last_insert = $editor->insert( $text );
is ( $first_line->text, $text, 'Text of first line, first insertion');
is ( $last_insert, $first_line, 'Line instance scalar context, first insertion');
is ( scalar($cursor->get), length($text), 'Cursor position, first insertion');

# Second insertion, 'pos' option
my $added_text = 'AZER';
$text = $added_text . $text;
$last_insert = $editor->insert( $added_text, { 'pos' => 0 } );

is ( $first_line->text, $text, 'Text of first line, insertion 2');
is ( $last_insert, $first_line, 'Line instance scalar context, insertion 2');
is ( scalar($cursor->get) , length($text), 'Cursor position, insertion 2');

# Third insertion, 'replace' and 'cursor' eq 'at_end' option, list context for single line insertion
my $replacement_text = 'TYUI';
$text = $replacement_text . substr( $text, length($replacement_text) );
( $last_insert ) = $editor->insert( $replacement_text, { 
	'pos' => 0,
	'cursor' => 'at_end',
	'replace' => 1,
} );
is ( $first_line->text, $text, 'Text of first line, insertion 3');
is ( $last_insert, $first_line, 'Line instance list context, insertion 3');
my $pos = $cursor->get;
is ( $pos , length($replacement_text), 'Cursor position, insertion 3');	

# 'replace' and 'cursor' eq 'at_start' option
$replacement_text = 'azer';
$text = substr( $text, 0, $pos ) . $replacement_text . substr( $text, $pos + length( $replacement_text ) );
$last_insert = $editor->insert( $replacement_text, { 
	'cursor' => 'at_start',
	'replace' => 1,
} );
is ( $first_line->text, $text, 'Text of first line, insertion 4');
is ( scalar($cursor->get) , $pos, 'Cursor position, insertion 4');	

# 'cursor' with line instance, implicit pos at end
$added_text = "uiop\n0123456789";
my ( $added_first, $text_of_last ) = split(/\n/, $added_text);
$text .= $added_first;
$last_insert = $editor->insert( $added_text, {
    'line' => $first_line,
	'cursor' => [ $first_line ],
} );
is ( $first_line->text, $text, 'Text of first line, insertion 5');
is ( scalar($cursor->get) , length($text), 'Cursor position, insertion 5');
is ( $cursor->line , $first_line, 'Cursor line, insertion 5');

#
$added_text = "azertyuiop\n";
$last_insert = $editor->insert( $added_text, {
    'line' => $editor->last,
	'pos' => 0,
	'cursor' => [ 'line_1', 0 ],
} );
my $last_line = $editor->last;
is ( $last_line->text, $text_of_last, 'Text of last line, insertion 6');
is ( scalar($cursor->get) , 0, 'Cursor position, insertion 6');
is ( $cursor->line , $last_line, 'Cursor line, insertion 6');

#
$added_text = "a";
$last_insert = $editor->insert( $added_text, {
	'display' => [ $first_line, { 'at' => 1, 'from' => 'top'} ],
} );
is ( $first_line->top_ord, 1, 'Ordinate of first line, insertion 7');

#
$added_text = "a\nb";
( undef, $last_insert ) = $editor->insert( $added_text, {
	'display' => [ 'line_1', { 'at' => 1, 'from' => 'bottom'} ],
} );
is ( $last_insert->bottom_ord, 1, 'Ordinate of inserted line, insertion 8');

$editor = Text::Editor::Easy->new( {
    #'sub' => 'main',
    'width' => 500,
    'height' => 400,
} );

$text = "0123456789\nAZERTYUIOP";
$editor->insert( $text,
    { 'line' => $editor->first }
);

my $displayed_text = $editor->visual_slurp;
is ( $displayed_text, $text, "Abstract visual insert");
