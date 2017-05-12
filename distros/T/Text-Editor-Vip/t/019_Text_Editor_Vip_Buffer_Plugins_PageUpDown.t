# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 2 ;

BEGIN 
{
use_ok('Text::Editor::Vip::Buffer'); 
use_ok('Text::Editor::Vip::Buffer::Test'); 
}

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::Selection') ;

my $text = <<EOT ;
 line 1 - 1
  line 2 - 2 2
   line 3 - 3 3 3
    line 4 - 4 4 4 4
     line 5 - 5 5 5 5 5

something
EOT

$buffer->Reset() ;
$buffer->Insert($text) ;

