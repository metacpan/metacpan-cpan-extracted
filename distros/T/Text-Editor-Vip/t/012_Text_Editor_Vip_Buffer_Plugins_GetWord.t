# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use strict ;

use Data::Hexdumper ;

use Test::More tests => 26 ;

use Text::Editor::Vip::Buffer ;

# GetFirstWord
my $buffer = Text::Editor::Vip::Buffer->new();
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::GetWord') ;

is_deeply([$buffer->GetFirstWord()], [undef, undef], 'GetFirstWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
is_deeply([$buffer->GetFirstWord()] , ['word1', 1], 'GetFirstWord') ;

$buffer->Reset() ;
$buffer->Insert(' *שש$*ש*] word1 word_2 3 word4') ;
is_deeply([$buffer->GetFirstWord()] , ['word1', 10] , 'GetFirstWord preceded with garbage') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->SetModificationCharacter(50) ;
is_deeply([$buffer->GetFirstWord()] , ['word1', 1], 'GetFirstWord with current character outside the text') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->GetSelection()->Set(0, 3, 0, 7) ;
is_deeply([$buffer->GetFirstWord()] , ['word1', 1], 'GetFirstWord with selection') ;

# GetPreviousWord
$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
is_deeply([$buffer->GetPreviousWord()] , ['word4', 16], 'GetPreviousWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4 ') ;
is_deeply([$buffer->GetPreviousWord()] , ['word4', 16], 'GetPreviousWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
is_deeply([$buffer->GetPreviousWord()] , ['word4', 16], 'GetPrevioustWord preceded with garbage') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
$buffer->SetModificationCharacter(0) ;
is_deeply([$buffer->GetPreviousWord()] , [undef, undef], 'GetPrevioustWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4 *$**') ;
$buffer->SetModificationCharacter(50) ;
is_deeply([$buffer->GetPreviousWord()] , ['word4', 16], 'GetPreviousWord with current character outside the text') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->GetSelection()->Set(0, 3, 0, 7) ;
is_deeply([$buffer->GetPreviousWord()] , ['word4', 16], 'GetPreviousWordwith selection') ;

# GetCurrentWord
$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->SetModificationCharacter(1) ;
is($buffer->GetCurrentWord() , 'word1', 'GetCurrentWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->SetModificationCharacter($buffer->GetModificationCharacter() - 1) ;
is($buffer->GetCurrentWord() , 'word4', 'GetCurrentWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
is($buffer->GetCurrentWord() , undef, 'GetCurrentWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
is($buffer->GetCurrentWord() , undef, 'GetCurrentWord preceded with garbage') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
$buffer->SetModificationCharacter(0) ;
is($buffer->GetCurrentWord() , undef, 'GetCurrentWord') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4 *$**') ;
$buffer->SetModificationCharacter(50) ;
is($buffer->GetCurrentWord() , undef, 'GetCurrentWord with current character outside the text') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->GetSelection()->Set(0, 3, 0, 7) ;
$buffer->SetModificationCharacter(1) ;
is($buffer->GetCurrentWord() , 'word1', 'GetCurrentWord with selection') ;

# GetPreviousAlphanumeric
$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
is($buffer->GetPreviousAlphanumeric() , 'word4', 'GetPreviousAlphanumeric') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
is($buffer->GetPreviousAlphanumeric() , 'word4', 'GetPreviousAlphanumeric preceded with garbage') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4 *$**') ;
$buffer->SetModificationCharacter(50) ;
is($buffer->GetPreviousAlphanumeric() , 'word4', 'GetPreviousAlphanumeric with current character outside the text') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->GetSelection()->Set(0, 3, 0, 7) ;
$buffer->SetModificationCharacter(1) ;
is($buffer->GetPreviousAlphanumeric() , undef, 'GetPreviousAlphanumeric with selection') ;

# GetNextAlphanumeric
$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4  *שש$*ש*]') ;
$buffer->SetModificationCharacter($buffer->GetModificationCharacter() - 1) ;
is($buffer->GetNextAlphanumeric() , undef, 'GetNextAlphanumeric') ;

$buffer->SetModificationCharacter(1) ;
is($buffer->GetNextAlphanumeric() , 'word1', 'GetNextAlphanumeric') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4 *$**') ;
$buffer->SetModificationCharacter(50) ;
is($buffer->GetNextAlphanumeric() , undef, 'GetNextAlphanumeric with current character outside the text') ;

$buffer->Reset() ;
$buffer->Insert(' word1 word_2 3 word4') ;
$buffer->GetSelection()->Set(0, 3, 0, 7) ;
$buffer->SetModificationCharacter(1) ;
is($buffer->GetNextAlphanumeric() , 'word1', 'GetNextAlphanumeric with selection') ;
