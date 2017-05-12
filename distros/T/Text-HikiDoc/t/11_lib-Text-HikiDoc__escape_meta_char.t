# 	$Id: 11_lib-Text-HikiDoc__escape_meta_char.t,v 1.2 2006/10/12 04:21:15 6-o Exp $
use Test::Base;
use Text::HikiDoc;

plan tests => 1 * blocks;
filters { input => 'chomp', output => 'chomp', outline => 'chomp'};

my $obj = Text::HikiDoc->new();
run {
	my $block = shift;
	is $obj->_escape_meta_char($block->input), $block->output, $block->outline;
}

__END__

===
--- input
a\:b
--- output
a&#x3a;b
--- outline
_escape_meta_char(\:)

===
--- input
a\"b
--- output
a&#x22;b
--- outline
_escape_meta_char(\")

===
--- input
a\|b
--- output
a&#x7c;b
--- outline
_escape_meta_char(\|)

===
--- input
a\'b
--- output
a&#x27;b
--- outline
_escape_meta_char(\')
