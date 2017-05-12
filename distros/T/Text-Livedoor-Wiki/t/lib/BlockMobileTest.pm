package BlockMobileTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
my $parser = Text::Livedoor::Wiki->new( { on_mobile => 1 } );

sub run_test {
    my $self = shift;
    my $block = shift;
    my $html = $parser->parse( $block->wiki ); 
    my $header = qq|<div class="user-area">\n|;
    my $footer = qq|</div>\n|;
    my $expected = $header . $block->html . $footer ;
    is( $html , $expected , $block->name );
}

1;
