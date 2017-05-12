# $Id: 22_lib-Text-HikiDoc_file.t,v 1.1 2006/10/12 09:17:45 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { input => 'read_file', output => 'read_file', outline => 'chomp'};

my $obj = Text::HikiDoc->new();
run {
    my $block = shift;

    is $obj->to_html($block->input), $block->output, $block->outline;
}

__END__

===
## compare TextFormattingRules
--- input
t/HikiDoc-TextFormattingRules
--- output
t/HikiDoc-TextFormattingRules.html
--- outline
compare TextFormattingRules

===
--- input
t/HikiDoc-TextFormattingRules.ja
--- output
t/HikiDoc-TextFormattingRules.ja.html
--- outline
compare TextFormattingRules.ja
