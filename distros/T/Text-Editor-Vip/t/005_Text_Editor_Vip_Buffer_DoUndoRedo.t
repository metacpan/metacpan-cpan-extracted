# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 10;

BEGIN { use_ok( 'Text::Editor::Vip::Buffer' ); }


my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert("line1\nline2\nline3") ;
my $text_0 = $buffer->GetText() ;

$buffer->Insert("\nline4\n") ;
my $text_1 = $buffer->GetText() ;

$buffer->SetSelectionBoundaries(1, 1, 1, 3) ;
my $text_2 = $buffer->GetText() ;

$buffer->Delete(1) ;
my $text_3 = $buffer->GetText() ;

#~ diag DumpTree($buffer->{DO_STACK}, 'Do stack:') ;

$buffer->Undo(1) ;
is($buffer->CompareText($text_2), '', 'first Undo') ;

$buffer->Undo(1) ; # temporary so we can see a redo stack with to redo
is($buffer->CompareText($text_1), '', 'second Undo') ;

$buffer->Undo(1) ; # temporary so we can see a redo stack with to redo
is($buffer->CompareText($text_0), '', 'second Undo') ;

$buffer->Redo(2) ;
is($buffer->CompareText($text_2), '', 'Redo 2 steps') ;

$buffer->Redo(1) ;
is($buffer->CompareText($text_3), '', 'Redo 1 step') ;

$buffer->Undo(1) ;
is($buffer->CompareText($text_2), '', 'first Undo again') ;

$buffer->Undo(1) ;
is($buffer->CompareText($text_1), '', 'second Undo') ;

$buffer->Undo(1) ;
is($buffer->CompareText($text_0), '', 'second Undo') ;

$buffer->Redo(3) ;
is($buffer->CompareText($text_3), '', 'Redo all') ;

