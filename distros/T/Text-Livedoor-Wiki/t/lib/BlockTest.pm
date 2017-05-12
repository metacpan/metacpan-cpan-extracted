package BlockTest;
use Test::Base -base;

use Text::Livedoor::Wiki;
use Text::Livedoor::Wiki::Plugin;
my $parser = Text::Livedoor::Wiki->new( {  opts => { storage => 'http://static.wiki.livedoor.jp/formatter-storage' } } );

sub run_test {
    my $self = shift;
    my $block = shift;
    my $html = $parser->parse( $block->wiki ); 
    my $header = qq|<div class="user-area">\n|;
    my $footer = qq|</div>\n|;
    my $except_html = $block->html;
    $except_html =~ s/\n_END_OF_DATA_$//;
    my $expected = $header . $except_html. $footer ;
    is( $html , $expected , $block->name );
}

1;
