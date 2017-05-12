# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use strict ;

use Data::Hexdumper ;

use Test::More tests => 1 ;

use Text::Editor::Vip::Buffer ;

my $buffer = Text::Editor::Vip::Buffer->new();

$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::File') ;

# InsertFile
use Text::Diff ;
$buffer->InsertFile(__FILE__) ;
my $diff = diff(\($buffer->GetText()), __FILE__, {STYLE => 'Table'}) ;
is($diff, '', 'InsertedFile is the same as source') ;

