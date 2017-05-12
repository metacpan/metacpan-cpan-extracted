package FunctionMobileTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
use Text::Livedoor::Wiki::Plugin;
use Text::Livedoor::Wiki::Function;
my $function_plugins = Text::Livedoor::Wiki::Plugin->function_plugins;
my $function = Text::Livedoor::Wiki::Function->new( { plugins => $function_plugins , on_mobile => 1 } );
my $parser 
    =  Text::Livedoor::Wiki::Inline->new( { plugins =>  Text::Livedoor::Wiki::Plugin->inline_plugins , function =>  $function , on_mobile => 1 } );

sub run_test {
    my $self = shift;
    my $block = shift;
    local $Text::Livedoor::Wiki::scratchpad = {};
    local $Text::Livedoor::Wiki::opts = {};
    $Text::Livedoor::Wiki::opts->{storage} = 'http://static.wiki.livedoor.jp/formatter-storage';
    $Text::Livedoor::Wiki::opts->{js_storage} = 'http://static.wiki.livedoor.jp/js';

    my $html = $parser->parse( $block->wiki ); 
    my $expected = $block->html;
    $expected =~ s/\n$//;
    $html     =~ s/\n$//;
    is( $html , $expected , $block->name );
}
1;
