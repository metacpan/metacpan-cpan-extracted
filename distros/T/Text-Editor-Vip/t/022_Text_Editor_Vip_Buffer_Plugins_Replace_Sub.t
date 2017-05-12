
use strict ;
use warnings ;

#~ use Devel::SimpleTrace ;
#~ use Carp::Indeed ;

use lib qw(lib) ;

use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use Test::More qw(no_plan);
use Test::Differences ;
use Test::Exception ;

use Text::Editor::Vip::Buffer ;
use Text::Editor::Vip::Buffer::Test ;

my $text = <<EOT ;
line 1 - 1
line 2 - 2 2
line 3 - 3 3 3
line 4 - 4 4 4 4
line 5 - 5 5 5 5 5
EOT

my $expected_text  ;

my $buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;

$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

($expected_text = $buffer->GetText()) =~ s/1/yasmin/ ;
is_deeply([$buffer->ReplaceOccurence('1', sub{'yasmin'})], [0, 5, '1', 'yasmin'], 'regex is sub') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

#Replacement is undef
is_deeply([$buffer->ReplaceOccurence('1', sub{})], [0, 14, '1', undef], 'regex is sub, returns undef') ;

# Replacement has \\n"
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2/yasmin\n/ ;
is_deeply([$buffer->ReplaceOccurence('2', sub{"yasmin\n"})], [1, 5, '2', "yasmin\n"], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

#Replacement is ''" 
$buffer->SetModificationPosition(0, 0) ;
($expected_text = $buffer->GetText()) =~ s/2// ;
is_deeply([$buffer->ReplaceOccurence('2', sub{''})], [2, 3, '2', ''], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

#invalid replacement doesn't die
$buffer->SetModificationPosition(0, 0) ;

my $redefined_sub_output = '' ;
$buffer->ExpandWith('PrintError', sub {$redefined_sub_output = $_[1]}) ;
lives_ok {$buffer->ReplaceOccurence(qr/l/, sub{die;}, 2, 0)} 'invalid replacement doesn\'t die' ;

use Test::Warn ;
warning_like {$buffer->ReplaceOccurence(qr/l/, '$2', 2, 0)} qr'Use of uninitialized value in substitution iterator', 'invalid replacement warning' ;


# verify arguments to replacement sub
$buffer->SetModificationPosition(0, 0) ;

sub replacement_sub
{
my($buffer, $match_line, $match_character, $match_word) = @_ ;

join(', ', ref($buffer), $match_line, $match_character, $match_word, "\n") ;
}

my $replacement = join(', ', ref($buffer), 5, 5, 5, "\n") ;
($expected_text = $buffer->GetText()) =~ s/5/$replacement/ ;

is_deeply([$buffer->ReplaceOccurence('5', \&replacement_sub)], [5, 5, '5', $replacement], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;

# within boundaries
$buffer = new Text::Editor::Vip::Buffer() ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Plugins::FindReplace') ;
$buffer->LoadAndExpandWith('Text::Editor::Vip::Buffer::Test') ;
$buffer->Reset() ;
$buffer->Insert($text) ;
$buffer->SetModificationPosition(0, 0) ;

$replacement = join(', ', ref($buffer), 4, 5, 5, "\n") ;
($expected_text = $buffer->GetText()) =~ s/5/$replacement/ ;

is_deeply([$buffer->ReplaceOccurenceWithinBoundaries('5', \&replacement_sub, 0, 0, 4, 6)], [4, 5, '5', $replacement], 'Found occurence 2') ;
is($buffer->CompareText($expected_text), '', 'Modification OK') ;
