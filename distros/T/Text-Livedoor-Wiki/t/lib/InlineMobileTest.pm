package InlineMobileTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
use Text::Livedoor::Wiki::Plugin;
use Text::Livedoor::Wiki::Function;
my $function = Text::Livedoor::Wiki::Function->new( { plugins => Text::Livedoor::Wiki::Plugin->function_plugins  } );

my $parser 
    =  Text::Livedoor::Wiki::Inline->new( { on_mobile => 1 , plugins =>  Text::Livedoor::Wiki::Plugin->inline_plugins , function => $function });


sub run_test {
    my $self = shift;
    my $block = shift;
    local $Text::Livedoor::Wiki::scratchpad = {};
    my $html = $parser->parse( $block->wiki ); 
    my $expected = $block->html;
    $expected =~ s/\n$//;
    is( $html , $expected , $block->name );
}
1;
