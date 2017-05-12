# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 26 ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Tags') ;

# ReplaceOccurence
my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

#SetTagAtLine
$buffer->SetModificationLine(2) ;
$buffer->SetTagAtLine('test') ;

$buffer->SetTagAtLine('test', 1) ;

$buffer->SetModificationLine(0) ;

$buffer->GotoNextTag('test') ;
is($buffer->GetModificationLine(), 1, 'Goto first tag') ;

$buffer->GotoNextTag('test') ;
is($buffer->GetModificationLine(), 2, 'Goto second tag') ;

$buffer->GotoNextTag('test') ;
is($buffer->GetModificationLine(), 2, 'No more tags forward') ;

$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 1, 'No more tags forward') ;

$buffer->SetModificationLine(3) ;
$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 2, 'goto previous tag') ;

$buffer->ClearTagAtLine('test', 2) ;
$buffer->SetModificationLine(3) ;
$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 1, 'goto previous tab') ;

$buffer->FlipTagAtLine('test', 2) ;
$buffer->SetModificationLine(3) ;
$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 2, 'FlipTag') ;

$buffer->FlipTagAtLine('test', 2) ;
$buffer->SetModificationLine(3) ;
$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 1, 'FlipTag') ;

$buffer->ClearAllTags('test') ;
$buffer->SetModificationLine(3) ;
$buffer->GotoPreviousTag('test') ;
is($buffer->GetModificationLine(), 3, 'ClearAllTags') ;
$buffer->GotoNextTag('test') ;
is($buffer->GetModificationLine(), 3, 'ClearAllTags') ;

$buffer->AddNamedTag('test class', 2, 'first tag') ;
$buffer->AddNamedTag('test class', 4, 'second tag') ;
$buffer->AddNamedTag('1 2 3', 2, '1 2 3 tag') ;

is_deeply($buffer->GetNamedTags('test class'), [['first tag', 2], ['second tag', 4]], 'named tags') ;
is_deeply($buffer->GetNamedTags('1 2 3'), [['1 2 3 tag', 2]], 'named tags') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag('test class', 'second tag'), 4, 'goto named tag') ;
is($buffer->GetModificationLine(), 4, 'goto named tag') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag('1 2 3', '1 2 3 tag'), 2, 'goto named tag') ;
is($buffer->GetModificationLine(), 2, 'goto named tag') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag('1 2 3', 'X'), undef, 'goto named tag') ;
is($buffer->GetModificationLine(), 0, 'goto named tag') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag('X', 'first tag'), undef, 'goto named tag') ;
is($buffer->GetModificationLine(), 0, 'goto named tag') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag('1 2 3'), undef, 'goto named tag') ;
is($buffer->GetModificationLine(), 0, 'goto named tag') ;

$buffer->SetModificationLine(0) ;
is($buffer->GotoNamedTag(undef, 'first_tag'), undef, 'goto named tag') ;
is($buffer->GetModificationLine(), 0, 'goto named tag') ;

# some nasty input
$buffer->Reset() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Tags') ;

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

# set at invalid lines
$buffer->SetTagAtLine('test', 1000) ;
$buffer->AddNamedTag('test class', 1000, 'first tag') ;

# undef class
$buffer->SetTagAtLine(undef, 1) ;
$buffer->FlipTagAtLine(undef, 2) ;
$buffer->AddNamedTag(undef, 1, 'first tag') ;

# undef named tags
$buffer->AddNamedTag('test' ,1, undef) ;

