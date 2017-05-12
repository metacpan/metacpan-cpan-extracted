package FunctionTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
use Text::Livedoor::Wiki::Plugin;
use Text::Livedoor::Wiki::Function;
my $function_plugins = Text::Livedoor::Wiki::Plugin->function_plugins({ addition => [qw/MyPlugin::Function::Test/] });
my $function = Text::Livedoor::Wiki::Function->new( { plugins => $function_plugins } );
my $parser 
    =  Text::Livedoor::Wiki::Inline->new( { plugins =>  Text::Livedoor::Wiki::Plugin->inline_plugins , function =>  $function } );

sub run_test {
    my $self = shift;
    my $block = shift;
    local $Text::Livedoor::Wiki::scratchpad = {};
    local $Text::Livedoor::Wiki::opts = {};
    $Text::Livedoor::Wiki::opts->{storage} = 'http://static.wiki.livedoor.jp/formatter-storage';

    my $html = $parser->parse( $block->wiki ); 
    my $expected = $block->html;
    $expected =~ s/\n$//;
    $html     =~ s/\n$//;
    is( $html , $expected , $block->name );
}
1;
