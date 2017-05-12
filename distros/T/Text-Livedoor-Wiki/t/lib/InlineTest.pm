package InlineTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
use Text::Livedoor::Wiki::Plugin;
use Text::Livedoor::Wiki::Function;

my $function = Text::Livedoor::Wiki::Function->new( { plugins => Text::Livedoor::Wiki::Plugin->function_plugins  } );
my $inline =  Text::Livedoor::Wiki::Plugin->inline_plugins( { addition => [qw/MyPlugin::Inline::Test/] } );
my $parser 
    =  Text::Livedoor::Wiki::Inline->new({ 
        plugins =>  $inline , 
        function => $function } 
    );

sub run_test {
    my $self = shift;
    my $block = shift;
    local $Text::Livedoor::Wiki::scratchpad = {};
    local $Text::Livedoor::Wiki::opts = { ping => 1 };
    my $html = $parser->parse( $block->wiki ); 
    my $expected = $block->html;
    $expected =~ s/\n$//;
    is( $html , $expected , $block->name );
}
1;
