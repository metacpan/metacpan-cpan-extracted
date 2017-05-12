# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use strict ;

use Data::Hexdumper ;

use Test::More tests => 4 ;

use Text::Editor::Vip::Buffer ;

my $buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

# no selection
my $redefined_sub_output = '' ;
my $expected_output = 'Redefined PrintError is working' ;
$buffer->ExpandWith('PrintError', sub {$redefined_sub_output = $_[1]}) ;

$buffer->MakeSelectionUpperCase() ;
is($redefined_sub_output, "Please select text for upper case operation.\n", 'No selection error message') ;

#upper case
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

$buffer->Insert("this is upper case") ;
$buffer->GetSelection()->Set(0, 8, 0, 13) ;

$buffer->MakeSelectionUpperCase() ;
is($buffer->GetText(), 'this is UPPER case', 'Upper casing selection') ;

# lower case
$buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

$buffer->Insert("this is LOWER case") ;
$buffer->GetSelection()->Set(0, 8, 0, 13) ;

$buffer->MakeSelectionLowerCase() ;
is($buffer->GetText(), 'this is lower case', 'lower casing selection') ;

#Multiline upper case

$buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Case') ;

my $text = "THIS is LOWER case\nthis is LOWER case\nthis is LOWER case\nAnotherline" ;
my $expected_text = "THIS is lower case\nthis is lower case\nthis is lower case\nAnotherline" ;

$buffer->Insert($text) ;
$buffer->GetSelection()->Set(0, 8, 2, 13) ;
$buffer->MakeSelectionLowerCase() ;
is($buffer->GetText(), $expected_text, 'lower casing selection') ;

