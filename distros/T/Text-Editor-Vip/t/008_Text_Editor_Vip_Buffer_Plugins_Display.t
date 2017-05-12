# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use Test::More tests => 7 ;

BEGIN { use_ok('Text::Editor::Vip::Buffer' ); }

my $buffer = Text::Editor::Vip::Buffer->new();
isa_ok($buffer, 'Text::Editor::Vip::Buffer');

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Display') ;
$buffer->SetTabSize(3) ;
is($buffer->GetTabSize(), 3, 'tab size is as set') ;

#~ use Data::TreeDumper ;
#~ diag("\n" . DumpTree($buffer, 'Buffer:')) ;

$buffer->Insert("\t\ttext") ;
is($buffer->GetCharacterDisplayPosition(0, 2), 6, 'text to display convertion') ;
is($buffer->GetCharacterPositionInText(0, 6), 2, 'display to text convertion') ;

# test with a tab
$buffer->Reset() ;
$buffer->Insert(<<EOT) ;
\t901234567890
EOT

$buffer->{SELECTION}->Clear() ;
$buffer->SetModificationPosition(1, 1) ;

my $modification_line = $buffer->GetModificationLine() ;

my $display_position = $buffer->GetCharacterPositionInText
				(
				  $modification_line - 1
				, $buffer->GetCharacterDisplayPosition
						(
						  $modification_line
						, $buffer->GetModificationCharacter()
						)
				) ;

is_deeply($display_position, 0, 'Display position OK') ;

$buffer->SetTabSize(8) ;
is($buffer->GetCharacterPositionInText(undef, 9, "\tline 3 - 3 3 3") , 2, 'test') ;
