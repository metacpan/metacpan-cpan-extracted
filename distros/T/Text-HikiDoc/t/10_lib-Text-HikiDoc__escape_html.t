# 	$Id: 10_lib-Text-HikiDoc__escape_html.t,v 1.2 2006/10/12 04:18:04 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { input => 'chomp', output => 'chomp', outline => 'chomp'};

my $obj = Text::HikiDoc->new();
run {
	my $block = shift;
	is $obj->_escape_html($block->input), $block->output, $block->outline;
}

__END__

===
--- input
a&b
--- output
a&amp;b
--- outline
_escape_html(&)

===
--- input
a<<b
--- output
a&lt;&lt;b
--- outline
_escape_html(<)

===
--- input
a>>b
--- output
a&gt;&gt;b
--- outline
_escape_html(>)
