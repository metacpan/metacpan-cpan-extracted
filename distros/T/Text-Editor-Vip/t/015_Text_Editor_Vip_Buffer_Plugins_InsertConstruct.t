# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 14 ;
use Test::Exception ;
BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::InsertConstruct') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

my $text_to_insert = <<EOT ;
if()
\t{
\t}
else
\t{
\t}
EOT

# simple insertion
my $expected_text = <<EOT ;
if()
\t{
\t}
else
\t{
\t}
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->InsertAlignedWithTab($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'Simple insertion') ;

#insertion at position 4
$expected_text = <<EOT ;
lineif()
    \t{
    \t}
    else
    \t{
    \t}
     1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;

$buffer->InsertAlignedWithTab($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'insertion at position 4') ;

# single line without \n
$expected_text = <<EOT ;
lineXXXXX 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;

$buffer->InsertAlignedWithTab("XXXXX") ;
is($buffer->CompareText($expected_text), '', 'single line without \n') ;

# single line
$expected_text = <<EOT ;
lineXXXXX
     1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;

$buffer->InsertAlignedWithTab("XXXXX\n") ;
is($buffer->CompareText($expected_text), '', 'single line') ;

# last line without \n
$expected_text = <<EOT ;
lineAAAAA
    XXXXX 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;

$buffer->InsertAlignedWithTab("AAAAA\nXXXXX") ;
is($buffer->CompareText($expected_text), '', 'last line without \n') ;

# line where text is inserted contains \t
$text = <<EOT ;
\t\tline 1 - 1
line 2 - 2 2
EOT

$expected_text = <<EOT ;
\t\tlineAAAAA
\t\t    XXXXX 1 - 1
line 2 - 2 2
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 6) ;

$buffer->InsertAlignedWithTab("AAAAA\nXXXXX") ;
is($buffer->CompareText($expected_text), '', 'insertion line contains \t') ;

# insertion on an empty line after end of line
$text = '' ;
$expected_text = "  AAAAA\n  XXXXX" ;

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 2) ;

$buffer->InsertAlignedWithTab("AAAAA\nXXXXX") ;
is($buffer->CompareText($expected_text), '', 'insertion in empty line after end of line') ;

# InsertConstruct

$text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$text_to_insert = <<EOT ;
if()
\t{
\t}
else
\t{
\tSELECTION
\t}
EOT

# simple insertion
$expected_text = <<EOT ;
if()
\t{
\t}
else
\t{
\t}
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;
$buffer->InsertConstruct($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'Simple insertion') ;

# selection must be for entire lines
$buffer->SetSelectionBoundaries(1, 5, 1, 9) ;
dies_ok {$buffer->InsertConstruct($text_to_insert) ;} 'selection must be for entire lines' ;


# with one line selection
$expected_text = <<EOT ;
line 1 - 1
if()
\t{
\t}
else
\t{
\tline 2 - 2 2
\t}
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(3, 4) ;
$buffer->SetSelectionBoundaries(1, 0, 2, 0) ;

$buffer->InsertConstruct($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'with on line selection') ;

# with multiple lines selection
$expected_text = <<EOT ;
line 1 - 1
if()
\t{
\t}
else
\t{
\tline 2 - 2 2
\tline 3 - 3 3 3
\t}
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;
$buffer->SetSelectionBoundaries(1, 0, 3, 0) ;

$buffer->InsertConstruct($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'with multiple lines selection') ;

# with invalid selection
$text = <<EOT ;
line 1 - 1
\tline 2 - 2 2
\tline 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$expected_text = <<EOT ;
line 1 - 1
\tif()
\t\t{
\t\t}
\telse
\t\t{
\t\tline 2 - 2 2
\t\tline 3 - 3 3 3
\t\t}
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 4) ;
$buffer->SetSelectionBoundaries(1, 0, 3, 0) ;

$buffer->InsertConstruct($text_to_insert) ;
is($buffer->CompareText($expected_text), '', 'with multiple lines selection') ;

