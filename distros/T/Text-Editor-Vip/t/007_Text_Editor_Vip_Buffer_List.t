# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use Test::More tests => 9;

BEGIN { use_ok( 'Text::Editor::Vip::Buffer::List' ); }

my $list = new Text::Editor::Vip::Buffer::List() ;
isa_ok ($list, 'Text::Editor::Vip::Buffer::List');

my $element = ['some_element'] ;
my $index = $list->Push($element) ;
my $fetched_element = $list->GetNodeData(0) ;

is($index, 0, 'first pushed element at index 0') ;
is_deeply($fetched_element, $element, 'element is the same') ;

my $element_2 = {TEXT => 'some_element'} ;
$index = $list->Push($element_2) ;
is($index, 1, 'second pushed element at index 1') ;
is_deeply($fetched_element, $element, 'element is the same') ;

$index = $list->InsertAfter($index) ;
is($index, 2, 'InsertAfter index') ;
is_deeply($list->GetNodeData($index), undef, 'element is the same') ;

$index = $list->InsertBefore($index) ;
is($index, 2, 'InsertBefore index') ;
